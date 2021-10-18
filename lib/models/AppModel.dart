import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teamtrack/functions/Functions.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/logic/provider/Theme.dart';
import 'Score.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../functions/Extensions.dart';

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

enum Role {
  viewer,
  editor,
  admin,
}





DataModel dataModel = DataModel();
final DarkThemeProvider themeChangeProvider = new DarkThemeProvider();
final Database.FirebaseDatabase firebaseDatabase =
    Database.FirebaseDatabase.instance;
final FirebaseFunctions functions = FirebaseFunctions.instance;
final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
final RemoteConfig remoteConfig = RemoteConfig.instance;
final FirebaseMessaging messaging = FirebaseMessaging.instance;



class TeamTrackUser {
  TeamTrackUser(
      {required this.role, this.displayName, this.email, this.photoURL});
  Role role;
  String? email;
  String? displayName;
  String? photoURL;
  TeamTrackUser.fromJson(Map<String, dynamic> json)
      : role = getRoleFromString(json['role']),
        email = json['email'],
        displayName = json['displayName'],
        photoURL = json['photoURL'];
  Map<String, dynamic> toJson() => {
        'role': role.toRep(),
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
      };
}









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
