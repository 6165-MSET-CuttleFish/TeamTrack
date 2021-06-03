import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'score.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:github_sign_in/github_sign_in.dart';

read(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return json.decode(prefs.getString(key));
}

save(String key, value) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString(key, json.encode(value));
}

class DarkThemeProvider with ChangeNotifier {
  DarkThemePreference darkThemePreference = DarkThemePreference();
  bool _darkTheme = false;

  bool get darkTheme => _darkTheme;

  set darkTheme(bool value) {
    _darkTheme = value;
    darkThemePreference.setDarkTheme(value);
    notifyListeners();
  }
}

class DarkThemePreference {
  static const THEME_STATUS = "THEMESTATUS";

  setDarkTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(THEME_STATUS, value);
  }

  Future<bool> getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(THEME_STATUS) ?? false;
  }
}

class DatabaseServices {
  String id;
  DatabaseServices({this.id});
  Stream<Database.Event> get getEventChanges =>
      firebaseDatabase.reference().child(id).onValue;
}

DatabaseServices db = DatabaseServices();

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;
  AuthenticationService(this._firebaseAuth);
  Stream<User> get authStateChanges => _firebaseAuth.idTokenChanges();
  Future<String> signIn({String email, String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      return "Signed in";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String> signUp({String email, String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      return "Signed up";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await _firebaseAuth.signInWithCredential(credential);
  }

  String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserCredential> signInWithApple() async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    return await _firebaseAuth.signInWithCredential(oauthCredential);
  }
}

DataModel dataModel;
DarkThemeProvider themeChangeProvider = new DarkThemeProvider();
Database.FirebaseDatabase firebaseDatabase = Database.FirebaseDatabase.instance;
FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

class DataModel {
  final List<String> keys = ['UltimateGoal'];
  DataModel() {
    try {
      restoreEvents();
      //restoreEvents();
      // events = List<Event>.from(
      //     jsonDecode[keys[0]].map((model) => Event.fromJson(model)));
    } catch (Exception) {
      print('No events');
    }
  }
  List<Event> events = [];
  List<Event> localEvents() {
    return events.where((e) => e.type == EventType.local).toList();
  }

  List<Event> remoteEvents() {
    return events.where((e) => e.type == EventType.remote).toList();
  }

  List<Event> liveEvents() {
    return events.where((e) => e.type == EventType.live).toList();
  }

  void saveEvents() async {
    var coded = events.map((e) => e.toJson()).toList();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(keys[0], jsonEncode(coded));
    print(coded);
    // for (Event event in events) {
    //   if (event.shared) {
    //     var ref = firebaseDatabase.reference().child(event.id);
    //     ref.update(event.toJson());
    //   }
    // }
  }

  void uploadEvent(Event event) {
    if (event.shared) {
      var ref = firebaseDatabase.reference().child(event.id);
      ref.update(event.toJson());
      var x = event.toJson();
      print(x);
    }
  }

  void restoreEvents() async {
    final prefs = await SharedPreferences.getInstance();
    var x = jsonDecode(prefs.getString(keys[0])) as List;
    var y = x.map((e) => Event.fromJson(e)).toList();
    events = y;
    // organize();
    print('reloaded');
  }

  void organize() {
    for (Event event in events) {
      for (Match match in event.matches) {
        match.red.item1 = event.teams.firstWhere(
            (e) => e.number == match.red.item1.number,
            orElse: () => Team.nullTeam());
        match.red.item2 = event.teams.firstWhere(
            (e) => e.number == match.red.item2.number,
            orElse: () => Team.nullTeam());
        match.blue.item1 = event.teams.firstWhere(
            (e) => e.number == match.blue.item1.number,
            orElse: () => Team.nullTeam());
        match.blue.item2 = event.teams.firstWhere(
            (e) => e.number == match.blue.item2.number,
            orElse: () => Team.nullTeam());
      }
    }
  }
}

class Event {
  Event({this.name, this.type});
  String id = Uuid().v4();
  bool shared = false;
  EventType type;
  List<Team> teams = [];
  List<Match> matches = [];
  String name;
  void addTeam(Team newTeam) {
    bool isIn = false;
    teams.forEach((element) {
      if (element.equals(newTeam)) isIn = true;
    });
    if (!isIn) teams.add(newTeam);
    teams.sortTeams();
  }

  void deleteTeam(Team team) {
    for (Match match in matches) {
      if (match.red.item1.equals(team)) match.red.item1 = Team.nullTeam();
      if (match.red.item2.equals(team)) match.red.item2 = Team.nullTeam();
      if (match.blue.item1.equals(team)) match.blue.item1 = Team.nullTeam();
      if (match.blue.item2.equals(team)) match.blue.item2 = Team.nullTeam();
    }
    teams.remove(team);
  }

  void deleteMatch(Match e) {
    e.red.item1.scores.removeWhere((f) => f.id == e.id);
    e.red.item2.scores.removeWhere((f) => f.id == e.id);
    e.blue.item1.scores.removeWhere((f) => f.id == e.id);
    e.blue.item2.scores.removeWhere((f) => f.id == e.id);
    matches.remove(e);
  }

  void share() {
    shared = true;
  }

  void updateLocal(Map<String, dynamic> json) {
    if (json != null) {
      name = json['name'];
      try {
        teams =
            List<Team>.from(json['teams'].map((model) => Team.fromJson(model)));
      } catch (e) {
        teams = [];
      }
      try {
        matches = List<Match>.from(
            json['matches'].map((model) => Match.fromJson(model, teams)));
      } catch (e) {
        matches = [];
      }
      type = getTypeFromString(json['type']);
      shared = json['shared'] ?? true;
      id = json['id'] ?? Uuid().v4();
    }
  }

  Future<void> updateRemote() async {
    if (id.isNotEmpty) {
      await firebaseDatabase.reference().child(id).update(toJson());
    }
  }

  Event.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    teams = List<Team>.from(json['teams'].map((model) => Team.fromJson(model)));
    matches = List<Match>.from(
        json['matches'].map((model) => Match.fromJson(model, teams)));
    type = getTypeFromString(json['type']);
    shared = json['shared'] ?? false;
    id = json['id'] ?? Uuid().v4();
  }
  Map<String, dynamic> toJson() => {
        'name': name,
        'teams': teams.map((e) => e.toJson()).toList(),
        'matches': matches.map((e) => e.toJson()).toList(),
        'type': type.toString(),
        'shared': shared,
        'id': id,
      };
}

class Alliance {
  Team item1;
  Team item2;
  Alliance(Team item1, Team item2) {
    this.item1 = item1;
    this.item2 = item2;
  }
  int allianceTotal(String id) {
    return 0 +
        item1?.scores
            ?.firstWhere((e) => e.id == id,
                orElse: () => Score(Uuid().v4(), Dice.none))
            ?.total() +
        item2?.scores
            ?.firstWhere((e) => e.id == id,
                orElse: () => Score(Uuid().v4(), Dice.none))
            ?.total();
  }

  Alliance.fromJson(Map<String, dynamic> json, List<Team> teamList)
      : item1 = teamList.firstWhere(
            (e) => e.number.trim() == json['team1'].trim(),
            orElse: () => Team.nullTeam()),
        item2 = teamList.firstWhere(
            (e) => e.number.trim() == json['team2'].trim(),
            orElse: () => Team.nullTeam());
  Map<String, dynamic> toJson() => {
        'team1': item1.number,
        'team2': item2.number,
      };
}

class Team {
  String name;
  String number;
  List<Score> scores;
  Score targetScore;
  Team(String number, String name) {
    this.name = name;
    this.number = number;
    scores = [];
    targetScore = Score(Uuid().v4(), Dice.none);
  }
  static Team nullTeam() {
    return Team("?", "?");
  }

  bool equals(Team other) {
    return this.number == other.number;
  }

  Team.fromJson(Map<String, dynamic> json) {
    number = json['number'];
    name = json['name'];
    try {
      scores = List<Score>.from(
          json['scores'].map((model) => Score.fromJson(model)));
    } catch (e) {
      scores = [];
    }
    targetScore = Score.fromJson(json['targetScore']);
  }
  Map<String, dynamic> toJson() => {
        'name': name,
        'number': number,
        'scores': scores.map((e) => e.toJson()).toList(),
        'targetScore': targetScore.toJson()
      };
}

class Match {
  EventType type = EventType.live;
  Dice dice = Dice.one;
  Alliance red;
  Alliance blue;
  String id;
  Match(Alliance red, Alliance blue, EventType type) {
    this.type = type;
    this.red = red;
    this.blue = blue;
    id = Uuid().v4();
    red?.item1?.scores?.addScore(Score(id, dice));
    if (type != EventType.remote) {
      red?.item2?.scores?.addScore(Score(id, dice));
      blue?.item1?.scores?.addScore(Score(id, dice));
      blue?.item2?.scores?.addScore(Score(id, dice));
    }
  }
  static Match defaultMatch(EventType type) {
    return Match(Alliance(Team('1', 'Alpha'), Team('2', 'Beta')),
        Alliance(Team('3', 'Charlie'), Team('4', 'Delta')), type);
  }

  Alliance alliance(Team team) {
    if (red.item1.equals(team) || red.item2.equals(team)) {
      return red;
    } else if (blue.item1.equals(team) || blue.item2.equals(team)) {
      return blue;
    } else {
      return null;
    }
  }

  void setDice(Dice dice) {
    this.dice = dice;
    red.item1.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .dice = dice;
    red.item2.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .dice = dice;
    blue.item1.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .dice = dice;
    blue.item2.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .dice = dice;
  }

  String score() {
    if (type == EventType.remote) {
      return red.item1.scores
          .firstWhere((e) => e.id == id,
              orElse: () => Score(Uuid().v4(), Dice.none))
          .total()
          .toString();
    }
    return redScore() + " - " + blueScore();
  }

  String redScore() {
    final r0 = red.item1.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .total();
    final r1 = red.item2.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .total();
    return (r0 + r1).toString();
  }

  String blueScore() {
    final b0 = blue.item1.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .total();
    final b1 = blue.item2.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .total();
    return (b0 + b1).toString();
  }

  Match.fromJson(Map<String, dynamic> json, List<Team> teamList)
      : red = Alliance.fromJson(json['red'], teamList),
        blue = Alliance.fromJson(json['blue'], teamList),
        id = json['id'],
        dice = getDiceFromString(json['dice']),
        type = getTypeFromString(json['type']);
  Map<String, dynamic> toJson() => {
        'red': red.toJson(),
        'blue': blue.toJson(),
        'type': type.toString(),
        'dice': dice.toString(),
        'id': id.toString()
      };
}

enum EventType { live, local, remote }
enum Dice { one, two, three, none }

extension DiceExtension on Dice {
  String stackHeight() {
    switch (this) {
      case Dice.one:
        return '0';
      case Dice.two:
        return '1';
      case Dice.three:
        return '4';
      default:
        return 'All Cases';
    }
  }
}

extension IterableExtensions on Iterable<int> {
  List<FlSpot> spots() {
    List<FlSpot> val = [];
    for (int i = 0; i < this.length; i++) {
      val.add(FlSpot(i.toDouble(), this.toList()[i].toDouble()));
    }
    return val;
  }

  double mean() {
    if (this.length == 0) {
      return 0;
    } else {
      return this.reduce((value, element) => value += element) / this.length;
    }
  }

  double mad() {
    if (this.length == 0) {
      return 0;
    }
    final mean = this.mean();
    return this.map((e) => (e - mean).abs().toInt()).mean();
  }
}

extension MatchExtensions on List<Match> {
  List<FlSpot> spots(Team team, Dice dice) {
    List<FlSpot> val = [];
    final arr =
        (dice != Dice.none ? this.where((e) => e.dice == dice) : this).toList();
    for (int i = 0; i < arr.length; i++) {
      final alliance = arr[i].alliance(team);
      if (alliance != null) {
        final allianceTotal = alliance.allianceTotal(arr[i].id);
        val.add(FlSpot(i.toDouble(), allianceTotal.toDouble()));
      }
    }
    return val;
  }

  int maxAllianceScore(Team team) {
    List<int> val = [];
    for (int i = 0; i < this.length; i++) {
      final alliance = this[i].alliance(team);
      if (alliance != null) {
        final allianceTotal = alliance.allianceTotal(this[i].id);
        val.add(allianceTotal);
      }
    }
    return val.reduce(max);
  }
}

extension TeamsExtension on List<Team> {
  Team findAdd(String number, String name) {
    bool found = false;
    for (Team team in this) {
      if (team.number ==
          number
              .replaceAll(new RegExp(r' -,[^\w\s]+'), '')
              .replaceAll(' ', '')) {
        found = true;
      }
    }
    if (found) {
      var team = this.firstWhere((e) =>
          e.number ==
          number
              .replaceAll(new RegExp(r' -,[^\w\s]+'), '')
              .replaceAll(' ', ''));
      team.name = name;
      return team;
    } else {
      var newTeam = Team(
          number.replaceAll(new RegExp(r' -,[^\w\s]+'), '').replaceAll(' ', ''),
          name);
      this.add(newTeam);
      this.sortTeams();
      return newTeam;
    }
  }

  void sortTeams() {
    this.sort((a, b) => int.parse(a.number).compareTo(int.parse(b.number)));
  }

  double maxScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.maxScore(dice)).reduce(max);
  }

  double lowestMadScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.madScore(dice)).reduce(min);
  }

  double maxAutoScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.autoMaxScore(dice)).reduce(max);
  }

  double lowestAutoMadScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.autoMADScore(dice)).reduce(min);
  }

  double maxTeleScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.teleMaxScore(dice)).reduce(max);
  }

  double lowestTeleMadScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.teleMADScore(dice)).reduce(min);
  }

  double maxEndScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.endMaxScore(dice)).reduce(max);
  }

  double lowestEndMadScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.endMADScore(dice)).reduce(min);
  }
}

extension ScoresExtension on List<Score> {
  List<FlSpot> spots() {
    final list = this.map((e) => e.total()).toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }

  List<FlSpot> teleSpots() {
    final list = this.map((e) => e.teleScore.total()).toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }

  List<FlSpot> autoSpots() {
    final list = this.map((e) => e.autoScore.total()).toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }

  List<FlSpot> endSpots() {
    final list = this.map((e) => e.endgameScore.total()).toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }

  double maxScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.total()).reduce(max).toDouble();
  }

  double minScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.total()).reduce(min).toDouble();
  }

  double meanScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.total()).mean();
  }

  double madScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.total()).mad();
  }

  double teleMaxScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.teleScore.total()).reduce(max).toDouble();
  }

  double teleMinScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.teleScore.total()).reduce(min).toDouble();
  }

  double teleMeanScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.teleScore.total()).mean();
  }

  double teleMADScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.teleScore.total()).mad();
  }

  double autoMaxScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0)
      return 0;
    else
      return arr.map((e) => e.autoScore.total()).reduce(max).toDouble();
  }

  double autoMinScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0)
      return 0;
    else
      return arr.map((e) => e.autoScore.total()).reduce(min).toDouble();
  }

  double autoMeanScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0)
      return 0;
    else
      return arr.map((e) => e.autoScore.total()).mean();
  }

  double autoMADScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0)
      return 0;
    else
      return arr.map((e) => e.autoScore.total()).mad();
  }

  double endMaxScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.endgameScore.total()).reduce(max).toDouble();
  }

  double endMinScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.endgameScore.total()).reduce(min).toDouble();
  }

  double endMeanScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.endgameScore.total()).mean();
  }

  double endMADScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.endgameScore.total()).mad();
  }

  List<Score> diceScores(Dice dice) {
    return (dice != Dice.none ? this.where((e) => e.dice == dice) : this)
        .toList();
  }
}

bool toggle(bool init) {
  return !init;
}
