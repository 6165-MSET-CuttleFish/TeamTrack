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

read(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return json.decode(prefs.getString(key)!);
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
  String? id;
  DatabaseServices({this.id});
  Stream<Database.Event> get getEventChanges =>
      firebaseDatabase.reference().child(id!).onValue;
}

DatabaseServices db = DatabaseServices();

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;
  AuthenticationService(this._firebaseAuth);
  Stream<User?> get authStateChanges => _firebaseAuth.idTokenChanges();
  Future<String?> signIn(
      {required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      return "Signed in";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signUp(
      {required String email,
      required String password,
      required String displayName}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      _firebaseAuth.currentUser?.updateDisplayName(displayName);
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
    final GoogleSignInAccount googleUser =
        await (GoogleSignIn().signIn() as FutureOr<GoogleSignInAccount>);

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

DataModel dataModel = DataModel();
final DarkThemeProvider themeChangeProvider = new DarkThemeProvider();
final Database.FirebaseDatabase firebaseDatabase =
    Database.FirebaseDatabase.instance;
final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

class DataModel {
  final List<String> keys = ['UltimateGoal'];
  DataModel() {
    try {
      restoreEvents();
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
  }

  bool isProcessing = false;
  void uploadEvent(Event event) async {
    if (event.shared) {
      isProcessing = true;
      var ref = firebaseDatabase.reference().child(event.id);
      await ref.update(event.toJson());
      isProcessing = false;
    }
  }

  void restoreEvents() async {
    final prefs = await SharedPreferences.getInstance();
    var x = jsonDecode(prefs.getString(keys[0])!) as List;
    var y = x.map((e) => Event.fromJson(e)).toList();
    events = y;
    print('reloaded');
  }

  void organize() {
    for (Event event in events) {
      for (Match match in event.matches) {
        match.red!.item1 = event.teams.firstWhere(
            (e) => e.number == match.red!.item1!.number,
            orElse: () => Team.nullTeam());
        match.red!.item2 = event.teams.firstWhere(
            (e) => e.number == match.red!.item2!.number,
            orElse: () => Team.nullTeam());
        match.blue!.item1 = event.teams.firstWhere(
            (e) => e.number == match.blue!.item1!.number,
            orElse: () => Team.nullTeam());
        match.blue!.item2 = event.teams.firstWhere(
            (e) => e.number == match.blue!.item2!.number,
            orElse: () => Team.nullTeam());
      }
    }
  }
}

class Event {
  Event({this.name, this.type});
  String id = Uuid().v4();
  bool shared = false;
  EventType? type;
  List<Team> teams = [];
  List<Match> matches = [];
  String? name;
  void addTeam(Team newTeam) {
    bool isIn = false;
    teams.forEach(
      (element) {
        if (element.equals(newTeam)) isIn = true;
      },
    );
    if (!isIn) teams.add(newTeam);
    //teams.sortTeams();
  }

  void deleteTeam(Team team) {
    for (Match match in matches) {
      if (match.red!.item1!.equals(team)) match.red!.item1 = Team.nullTeam();
      if (match.red!.item2!.equals(team)) match.red!.item2 = Team.nullTeam();
      if (match.blue!.item1!.equals(team)) match.blue!.item1 = Team.nullTeam();
      if (match.blue!.item2!.equals(team)) match.blue!.item2 = Team.nullTeam();
    }
    teams.remove(team);
  }

  void deleteMatch(Match e) {
    e.red?.item1?.scores.removeWhere((f) => f.id == e.id);
    e.red?.item2?.scores.removeWhere((f) => f.id == e.id);
    e.blue?.item1?.scores.removeWhere((f) => f.id == e.id);
    e.blue?.item2?.scores.removeWhere((f) => f.id == e.id);
    matches.remove(e);
  }

  void share() {
    shared = true;
  }

  void updateLocal(Map<String, dynamic>? json) {
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
  Team? item1;
  Team? item2;
  Alliance(Team item1, Team item2) {
    this.item1 = item1;
    this.item2 = item2;
  }
  int allianceTotal(String? id) {
    return 0 +
        (item1?.scores
                .firstWhere((e) => e.id == id,
                    orElse: () => Score(Uuid().v4(), Dice.none))
                .total() ??
            0) +
        (item2?.scores
                .firstWhere(
                  (e) => e.id == id,
                  orElse: () => Score(Uuid().v4(), Dice.none),
                )
                .total() ??
            0);
  }

  Alliance.fromJson(Map<String, dynamic>? json, List<Team> teamList)
      : item1 = teamList.firstWhere(
            (e) => e.number.trim() == json?['team1'].trim(),
            orElse: () => Team.nullTeam()),
        item2 = teamList.firstWhere(
            (e) => e.number.trim() == json?['team2'].trim(),
            orElse: () => Team.nullTeam());
  Map<String, dynamic> toJson() => {
        'team1': item1?.number,
        'team2': item2?.number,
      };
}

class Team {
  String name = '';
  String number = '';
  List<Score> scores = [];
  Score? targetScore;
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
        'targetScore': targetScore?.toJson()
      };
}

class Match {
  EventType? type = EventType.live;
  Dice dice = Dice.one;
  Alliance? red;
  Alliance? blue;
  String id = '';
  Match(Alliance red, Alliance blue, EventType? type) {
    this.type = type;
    this.red = red;
    this.blue = blue;
    id = Uuid().v4();
    red.item1?.scores.addScore(Score(id, dice));
    if (type != EventType.remote) {
      red.item2?.scores.addScore(Score(id, dice));
      blue.item1?.scores.addScore(Score(id, dice));
      blue.item2?.scores.addScore(Score(id, dice));
    }
  }
  static Match defaultMatch(EventType type) {
    return Match(Alliance(Team('1', 'Alpha'), Team('2', 'Beta')),
        Alliance(Team('3', 'Charlie'), Team('4', 'Delta')), type);
  }

  Alliance? alliance(Team team) {
    if (red!.item1!.equals(team) || red!.item2!.equals(team)) {
      return red;
    } else if (blue!.item1!.equals(team) || blue!.item2!.equals(team)) {
      return blue;
    } else {
      return null;
    }
  }

  void setDice(Dice dice) {
    this.dice = dice;
    red?.item1?.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .dice = dice;
    red?.item2?.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .dice = dice;
    blue?.item1?.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .dice = dice;
    blue?.item2?.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .dice = dice;
  }

  String score() {
    if (type == EventType.remote) {
      return red!.item1!.scores
          .firstWhere((e) => e.id == id,
              orElse: () => Score(Uuid().v4(), Dice.none))
          .total()
          .toString();
    }
    return redScore() + " - " + blueScore();
  }

  String redScore() {
    final r0 = red?.item1?.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .total();
    final r1 = red?.item2?.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .total();
    return ((r0 ?? 0) + (r1 ?? 0)).toString();
  }

  String blueScore() {
    final b0 = blue?.item1?.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .total();
    final b1 = blue?.item2?.scores
        .firstWhere((e) => e.id == id,
            orElse: () => Score(Uuid().v4(), Dice.none))
        .total();
    return ((b0 ?? 0) + (b1 ?? 0)).toString();
  }

  Match.fromJson(Map<String, dynamic> json, List<Team> teamList)
      : red = Alliance.fromJson(json['red'], teamList),
        blue = Alliance.fromJson(json['blue'], teamList),
        id = json['id'],
        dice = getDiceFromString(json['dice']),
        type = getTypeFromString(json['type']);
  Map<String, dynamic> toJson() => {
        'red': red!.toJson(),
        'blue': blue!.toJson(),
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

extension Arithmetic on Iterable<num> {
  double mean() {
    if (this.length == 0) {
      return 0;
    } else {
      return this.reduce(
              (value, element) => value.toDouble() + element.toDouble()) /
          this.length;
    }
  }

  List<FlSpot> spots() {
    List<FlSpot> val = [];
    for (int i = 0; i < this.length; i++) {
      val.add(FlSpot(i.toDouble(), this.toList()[i].toDouble()));
    }
    return val;
  }

  double standardDeviation() {
    if (this.length == 0) return 0;
    double mean = this.mean();
    return sqrt(this
            .map((e) => pow(e - mean, 2).toDouble())
            .reduce((value, element) => value + element) /
        this.length);
  }

  double median() {
    if (this.length < 2) return 0;
    final arr = this.sorted();
    int index = this.length ~/ 2;
    if (this.length % 2 == 0) {
      return [arr[(index - 1).clamp(0, 99999999999)] + arr[index]].mean();
    }
    return arr[index];
  }

  double q1() {
    if (this.length < 2) return 0;
    final arr = this.sorted();
    if (this.length % 2 == 0) {
      return arr.sublist(0, (this.length ~/ 2) - 1).median();
    }
    return arr.sublist(0, this.length ~/ 2).median();
  }

  double iqr() => q3() - q1();

  double q3() {
    if (this.length < 2) return 0;
    final arr = this.sorted();
    return arr.sublist(this.length ~/ 2).median();
  }

  double maxValue() => this.map((e) => e.toDouble()).reduce(max);
  double minValue() => this.map((e) => e.toDouble()).reduce(min);

  List<double> sorted() {
    if (this.length < 2) return [];
    List<double> val = [];
    for (num i in this) val.add(i.toDouble());
    val.sort((a, b) => a.compareTo(b));
    return val;
  }

  List<double> removeOutliers(bool removeOutliers) => this
      .map((e) => e.toDouble())
      .where((e) => removeOutliers ? !e.isOutlier(this) : true)
      .toList();

  BoxAndWhisker getBoxAndWhisker() => BoxAndWhisker(
        max: this.maxValue(),
        min: this.minValue(),
        median: median(),
        q1: q1(),
        q3: q3(),
      );
}

extension moreArithmetic on num {
  bool isOutlier(Iterable<num> list) =>
      this < list.q1() - 1.5 * list.iqr() ||
      this > list.q3() + 1.5 * list.iqr();
}

extension MatchExtensions on List<Match> {
  List<FlSpot> spots(Team? team, Dice? dice) {
    List<FlSpot> val = [];
    final arr =
        (dice != Dice.none ? this.where((e) => e.dice == dice) : this).toList();
    for (int i = 0; i < arr.length; i++) {
      final alliance = arr[i].alliance(team!);
      if (alliance != null) {
        final allianceTotal = alliance.allianceTotal(arr[i].id);
        val.add(FlSpot(i.toDouble(), allianceTotal.toDouble()));
      }
    }
    return val;
  }

  int maxAllianceScore(Team? team) {
    List<int> val = [];
    for (int i = 0; i < this.length; i++) {
      final alliance = this[i].alliance(team!);
      if (alliance != null) {
        final allianceTotal = alliance.allianceTotal(this[i].id);
        val.add(allianceTotal);
      }
    }
    return val.reduce(max);
  }
}

extension SpotExtensions on List<FlSpot> {
  List<FlSpot> removeOutliers(bool remove) {
    if (!remove) return this;
    return this.map((e) => e.y).toList().removeOutliers(remove).spots();
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
      //this.sortTeams();
      return newTeam;
    }
  }

  List<Team> sortedTeams() {
    List<Team> val = [];
    for (Team team in this) {
      val.add(team);
    }
    val.sort((a, b) => int.parse(a.number).compareTo(int.parse(b.number)));
    return val;
  }

  double maxScoreVar(Dice? dice, String? string, bool removeOutliers) {
    if (string == "auto") {
      return this.maxAutoScore(dice, removeOutliers);
    } else if (string == "tele") {
      return this.maxTeleScore(dice, removeOutliers);
    } else if (string == "endgame") {
      return this.maxEndScore(dice, removeOutliers);
    } else {
      return this.maxScore(dice, removeOutliers);
    }
  }

  double lowestStandardDeviationVar(
      Dice? dice, String string, bool removeOutliers) {
    if (string == "auto") {
      return this.lowestAutoStandardDeviationScore(dice, removeOutliers);
    } else if (string == "tele") {
      return this.lowestTeleStandardDeviationScore(dice, removeOutliers);
    } else if (string == "endgame") {
      return this.lowestEndStandardDeviationScore(dice, removeOutliers);
    } else {
      return this.lowestStandardDeviationScore(dice, removeOutliers);
    }
  }

  double lowestDeviationVar(Dice? dice, String string, bool removeOutliers) {
    if (string == "auto") {
      return this.lowestAutoStandardDeviationScore(dice, removeOutliers);
    } else if (string == "tele") {
      return this.lowestTeleStandardDeviationScore(dice, removeOutliers);
    } else if (string == "endgame") {
      return this.lowestEndStandardDeviationScore(dice, removeOutliers);
    } else {
      return this.lowestStandardDeviationScore(dice, removeOutliers);
    }
  }

  double maxScore(Dice? dice, bool removeOutliers) {
    if (this.length == 0) return 1;
    var x = this.map((e) => e.scores.maxScore(dice, removeOutliers));
    //.reduce(max);
    var y = x.reduce(max);
    return y;
  }

  double lowestStandardDeviationScore(Dice? dice, bool removeOutliers) {
    if (this.length == 0) return 1;
    return this
        .map((e) => e.scores.standardDeviationScore(dice, removeOutliers))
        .reduce(min);
  }

  double maxAutoScore(Dice? dice, bool removeOutliers) {
    if (this.length == 0) return 1;
    return this
        .map((e) => e.scores.autoMaxScore(dice, removeOutliers))
        .reduce(max);
  }

  double lowestAutoStandardDeviationScore(Dice? dice, bool removeOutliers) {
    if (this.length == 0) return 1;
    return this
        .map((e) => e.scores.autostandardDeviationScore(dice, removeOutliers))
        .reduce(min);
  }

  double maxTeleScore(Dice? dice, bool removeOutliers) {
    if (this.length == 0) return 1;
    return this
        .map((e) => e.scores.teleMaxScore(dice, removeOutliers))
        .reduce(max);
  }

  double lowestTeleStandardDeviationScore(Dice? dice, bool removeOutliers) {
    if (this.length == 0) return 1;
    return this
        .map((e) => e.scores.teleStandardDeviationScore(dice, removeOutliers))
        .reduce(min);
  }

  double maxEndScore(Dice? dice, bool removeOutliers) {
    if (this.length == 0) return 1;
    return this
        .map((e) => e.scores.endMaxScore(dice, removeOutliers))
        .reduce(max);
  }

  double lowestEndStandardDeviationScore(Dice? dice, bool removeOutliers) {
    if (this.length == 0) return 1;
    return this
        .map((e) => e.scores.endstandardDeviationScore(dice, removeOutliers))
        .reduce(min);
  }
}

extension ScoreDivExtension on List<ScoreDivision> {
  List<FlSpot> spots() => this.map((e) => e.total()).spots();

  double maxScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr
        .map((e) => e.total().toDouble())
        .removeOutliers(removeOutliers)
        .reduce(max)
        .toDouble();
  }

  double minScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr
        .map((e) => e.total().toDouble())
        .removeOutliers(removeOutliers)
        .reduce(min)
        .toDouble();
  }

  double meanScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr
        .map((e) => e.total().toDouble())
        .removeOutliers(removeOutliers)
        .mean();
  }

  double standardDeviationScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr
        .map((e) => e.total().toDouble())
        .removeOutliers(removeOutliers)
        .standardDeviation();
  }

  double devianceScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr
        .map((e) => e.total().toDouble())
        .removeOutliers(removeOutliers)
        .standardDeviation();
  }

  List<ScoreDivision> diceScores(Dice dice) =>
      (dice != Dice.none ? this.where((e) => e.getDice() == dice) : this)
          .toList();
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

  double maxScore(Dice? dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr.map((e) => e.total()).removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.reduce(max).toDouble();
    return 0;
  }

  double minScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr.map((e) => e.total()).removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.reduce(min).toDouble();
    return 0;
  }

  double meanScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr.map((e) => e.total()).removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.mean();
    return 0;
  }

  double standardDeviationScore(Dice? dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr.map((e) => e.total()).removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.standardDeviation();
    return 0;
  }

  double teleMaxScore(Dice? dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp =
        arr.map((e) => e.teleScore.total()).removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.reduce(max).toDouble();
    return 0;
  }

  double teleMinScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp =
        arr.map((e) => e.teleScore.total()).removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.reduce(min).toDouble();
    return 0;
  }

  double teleMeanScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp =
        arr.map((e) => e.teleScore.total()).removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.mean();
    return 0;
  }

  double teleStandardDeviationScore(Dice? dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp =
        arr.map((e) => e.teleScore.total()).removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.standardDeviation();
    return 0;
  }

  double autoMaxScore(Dice? dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp =
        arr.map((e) => e.autoScore.total()).removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.reduce(max).toDouble();
    return 0;
  }

  double autoMinScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp =
        arr.map((e) => e.autoScore.total()).removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.reduce(min).toDouble();
    return 0;
  }

  double autoMeanScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp =
        arr.map((e) => e.autoScore.total()).removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.mean();
    return 0;
  }

  double autostandardDeviationScore(Dice? dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) => e.autoScore.total().toDouble())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.standardDeviation();
    return 0;
  }

  double endMaxScore(Dice? dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp =
        arr.map((e) => e.endgameScore.total()).removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.reduce(max).toDouble();
    return 0;
  }

  double endMinScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr.map((e) => e.endgameScore.total());
    if (temp.length != 0) return temp.reduce(min).toDouble();
    return 0;
  }

  double endMeanScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) => e.endgameScore.total().toDouble())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.mean();
    return 0;
  }

  double endstandardDeviationScore(Dice? dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) => e.endgameScore.total().toDouble())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.standardDeviation();
    return 0;
  }

  List<Score> diceScores(Dice? dice) =>
      (dice != Dice.none ? this.where((e) => e.dice == dice) : this).toList();
}

bool toggle(bool init) {
  return !init;
}
