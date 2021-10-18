import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:flutter/cupertino.dart';
import 'package:teamtrack/functions/Functions.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/Change.dart';
import 'package:tuple/tuple.dart';
import 'Score.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/functions/Extensions.dart';

class Statics {
  static String gameName = remoteConfig.getString("gameName");
}

enum EventType { live, local, remote }
enum Dice { one, two, three, none }
enum OpModeType { auto, tele, endgame, penalty }
enum UserType { admin, editor, viewer }

class Event {
  Event(
      {required this.name,
      required this.type,
      required this.gameName,
      this.role = Role.editor});
  String id = Uuid().v4();
  String? authorName;
  String? authorEmail;
  String gameName = Statics.gameName;
  late Role role;
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

  TeamTrackUser getTTUserFromUser(User? user) {
    return TeamTrackUser(
      displayName: user?.displayName,
      email: user?.email,
      photoURL: user?.photoURL,
      role: role,
    );
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

  void updateLocal(dynamic map, BuildContext context) {
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
      try {
        permissions = (map['Permissions'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, TeamTrackUser.fromJson(value)));
      } catch (e) {}
      role = permissions[context.read<User?>()?.uid]?.role ?? Role.editor;
    }
  }

  Database.DatabaseReference? getRef() {
    if (!shared) return null;
    return firebaseDatabase.reference().child('Events/$gameName').child(id);
  }

  Event.fromJson(Map<String, dynamic>? json) {
    role = Role.editor;
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

class Match {
  EventType type = EventType.live;
  Dice dice = Dice.one;
  Alliance? red;
  Alliance? blue;
  String id = '';
  Map<String, TeamTrackUser>? activeUsers;
  Timestamp timeStamp = Timestamp.now();
  Match(this.red, this.blue, this.type) {
    id = Uuid().v4();
    timeStamp = Timestamp.now();
    red?.opposingAlliance = blue;
    blue?.opposingAlliance = red;
    red?.id = id;
    blue?.id = id;
    activeUsers = {};
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
    activeUsers = (json['activeUsers'] as Map<String, dynamic>?)
        ?.map((key, value) => MapEntry(key, TeamTrackUser.fromJson(value)));
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
