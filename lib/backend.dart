import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';
import 'score.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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
  static String gameName = remoteConfig.getString("gameName");
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

enum Role {
  viewer,
  editor,
  admin,
}

extension RoleExtension on Role {
  String name() {
    switch (this) {
      case Role.viewer:
        return 'Viewer';
      case Role.editor:
        return 'Editor';
      case Role.admin:
        return 'Admin';
    }
  }

  String toRep() {
    switch (this) {
      case Role.viewer:
        return 'viewer';
      case Role.editor:
        return 'editor';
      case Role.admin:
        return 'Admin';
    }
  }
}

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;
  AuthenticationService(this._firebaseAuth);
  User? getUser() => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.idTokenChanges();

  Future<void> addToken() async {
    final docRef = firebaseFirestore
        .collection('users')
        .doc(_firebaseAuth.currentUser?.uid);
    await firebaseFirestore.runTransaction((t) async {
      var snapshot = await t.get(docRef);
      List newTokens = snapshot.data()?['FCMtokens'];
      if (!newTokens.contains(dataModel.token) && dataModel.token != null) {
        newTokens.add(dataModel.token!);
      }
      return t.update(docRef, {'FCMtokens': newTokens});
    });
  }

  Future<void> removeToken() async {
    final docRef = firebaseFirestore
        .collection('users')
        .doc(_firebaseAuth.currentUser?.uid);
    await firebaseFirestore.runTransaction((t) async {
      var snapshot = await t.get(docRef);
      List newTokens = snapshot.data()?['FCMtokens'];
      if (dataModel.token != null)
        newTokens.removeWhere((e) => e == dataModel.token);
      return t.update(docRef, {'FCMtokens': newTokens});
    });
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      addToken();
      return "Signed in";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> forgotPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return "sent";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (_firebaseAuth.currentUser?.isAnonymous ?? false) {
      AuthCredential credential =
          EmailAuthProvider.credential(email: email, password: password);
      try {
        await _firebaseAuth.currentUser?.linkWithCredential(credential);
        _firebaseAuth.currentUser?.updateDisplayName(displayName);
        _firebaseAuth.currentUser?.sendEmailVerification();
        return "Signed Up";
      } on FirebaseAuthException catch (e) {
        return e.message;
      }
    } else {
      try {
        await _firebaseAuth.createUserWithEmailAndPassword(
            email: email, password: password);
        _firebaseAuth.currentUser?.updateDisplayName(displayName);
        _firebaseAuth.currentUser?.sendEmailVerification();
        return "Signed up";
      } on FirebaseAuthException catch (e) {
        return e.message;
      }
    }
  }

  Future<void> signOut() async {
    await removeToken();
    await _firebaseAuth.signOut();
  }

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      if (_firebaseAuth.currentUser?.isAnonymous ?? false) {
        return _firebaseAuth.currentUser?.linkWithCredential(credential);
      }
      var result = await _firebaseAuth.signInWithCredential(credential);
      addToken();
      return result;
    }
    return null;
  }

  Future<UserCredential?> signInWithAnonymous() async {
    if (_firebaseAuth.currentUser?.isAnonymous ?? false) return null;
    return _firebaseAuth.signInAnonymously();
  }
}

DataModel dataModel = DataModel();
final DarkThemeProvider themeChangeProvider = new DarkThemeProvider();
final Database.FirebaseDatabase firebaseDatabase =
    Database.FirebaseDatabase.instance;
final FirebaseFunctions functions = FirebaseFunctions.instance;
final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
final RemoteConfig remoteConfig = RemoteConfig.instance;
final FirebaseMessaging messaging = FirebaseMessaging.instance;

class DataModel {
  List<Event> events = [];
  String? token;
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
    prefs.setString("Events", jsonEncode(coded));
    print(coded);
  }

  Future<void> restoreEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var x = jsonDecode(prefs.getString("Events") ?? '') as List;
      events = x.map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      print("failed");
    }
  }

  Future<HttpsCallableResult<dynamic>> shareEvent({
    required String name,
    required String email,
    required String authorEmail,
    required String id,
    required String type,
    required String authorName,
    required String gameName,
    required Role role,
  }) async {
    final HttpsCallable callable = functions.httpsCallable('shareEvent');
    return callable.call(
      {
        'email': email,
        'name': name,
        'id': id,
        'authorEmail': authorEmail,
        'type': type,
        'authorName': authorName,
        'gameName': gameName,
        'role': role.toRep(),
      },
    );
  }
}

class TeamTrackUser {
  TeamTrackUser({required this.role, this.displayName, this.email});
  Role role;
  String? email;
  String? displayName;
}

class Event {
  Event({required this.name, required this.type, required this.gameName});
  String id = Uuid().v4();
  String? authorName;
  String? authorEmail;
  String gameName = Statics.gameName;
  bool shared = false;
  EventType type = EventType.remote;
  Map<String, Team> teams = Map<String, Team>();
  Map<String, Match> matches = {};
  late String name;
  Timestamp timeStamp = Timestamp.now();
  Map<String, TeamTrackUser> permissions = {};

  void addTeam(Team newTeam) async {
    await getRef()
        ?.child('teams/${newTeam.number}')
        .update({"name": newTeam.name, "number": newTeam.number});
    teams[newTeam.number] = newTeam;
  }

  List<Match> getSortedMatches(bool ascending) {
    var arr = matches.values.toList();
    if (ascending)
      arr.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
    else
      arr.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return arr;
  }

  List<Match> getMatches(Team team) {
    var arr = <Match>[];
    for (var match in matches.values) {
      if (team.scores[match.id] != null) {
        arr.add(match);
      }
    }
    return arr;
  }

  List<Tuple2<Team, List<Match>>> getMatchLists() {
    var bigArr = <Tuple2<Team, List<Match>>>[];
    for (var team in teams.values) {
      var smallArr = <Match>[];
      for (var match in matches.values) {
        if (match.alliance(team) != null) {
          smallArr.add(match);
        }
      }
      bigArr.add(Tuple2(team, smallArr));
    }
    return bigArr;
  }

  void addMatch(Match e) async {
    await getRef()?.runTransaction((mutableData) {
      var newMatches = mutableData.value['matches'] ?? {};
      newMatches[e.id] = e.toJson();
      mutableData.value['matches'] = newMatches;
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
          ref.putIfAbsent(e.id, () => Score(e.id, e.dice, gameName).toJson());
          mutableData.value['teams'][teamIndex]['scores'] = ref;
        }
      }
      return mutableData;
    });
    if (!shared) {
      matches[e.id] = e;
      e.red?.team1?.scores.addScore(
        Score(e.id, e.dice, gameName),
      );
      if (type != EventType.remote) {
        e.red?.team2?.scores.addScore(
          Score(e.id, e.dice, gameName),
        );
        e.blue?.team1?.scores.addScore(
          Score(e.id, e.dice, gameName),
        );
        e.blue?.team2?.scores.addScore(
          Score(e.id, e.dice, gameName),
        );
      }
    }
  }

  String? deleteTeam(Team team) {
    String? x;
    if (type != EventType.remote) {
      for (Match match in matches.values) {
        if ((match.red?.hasTeam(team) ?? false) ||
            (match.blue?.hasTeam(team) ?? false)) {
          if (type == EventType.remote)
            match.red?.team1 == null;
          else
            x = 'some';
        }
      }
      if (x == null) {
        teams.remove(team.number);
        getRef()?.runTransaction(
          (mutableData) {
            bool allowRemove = true;
            List<String> ids;
            try {
              var newTeams = ((mutableData.value as Map)['teams'] as Map?);
              ids = (newTeams?[team.number]?['scores'] as Map<String, dynamic>?)
                      ?.keys
                      .toList() ??
                  [];
            } catch (e) {
              var newTeams = ((mutableData.value as Map)['teams'] as List?);
              ids = (newTeams?.firstWhere(
                              (element) => element?['number'] == team.number,
                              orElse: () => null)?['scores']
                          as Map<String, dynamic>?)
                      ?.keys
                      .toList() ??
                  [];
            }
            for (final id in ids) {
              if (matches.containsKey(id)) {
                allowRemove = false;
              }
            }
            try {
              var newTeams = ((mutableData.value as Map)['teams'] as Map?);
              newTeams?.remove(team.number);
              mutableData.value['teams'] = newTeams;
            } catch (e) {
              var newTeams = allowRemove
                  ? ((mutableData.value as Map)['teams'] as List?)
                      ?.where((element) => element?['number'] != team.number)
                      .toList()
                  : (mutableData.value as Map)['teams'] as List?;
              mutableData.value['teams'] = newTeams;
            }
            return mutableData;
          },
        );
      }
    } else {
      matches.removeWhere((key, element) => element.alliance(team) != null);
      teams.remove(team.number);
      getRef()?.runTransaction((mutableData) {
        List<dynamic> ids = [];
        try {
          var newTeams = ((mutableData.value as Map)['teams'] as Map?);
          ids =
              (newTeams?[team.number]?['scores'] as Map?)?.keys.toList() ?? [];
          newTeams?.remove(team.number);
          mutableData.value['teams'] = newTeams;
        } catch (e) {
          var newTeams = ((mutableData.value as Map)['teams'] as List?);
          ids = (newTeams?.firstWhere((element) =>
                          element['number'] == team.number)?['scores']
                      as Map<String, dynamic>?)
                  ?.keys
                  .toList() ??
              [];
          newTeams?.removeWhere((element) => element['number'] == team.number);
          mutableData.value['teams'] = newTeams;
        }
        var newMatches = ((mutableData.value as Map)['matches'] as Map?);
        for (var id in ids) {
          newMatches?[id] = null;
        }
        mutableData.value['matches'] = newMatches;
        return mutableData;
      });
    }
    return x;
  }

  void deleteMatch(Match e) {
    if (!shared) {
      e.red?.team1?.scores.removeWhere((f, _) => f == e.id);
      e.red?.team2?.scores.removeWhere((f, _) => f == e.id);
      e.blue?.team1?.scores.removeWhere((f, _) => f == e.id);
      e.blue?.team2?.scores.removeWhere((f, _) => f == e.id);
      matches.remove(e.id);
    }
    getRef()?.runTransaction(
      (mutableData) {
        final newMatches = ((mutableData.value as Map)['matches'] as Map);
        newMatches.removeWhere((key, value) => key == e.id);
        mutableData.value['matches'] = newMatches;
        for (var team in e.getTeams()) {
          var teamIndex;
          try {
            mutableData.value['teams'] as Map;
            teamIndex = team?.number;
          } catch (e) {
            teamIndex = int.parse(team?.number ?? '');
          }
          try {
            var tempScores =
                (mutableData.value['teams'][teamIndex]['scores'] as Map);
            tempScores.remove(e.id);
            mutableData.value['teams'][teamIndex]['scores'] = tempScores;
          } catch (e) {}
        }
        return mutableData;
      },
    );
  }

  void updateLocal(dynamic map) {
    if (map != null) {
      gameName = map['gameName'] ?? Statics.gameName;
      type = getTypeFromString(map['type']);
      name = map['name'];
      try {
        teams = (map['teams'] as Map)
            .map((key, value) => MapEntry(key, Team.fromJson(value, gameName)));
      } catch (e) {
        try {
          var teamList = List<Team>.from(
            map['teams']
                ?.map(
                  (model) =>
                      model != null ? Team.fromJson(model, gameName) : null,
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
        matches = (map['matches'] as Map).map(
          (key, model) => MapEntry(
            key,
            Match.fromJson(
              model,
              teams,
              type,
              gameName,
            ),
          ),
        );
      } catch (e) {
        matches = {};
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
      for (var match in matches.values) {
        match.setDice(match.dice);
      }
    }
  }

  Database.DatabaseReference? getRef() {
    if (!shared) return null;
    return firebaseDatabase.reference().child('Events/$gameName').child(id);
  }

  Event.fromJson(Map<String, dynamic>? json) {
    gameName = json?['gameName'] ?? Statics.gameName;
    type = getTypeFromString(json?['type']);
    name = json?['name'];
    try {
      teams = (json?['teams'] as Map)
          .map((key, value) => MapEntry(key, Team.fromJson(value, gameName)));
      matches = (json?['matches'] as Map).map(
        (key, model) => MapEntry(
          key,
          Match.fromJson(model, teams, type, gameName),
        ),
      );
    } catch (e) {}
    shared = json?['shared'] ?? false;
    id = json?['id'] ?? Uuid().v4();
    try {
      timeStamp = Timestamp(json?['seconds'], json?['nanoSeconds']);
    } catch (e) {
      timeStamp = Timestamp.now();
    }
    authorEmail = json?['authorEmail'];
    authorName = json?['authorName'];
    for (var match in matches.values) {
      match.setDice(match.dice);
    }
  }
  Map<String, dynamic> toJson() => {
        'gameName': gameName,
        'name': name,
        'teams': teams
            .map<String, dynamic>((num, team) => MapEntry(num, team.toJson())),
        'matches': matches.map((key, e) => MapEntry(key, e.toJson())),
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
  late Score? sharedScore;
  String? id;
  Alliance(this.team1, this.team2, this.eventType, String gameName) {
    sharedScore =
        Score(Uuid().v4(), Dice.none, gameName, isAllianceScore: true);
  }
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
      (((team1?.scores[id]?.getScoreDivision(type).total() ?? 0) +
                  (team2?.scores[id]?.getScoreDivision(type).total() ?? 0) +
                  ((showPenalties ?? false)
                      ? (eventType == EventType.remote
                          ? getPenalty()
                          : -getPenalty())
                      : 0)) +
              (sharedScore?.total() ?? 0))
          .clamp(0, 999);
  Alliance.fromJson(
    Map<String, dynamic> json,
    Map<String, Team> teamList,
    this.eventType,
    String gameName,
  )   : team1 = json['team1'] != null ? teamList[json['team1']] : null,
        team2 = json['team2'] != null ? teamList[json['team2']] : null,
        sharedScore = json['sharedScore'] != null
            ? Score.fromJson(json['sharedScore'], gameName,
                isAllianceScore: true)
            : Score(Uuid().v4(), Dice.none, gameName, isAllianceScore: true);
  Map<String, dynamic> toJson() => {
        'team1': team1?.number,
        'team2': team2?.number,
        'sharedScore': sharedScore?.toJson(),
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

  Team.fromJson(Map<String, dynamic> json, String gameName) {
    number = json['number'];
    name = json['name'];
    try {
      scores = (json['scores'] as Map)
          .map((key, value) => MapEntry(key, Score.fromJson(value, gameName)));
    } catch (e) {
      scores = Map();
    }
    if (json['targetScore'] != null)
      targetScore = Score.fromJson(json['targetScore'], gameName);
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
  Map<String, String> activeUsers = Map();
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
      Alliance(Team('1', 'Alpha'), Team('2', 'Beta'), type, ""),
      Alliance(Team('3', 'Charlie'), Team('4', 'Delta'), type, ""),
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

  String score({required bool? showPenalties}) {
    if (type == EventType.remote) {
      return redScore(showPenalties: showPenalties).toString();
    }
    return redScore(showPenalties: showPenalties).toString() +
        " - " +
        blueScore(showPenalties: showPenalties).toString();
  }

  int getMaxScoreVal({required bool? showPenalties}) {
    return [
      redScore(showPenalties: showPenalties),
      blueScore(showPenalties: showPenalties)
    ].reduce(max);
  }

  int redScore({required bool? showPenalties}) =>
      red?.allianceTotal(id, showPenalties) ?? 0;

  int blueScore({required bool? showPenalties}) =>
      blue?.allianceTotal(id, showPenalties) ?? 0;

  Match.fromJson(Map<String, dynamic> json, Map<String, Team> teamList,
      this.type, String gameName) {
    try {
      red = Alliance.fromJson(
        json['red'],
        teamList,
        type,
        gameName,
      );
    } catch (e) {
      red = null;
    }
    try {
      blue = Alliance.fromJson(
        json['blue'],
        teamList,
        type,
        gameName,
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
  Score? getScore(String? number) {
    if (number == red?.team1?.number)
      return red?.team1?.scores[id];
    else if (number == red?.team2?.number)
      return red?.team2?.scores[id];
    else if (number == blue?.team1?.number)
      return blue?.team1?.scores[id];
    else if (number == blue?.team2?.number) return blue?.team2?.scores[id];
  }
}

enum EventType { live, local, remote }
enum Dice { one, two, three, none }
enum OpModeType { auto, tele, endgame, penalty }
enum UserType { admin, editor, viewer }

UserType? getUserTypeFromString(String userType) {
  switch (userType) {
    case 'editor':
      return UserType.admin;
    case 'temp':
      return UserType.editor;
    case 'viewer':
      return UserType.viewer;
  }
}

extension usExt on UserType {
  String toBackend() {
    switch (this) {
      case UserType.admin:
        return 'editor';
      case UserType.editor:
        return 'temp';
      case UserType.viewer:
        return 'viewer';
    }
  }

  String toRep() {
    switch (this) {
      case UserType.admin:
        return 'Admin';
      case UserType.editor:
        return 'Editor';
      case UserType.viewer:
        return 'Viewer';
    }
  }
}

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

  String toVal() {
    switch (this) {
      case OpModeType.auto:
        return 'Autonomous';
      case OpModeType.tele:
        return 'Tele-Op';
      case OpModeType.endgame:
        return 'Endgame';
      default:
        return 'Penalty';
    }
  }
}

extension DiceExtension on Dice {
  String toVal(String gameName) {
    final skeleton = json.decode(
      remoteConfig.getString(
        gameName,
      ),
    );
    var dice = skeleton["Dice"];
    switch (this) {
      case Dice.one:
        return dice['1'];
      case Dice.two:
        return dice['2'];
      case Dice.three:
        return dice['3'];
      default:
        return 'All Cases';
    }
  }
}

extension Arithmetic on Iterable<num?> {
  double mean() {
    if (this.length == 0) return 0;
    return (this.reduce((value, element) =>
                (value?.toDouble() ?? 0) + (element?.toDouble() ?? 0)) ??
            0) /
        this.length;
  }

  List<FlSpot> spots() {
    List<FlSpot> val = [];
    for (int i = 0; i < this.length; i++)
      val.add(FlSpot(i.toDouble(), (this.toList()[i]?.toDouble() ?? 0)));
    return val;
  }

  double standardDeviation() {
    if (this.length == 0) return 0;
    double mean = this.mean();
    return sqrt(this
            .map((e) => pow((e ?? 0) - mean, 2).toDouble())
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

  double maxValue() =>
      this.length != 0 ? this.map((e) => e?.toDouble() ?? 0).reduce(max) : 0;
  double minValue() =>
      this.length != 0 ? this.map((e) => e?.toDouble() ?? 0).reduce(min) : 0;

  List<double> sorted() {
    if (this.length < 2) return [];
    List<double> val = [];
    for (num? i in this) val.add(i?.toDouble() ?? 0);
    val.sort((a, b) => a.compareTo(b));
    return val;
  }

  List<double> removeOutliers(bool removeOutliers) {
    if (this.length < 3) return this.map((e) => e?.toDouble() ?? 0).toList();
    return this
        .map((e) => e?.toDouble() ?? 0)
        .where((e) => removeOutliers ? !e.isOutlier(this) : true)
        .toList();
  }
}

extension moreArithmetic on num {
  bool isOutlier(Iterable<num?> list) =>
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
    if (val.isEmpty) return 0;
    return val.reduce(max);
  }

  double maxScore(bool showPenalties) => this
      .toList()
      .map((e) => e.getMaxScoreVal(showPenalties: showPenalties))
      .reduce(max)
      .toDouble();
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

  List<Team> sortedTeams(OpModeType? type) {
    List<Team> val = [];
    for (Team team in this.values) {
      val.add(team);
    }
    val.sort(
      (a, b) => b.scores.values
          .map(
            ((score) => score.getScoreDivision(type)),
          )
          .toList()
          .meanScore(Dice.none, true)
          .compareTo(
            a.scores.values
                .map(
                  ((score) => score.getScoreDivision(type)),
                )
                .toList()
                .meanScore(Dice.none, true),
          ),
    );
    return val;
  }

  double maxScore(Dice? dice, bool removeOutliers, OpModeType? type) {
    if (this.length == 0) return 1;
    return this
        .values
        .map((e) => e.scores.maxScore(dice, removeOutliers, type))
        .reduce(max);
  }

  double maxMeanScore(Dice? dice, bool removeOutliers, OpModeType? type) {
    if (this.length == 0) return 1;
    return this
        .values
        .map((e) => e.scores.meanScore(dice ?? Dice.none, removeOutliers, type))
        .reduce(max);
  }

  double maxMedianScore(Dice? dice, bool removeOutliers, OpModeType? type) {
    if (this.length == 0) return 1;
    var x = this
        .values
        .map((e) =>
            e.scores.medianScore(dice ?? Dice.none, removeOutliers, type))
        .toList();
    return x.reduce(max);
  }

  double lowestStandardDeviationScore(
      Dice? dice, bool removeOutliers, OpModeType? type) {
    if (this.length == 0) return 1;
    final arr = this
        .values
        .map((e) => e.scores.standardDeviationScore(dice, removeOutliers, type))
        .where((element) => element != 0);
    return arr.length != 0 ? arr.reduce(min) : 1;
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

  double medianScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr
        .map((e) => e.total().toDouble())
        .removeOutliers(removeOutliers)
        .median();
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

  double medianScore(Dice dice, bool removeOutliers, OpModeType? type) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) => e.getScoreDivision(type).total())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.median();
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

extension StrExt on String {
  // return new string with spaces added before capital letters
  String spaceBeforeCapital() {
    var returnString = "";
    for (var i = 0; i < this.length; i++) {
      var currentChar = this[i];
      if (currentChar.toUpperCase() == currentChar && i != 0) {
        returnString += " ";
      }
      returnString += currentChar;
    }
    return returnString;
  }
}
