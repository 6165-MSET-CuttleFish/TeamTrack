import 'dart:async';
import 'dart:collection';
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
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

read(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return json.decode(prefs.getString(key)!);
}

save(String key, value) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString(key, json.encode(value));
}

class Statics {
  static String gameName = 'UltimateGoal';
  static Map<String, dynamic> skeleton =
      json.decode(remoteConfig.getString("skeleton"));
  // static Map<String, dynamic> skeleton = {
  //   'AutoScore': {
  //     'HighGoals': {
  //       'name': 'High Goals',
  //       'min': 0,
  //       'max': 999,
  //       'value': 12,
  //     },
  //     'MidGoals': {
  //       'name': 'Middle Goals',
  //       'min': 0,
  //       'max': 999,
  //       'value': 6,
  //     },
  //     'LowGoals': {
  //       'name': 'Low Goals',
  //       'min': 0,
  //       'max': 999,
  //       'value': 3,
  //     },
  //     'WobbleGoals': {
  //       'name': 'Wobble Goals',
  //       'min': 0,
  //       'max': 2,
  //       'value': 15,
  //     },
  //     'PowerShots': {
  //       'name': 'Power Shots',
  //       'min': 0,
  //       'max': 3,
  //       'value': 15,
  //     },
  //     'Navigated': {
  //       'name': 'Navigated',
  //       'min': 0,
  //       'max': 1,
  //       'value': 5,
  //       'isBool': true,
  //     },
  //   },
  //   'TeleScore': {
  //     'HighGoals': {
  //       'name': 'High Goals',
  //       'min': 0,
  //       'max': 999,
  //       'value': 6,
  //     },
  //     'MidGoals': {
  //       'name': 'Middle Goals',
  //       'min': 0,
  //       'max': 999,
  //       'value': 4,
  //     },
  //     'LowGoals': {
  //       'name': 'Low Goals',
  //       'min': 0,
  //       'max': 999,
  //       'value': 2,
  //     },
  //   },
  //   'EndgameScore': {
  //     'PowerShots': {
  //       'name': 'Power Shots',
  //       'min': 0,
  //       'max': 3,
  //       'value': 15,
  //     },
  //     'WobblesInDrop': {
  //       'name': 'Wobbles in Drop',
  //       'maxIsReference': true,
  //       'min': 0,
  //       'max': {'total': 2, 'reference': 'WobblesInStart'},
  //       'value': 20,
  //     },
  //     'WobblesInStart': {
  //       'name': 'Wobbles in Start',
  //       'maxIsReference': true,
  //       'min': 0,
  //       'max': {'total': 2, 'reference': 'WobblesInDrop'},
  //       'value': 5,
  //     },
  //     'RingsOnWobble': {
  //       'name': 'Rings on Wobble',
  //       'min': 0,
  //       'max': 999,
  //       'value': 5,
  //     }
  //   },
  // };
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
  Stream<Database.Event>? get getEventChanges => id != null
      ? firebaseDatabase
          .reference()
          .child('Events/${Statics.gameName}/$id')
          .onValue
      : null;
}

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
final FirebaseFunctions functions = FirebaseFunctions.instance;
final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
final RemoteConfig remoteConfig = RemoteConfig.instance;

class DataModel {
  final List<String> keys = [Statics.gameName];
  DataModel() {
    try {
      restoreEvents();
    } catch (e) {
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

  Future<void> restoreEvents() async {
    final prefs = await SharedPreferences.getInstance();
    var x = jsonDecode(prefs.getString(keys[0]) ?? '') as List;
    events = x.map((e) => Event.fromJson(e)).toList();
  }

  Future<void> shareEvent({required Map metaData, String? email}) async {
    final HttpsCallable callable = functions.httpsCallable('shareEvent');
    var resp = await callable.call(<String, dynamic>{
      'email': email,
      'metaData': metaData,
    });
  }
}

class Event {
  Event({required this.name, required this.type});
  String id = Uuid().v4();
  String? authorName;
  String? authorEmail;
  bool shared = false;
  EventType type = EventType.remote;
  Map<String, Team> teams = Map<String, Team>();
  List<Match> matches = [];
  late String name;
  Timestamp timeStamp = Timestamp.now();
  void addTeam(Team newTeam) async {
    await getRef()
        ?.child('teams/${newTeam.number}')
        .runTransaction((mutableData) async {
      if (mutableData.value == null) {
        mutableData.value = newTeam.toJson();
      }
      return mutableData;
    });
    teams[newTeam.number] = newTeam;
  }

  void addMatch(Match e) async {
    await getRef()?.runTransaction((mutableData) async {
      mutableData.value['matches'] = [
        ...mutableData.value['matches'] ?? [],
        e.toJson()
      ];
      for (var team in e.getTeams()) {
        if (team != null) {
          try {
            var ref = mutableData.value['teams'] as Map? ?? {};
            ref.putIfAbsent(team.number, () => team.toJson());

            mutableData.value['teams'] = ref;
          } catch (e) {
            var ref;
            if (mutableData.value['teams'] != null) {
              ref = List.from(mutableData.value['teams'])
                  .where((element) => element != null)
                  .toList();
            } else {
              ref = [];
            }
            var map = Map<String, dynamic>.fromIterable(ref,
                key: (item) => item["number"], value: (item) => item);
            map.putIfAbsent(team.number, () => team.toJson());
            mutableData.value['teams'] = map;
          }
          var teamIndex;
          try {
            mutableData.value['teams'] as Map;
            teamIndex = team.number;
          } catch (e) {
            teamIndex = int.parse(team.number);
          }
          var ref =
              mutableData.value['teams'][teamIndex]['scores'] as Map? ?? {};
          ref.putIfAbsent(e.id, () => Score(e.id, e.dice).toJson());
          mutableData.value['teams'][teamIndex]['scores'] = ref;
        }
      }
      return mutableData;
    });
    matches.add(e);
    e.red?.team1?.scores.addScore(
      Score(
        e.id,
        e.dice,
      ),
    );
    if (type != EventType.remote) {
      e.red?.team2?.scores.addScore(
        Score(
          e.id,
          e.dice,
        ),
      );
      e.blue?.team1?.scores.addScore(
        Score(
          e.id,
          e.dice,
        ),
      );
      e.blue?.team2?.scores.addScore(
        Score(
          e.id,
          e.dice,
        ),
      );
    }
  }

  String? deleteTeam(Team team) {
    String? x;
    for (Match match in matches) {
      if ((match.red?.hasTeam(team) ?? false) ||
          (match.blue?.hasTeam(team) ?? false)) {
        if (type == EventType.remote)
          match.red?.team1 == null;
        else
          x = 'some';
      }
    }
    if (x == null) {
      teams.remove(team);
      getRef()?.runTransaction((mutableData) async {
        var newTeams = ((mutableData.value as Map)['teams'] as Map);
        newTeams.remove(team.number);
        mutableData.value['teams'] = newTeams;
        return mutableData;
      });
    }
    return x;
  }

  void deleteMatch(Match e) {
    if (shared) {
      e.red?.team1?.scores.removeWhere((f, _) => f == e.id);
      e.red?.team2?.scores.removeWhere((f, _) => f == e.id);
      e.blue?.team1?.scores.removeWhere((f, _) => f == e.id);
      e.blue?.team2?.scores.removeWhere((f, _) => f == e.id);
      matches.remove(e);
    }
    getRef()?.runTransaction((mutableData) async {
      final newMatches = ((mutableData.value as Map)['matches'] as List)
          .where((element) => element['id'] != e.id)
          .toList();
      mutableData.value['matches'] = newMatches;
      for (var team in e.getTeams()) {
        var teamIndex;
        try {
          mutableData.value['teams'] as Map;
          teamIndex = team?.number;
        } catch (e) {
          teamIndex = int.parse(team?.number ?? '');
        }
        var tempScores =
            (mutableData.value['teams'][teamIndex]['scores'] as Map);
        tempScores.remove(e.id);
        mutableData.value['teams'][teamIndex]['scores'] = tempScores;
      }
      return mutableData;
    });
  }

  void updateLocal(dynamic map) {
    if (map != null) {
      type = getTypeFromString(map['type']);
      name = map['name'];
      try {
        teams = (map['teams'] as Map)
            .map((key, value) => MapEntry(key, Team.fromJson(value, type)));
      } catch (e) {
        try {
          var teamList = List<Team>.from(
            map['teams']
                ?.map(
                  (model) => model != null ? Team.fromJson(model, type) : null,
                )
                .where((e) => e != null),
          );
          teams = Map.fromIterable(teamList,
              key: (item) => item.number, value: (item) => item);
        } catch (e) {
          teams = {};
        }
      }
      try {
        matches = List<Match>.from(
          map['matches']?.map(
            (model) => Match.fromJson(
              model,
              teams,
              getTypeFromString(map['type']),
            ),
          ),
        );
      } catch (e) {
        matches = [];
      }
      shared = map['shared'] ?? true;
      id = map['id'] ?? Uuid().v4();
      try {
        timeStamp = Timestamp(map['seconds'], map['nanoSeconds']);
      } catch (e) {
        timeStamp = Timestamp.now();
      }
      authorEmail = map['authorEmail'];
      authorName = map['authorName'];
      for (var match in matches) {
        match.setDice(match.dice);
      }
    }
  }

  Database.DatabaseReference? getRef() {
    if (!shared) return null;
    return firebaseDatabase
        .reference()
        .child('Events/${Statics.gameName}')
        .child(id);
  }

  Event.fromJson(Map<String, dynamic> json) {
    type = getTypeFromString(json['type']);
    name = json['name'];
    teams = (json['teams'] as Map)
        .map((key, value) => MapEntry(key, Team.fromJson(value, type)));
    matches = List<Match>.from(
      json['matches'].map(
        (model) => Match.fromJson(
          model,
          teams,
          getTypeFromString(json['type']),
        ),
      ),
    );
    shared = json['shared'] ?? false;
    id = json['id'] ?? Uuid().v4();
    try {
      timeStamp = Timestamp(json['seconds'], json['nanoSeconds']);
    } catch (e) {
      timeStamp = Timestamp.now();
    }
    authorEmail = json['authorEmail'];
    authorName = json['authorName'];
    for (var match in matches) {
      match.setDice(match.dice);
    }
  }
  Map<String, dynamic> toJson() => {
        'name': name,
        'teams': teams
            .map<String, dynamic>((num, team) => MapEntry(num, team.toJson())),
        'matches': matches.map((e) => e.toJson()).toList(),
        'type': type.toString(),
        'shared': shared,
        'id': id,
        'authorName': authorName,
        'authorEmail': authorEmail,
        'seconds': timeStamp.seconds,
        'nanoSeconds': timeStamp.nanoseconds,
      };
}

class Alliance {
  Team? team1;
  Team? team2;
  EventType eventType;
  Alliance? opposingAlliance;
  String? id;
  Alliance(this.team1, this.team2, this.eventType);
  int getPenalty() {
    if (eventType == EventType.remote)
      return team1?.scores[id]?.penalties.total() ?? 0;
    return opposingAlliance?.penaltyTotal() ?? 0;
  }

  bool hasTeam(Team team) =>
      (team1 != null && team1!.equals(team)) ||
      (team2 != null && team2!.equals(team));
  int penaltyTotal() =>
      (team1?.scores[id]?.penalties.total() ?? 0) +
      (team2?.scores[id]?.penalties.total() ?? 0);

  int allianceTotal(String? id, bool? showPenalties, {OpModeType? type}) =>
      ((team1?.scores[id]?.getScoreDivision(type).total() ?? 0) +
              (team2?.scores[id]?.getScoreDivision(type).total() ?? 0) +
              ((showPenalties ?? false)
                  ? (eventType == EventType.remote
                      ? getPenalty()
                      : -getPenalty())
                  : 0))
          .clamp(0, 999);

  Alliance.fromJson(
    Map<String, dynamic> json,
    Map<String, Team> teamList,
    this.eventType,
  )   : team1 = teamList[json['team1']],
        team2 = teamList[json['team2']];
  Map<String, dynamic> toJson() => {
        'team1': team1?.number,
        'team2': team2?.number,
      };
}

class Team {
  String name = '';
  String number = '';
  Map<String, Score> scores = Map();
  List<Change> changes = [];
  Score? targetScore;
  Team(this.number, this.name);
  static Team nullTeam() {
    return Team("?", "?");
  }

  void deleteChange(Change change) {
    changes.remove(change);
  }

  void addChange(Change change) {
    changes.add(change);
    changes.sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  Team.fromJson(Map<String, dynamic> json, EventType eventType) {
    number = json['number'];
    name = json['name'];
    try {
      scores = (json['scores'] as Map)
          .map((key, value) => MapEntry(key, Score.fromJson(value, eventType)));
    } catch (e) {
      scores = Map();
    }
    if (json['targetScore'] != null)
      targetScore = Score.fromJson(json['targetScore'], eventType);
    try {
      changes = List<Change>.from(
        json['changes'].map(
          (model) => Change.fromJson(model),
        ),
      );
    } catch (e) {
      changes = [];
    }
  }
  Map<String, dynamic> toJson() => {
        'name': name,
        'number': number,
        'scores': scores.map((key, value) => MapEntry(key, value.toJson())),
        'targetScore': targetScore?.toJson(),
        'changes': changes.map((e) => e.toJson()).toList(),
      };
}

class Match {
  EventType type = EventType.live;
  Dice dice = Dice.one;
  Alliance? red;
  Alliance? blue;
  String id = '';
  Timestamp timeStamp = Timestamp.now();
  Match(this.red, this.blue, this.type) {
    id = Uuid().v4();
    timeStamp = Timestamp.now();
    red?.opposingAlliance = blue;
    blue?.opposingAlliance = red;
    red?.id = id;
    blue?.id = id;
  }
  static Match defaultMatch(EventType type) {
    return Match(
      Alliance(Team('1', 'Alpha'), Team('2', 'Beta'), type),
      Alliance(Team('3', 'Charlie'), Team('4', 'Delta'), type),
      type,
    );
  }

  Alliance? alliance(Team? team) {
    if ((red?.team1?.equals(team) ?? false) ||
        (red?.team2?.equals(team) ?? false)) {
      return red;
    } else if ((blue?.team1?.equals(team) ?? false) ||
        (blue?.team2?.equals(team) ?? false)) {
      return blue;
    } else {
      return null;
    }
  }

  List<Team?> getTeams() => [red?.team1, red?.team2, blue?.team1, blue?.team2];

  void setDice(Dice dice) {
    this.dice = dice;
    red?.team1?.scores[id]?.setDice(dice, timeStamp);
    red?.team2?.scores[id]?.setDice(dice, timeStamp);
    blue?.team1?.scores[id]?.setDice(dice, timeStamp);
    blue?.team2?.scores[id]?.setDice(dice, timeStamp);
  }

  String score({bool? showPenalties}) {
    if (type == EventType.remote) {
      return redScore(showPenalties: showPenalties);
    }
    return redScore(showPenalties: showPenalties) +
        " - " +
        blueScore(showPenalties: showPenalties);
  }

  String redScore({bool? showPenalties}) =>
      (red?.allianceTotal(id, showPenalties) ?? 0).toString();

  String blueScore({bool? showPenalties}) =>
      (blue?.allianceTotal(id, showPenalties) ?? 0).toString();

  Match.fromJson(
      Map<String, dynamic> json, Map<String, Team> teamList, this.type) {
    try {
      red = Alliance.fromJson(
        json['red'],
        teamList,
        type,
      );
    } catch (e) {
      red = null;
    }
    try {
      blue = Alliance.fromJson(
        json['blue'],
        teamList,
        type,
      );
    } catch (e) {
      blue = null;
    }
    id = json['id'];
    dice = getDiceFromString(json['dice']);
    red?.opposingAlliance = blue;
    blue?.opposingAlliance = red;
    red?.id = id;
    blue?.id = id;
    try {
      timeStamp = Timestamp(json['seconds'], json['nanoSeconds']);
    } catch (e) {
      timeStamp = Timestamp.now();
    }
  }
  Map<String, dynamic> toJson() => {
        'red': red?.toJson(),
        'blue': blue?.toJson(),
        'type': type.toString(),
        'dice': dice.toString(),
        'id': id.toString(),
        'seconds': timeStamp.seconds,
        'nanoSeconds': timeStamp.nanoseconds,
      };
  int geIndex(Database.MutableData mutableData) =>
      (mutableData.value['matches'] as List)
          .indexWhere((element) => element['id'] == id);
}

enum EventType { live, local, remote }
enum Dice { one, two, three, none }
enum OpModeType { auto, tele, endgame, penalty }

extension extOp on OpModeType {
  String toRep() {
    switch (this) {
      case OpModeType.auto:
        return 'AutoScore';
      case OpModeType.tele:
        return 'TeleScore';
      case OpModeType.endgame:
        return 'EndgameScore';
      default:
        return 'Penalty';
    }
  }
}

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
    if (this.length == 0) return 0;
    return this
            .reduce((value, element) => value.toDouble() + element.toDouble()) /
        this.length;
  }

  List<FlSpot> spots() {
    List<FlSpot> val = [];
    for (int i = 0; i < this.length; i++)
      val.add(FlSpot(i.toDouble(), this.toList()[i].toDouble()));
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
    if (this.length % 2 == 0)
      return [arr[(index - 1).clamp(0, 999)], arr[index]].mean();
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

  List<double> removeOutliers(bool removeOutliers) {
    if (this.length < 3) return this.map((e) => e.toDouble()).toList();
    return this
        .map((e) => e.toDouble())
        .where((e) => removeOutliers ? !e.isOutlier(this) : true)
        .toList();
  }
}

extension moreArithmetic on num {
  bool isOutlier(Iterable<num> list) =>
      this < list.q1() - 1.5 * list.iqr() ||
      this > list.q3() + 1.5 * list.iqr();
}

extension Ex on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}

extension ExTeam on Team? {
  bool equals(Team? other) => this?.number == other?.number;
}

extension MatchExtensions on List<Match> {
  List<FlSpot> spots(Team team, Dice dice, bool showPenalties,
      {OpModeType? type}) {
    List<FlSpot> val = [];
    final arr =
        (dice != Dice.none ? this.where((e) => e.dice == dice) : this).toList();
    int i = 0;
    for (var match in arr) {
      final alliance = match.alliance(team);
      if (alliance != null) {
        final allianceTotal =
            alliance.allianceTotal(match.id, showPenalties, type: type);
        val.add(FlSpot(i.toDouble(), allianceTotal.toDouble()));
        i++;
      }
    }
    return val;
  }

  int maxAllianceScore(Team team) {
    List<int> val = [];
    for (int i = 0; i < this.length; i++) {
      final alliance = this[i].alliance(team);
      if (alliance != null) {
        final allianceTotal = alliance.allianceTotal(this[i].id, false);
        val.add(allianceTotal);
        final allianceTotal2 = alliance.allianceTotal(this[i].id, true);
        val.add(allianceTotal2);
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

extension ListScore on List<Score> {
  List<FlSpot> spots(OpModeType? type, {bool? showPenalties}) {
    final list = this
        .map(
            (e) => e.getScoreDivision(type).total(showPenalties: showPenalties))
        .toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }
}

extension colorExt on OpModeType? {
  Color getColor() {
    switch (this) {
      case OpModeType.auto:
        return Colors.green;
      case OpModeType.tele:
        return Colors.blue;
      case OpModeType.endgame:
        return Colors.deepOrange;
      case OpModeType.penalty:
        return Colors.red;
      default:
        return Color.fromRGBO(230, 30, 213, 1);
    }
  }
}

extension TeamsExtension on Map<String, Team> {
  Team? findAdd(String number, String name, Event event) {
    if (this.containsKey(number)) {
      var team = this[number
          .replaceAll(new RegExp(r' -,[^\w\s]+'), '')
          .replaceAll(' ', '')];
      team?.name = name;
      return team;
    } else {
      var newTeam = Team(
          number.replaceAll(new RegExp(r' -,[^\w\s]+'), '').replaceAll(' ', ''),
          name);
      event.teams[newTeam.number] = newTeam; //addTeam(newTeam);
      return newTeam;
    }
  }

  List<Team> sortedTeams() {
    List<Team> val = [];
    for (Team team in this.values) {
      val.add(team);
    }
    val.sort((a, b) => int.parse(a.number).compareTo(int.parse(b.number)));
    return val;
  }

  double maxScore(Dice? dice, bool removeOutliers, OpModeType? type) {
    if (this.length == 0) return 1;
    return this
        .values
        .map((e) => e.scores.maxScore(dice, removeOutliers, type))
        .reduce(max);
  }

  double lowestStandardDeviationScore(
      Dice? dice, bool removeOutliers, OpModeType? type) {
    if (this.length == 0) return 1;
    return this
        .values
        .map((e) => e.scores.standardDeviationScore(dice, removeOutliers, type))
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

  List<ScoreDivision> diceScores(Dice dice) {
    var returnList =
        (dice != Dice.none ? this.where((e) => e.getDice() == dice) : this)
            .toList();
    returnList
        .sort((a, b) => a.timeStamp.toDate().compareTo(b.timeStamp.toDate()));
    return returnList;
  }
}

extension ScoresExtension on Map<String, Score> {
  double maxScore(Dice? dice, bool removeOutliers, OpModeType? type) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) => e.getScoreDivision(type).total())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.reduce(max).toDouble();
    return 0;
  }

  double minScore(Dice dice, bool removeOutliers, OpModeType? type) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) => e.getScoreDivision(type).total())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.reduce(min).toDouble();
    return 0;
  }

  double meanScore(Dice dice, bool removeOutliers, OpModeType? type) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) => e.getScoreDivision(type).total())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.mean();
    return 0;
  }

  double standardDeviationScore(
      Dice? dice, bool removeOutliers, OpModeType? type) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) => e.getScoreDivision(type).total())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.standardDeviation();
    return 0;
  }

  List<Score> diceScores(Dice? dice) {
    var returnList = (dice != Dice.none
            ? this.values.where((e) => e.getDice() == dice)
            : this.values)
        .toList();
    returnList
        .sort((a, b) => a.timeStamp.toDate().compareTo(b.timeStamp.toDate()));
    return returnList;
  }
}
