import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:flutter/cupertino.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:teamtrack/functions/Functions.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/Change.dart';
import 'package:teamtrack/models/StatConfig.dart';
import 'ScoreModel.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/functions/Extensions.dart';

class Statics {
  static String gameName = "FreightFrenzy";
}

enum EventType {
  live,
  local,
  remote,
}
enum Dice {
  one,
  two,
  three,
  none,
}
enum OpModeType {
  auto,
  tele,
  endgame,
  penalty,
}

class Event with ClusterItem {
  Event({
    required this.name,
    required this.type,
    required this.gameName,
    this.role = Role.editor,
  });

  String id = Uuid().v4();
  StatConfig statConfig = StatConfig();

  TeamTrackUser? author;

  String gameName = Statics.gameName;
  Role role = Role.editor;
  bool shared = false;
  EventType type = EventType.remote;
  Map<String, Team> teams = Map<String, Team>();
  Map<String, Match> matches = {};
  String name = "";
  Timestamp createdAt = Timestamp.now();

  Timestamp? sendTime;

  TeamTrackUser? sender;
  GeoFirePoint? loc;

  @override
  LatLng get location => LatLng(loc?.latitude ?? 0, loc?.longitude ?? 0);

  List<TeamTrackUser> users = [];

  Future<HttpsCallableResult<dynamic>> shareEvent({
    required String email,
    required Role role,
  }) async {
    final callable = functions.httpsCallable('shareEvent');
    return callable.call(
      {
        'email': email,
        'name': this.name,
        'id': this.id,
        'author': this.author?.toJson(),
        'type': this.type.toString(),
        'gameName': this.gameName,
        'role': role.toRep(),
      },
    );
  }

  void addTeam(Team newTeam) async {
    await getRef()
        ?.child('teams/${newTeam.number}')
        .update({"name": newTeam.name, "number": newTeam.number});
    teams.putIfAbsent(newTeam.number, () => newTeam);
    dataModel.saveEvents();
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
    final matches = getSortedMatches(true);
    for (var match in matches) {
      if (team.scores[match.id] != null) {
        arr.add(match);
      }
    }
    return arr;
  }

  void addMatch(Match e) async {
    await getRef()?.child('matches/${e.id}').set(e.toJson());
    await getRef()?.child('teams').runTransaction((mutableData) {
      for (var team in e.getTeams()) {
        if (team != null) {
          try {
            var ref = mutableData.value as Map? ?? {};
            ref.putIfAbsent(team.number, () => team.toJson());
            mutableData.value = ref;
          } catch (e) {
            var ref;
            if (mutableData.value != null) {
              ref = List.from(mutableData.value)
                  .where((element) => element != null)
                  .toList();
            } else {
              ref = [];
            }
            var map = Map<String, dynamic>.fromIterable(ref,
                key: (item) => item["number"], value: (item) => item);
            map.putIfAbsent(team.number, () => team.toJson());
            mutableData.value = map;
          }
          var teamIndex;
          try {
            mutableData.value as Map;
            teamIndex = team.number;
          } catch (e) {
            teamIndex = int.parse(team.number);
          }
          var ref = mutableData.value[teamIndex]['scores'] as Map? ?? {};
          ref.putIfAbsent(e.id, () => Score(e.id, e.dice, gameName).toJson());
          mutableData.value[teamIndex]['scores'] = ref;
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
      await dataModel.saveEvents();
    }
  }

  String? deleteTeam(Team team) {
    String? x;
    if (type != EventType.remote) {
      for (Match match in matches.values) {
        if ((match.red?.hasTeam(team) ?? false) ||
            (match.blue?.hasTeam(team) ?? false)) {
          if (type == EventType.remote)
            match.red?.team1 = null;
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
      dataModel.saveEvents();
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
          teams = List<Team>.from(
            map['teams']
                ?.map(
                  (model) =>
                      model != null ? Team.fromJson(model, gameName) : null,
                )
                .where((team) => team != null),
          ).asMap().map(
                (key, value) => MapEntry(
                  value.number,
                  value,
                ),
              );
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
        createdAt = getTimestampFromString(
            map['createdAt']); //Timestamp(map['seconds'], map['nanoSeconds']);
      } catch (e) {
        createdAt = Timestamp.now();
      }

      try {
        author = TeamTrackUser.fromJson(map['author'], null);
      } catch (e) {
        author = TeamTrackUser(
            role: Role.editor,
            displayName: map['authorName'],
            email: map['authorEmail']);
      }

      for (var match in matches.values) {
        match.setDice(match.dice);
      }
      try {
        users = (map['Permissions'] as Map<String, dynamic>)
            .map((key, value) =>
                MapEntry(key, TeamTrackUser.fromJson(value, key)))
            .values
            .toList();
      } catch (e) {}
      role = users
          .firstWhere(
            (element) => element.uid == context.read<User?>()?.uid,
            orElse: () => TeamTrackUser(role: Role.editor),
          )
          .role;
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
    statConfig.allianceTotal = type == EventType.remote;
    name = json?['name'] ?? "";
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
      createdAt = Timestamp(json?['seconds'], json?['nanoSeconds']);
    } catch (e) {
      createdAt = Timestamp.now();
    }

    try {
      author = TeamTrackUser.fromJson(json?['author'], null);
    } catch (e) {
      author = TeamTrackUser(
          role: Role.editor,
          displayName: json?['authorName'],
          email: json?['authorEmail']);
    }

    try {
      sender = TeamTrackUser.fromJson(json?['sender'], null);
    } catch (e) {
      sender = TeamTrackUser(
        role: Role.editor,
        displayName: json?['senderName'],
        email: json?['senderEmail'],
        uid: json?['senderID'],
        photoURL: json?['photoURL'],
      );
    }

    sendTime = json?['sendTime'];

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
        'author': author?.toJson(),
        'seconds': createdAt.seconds,
        'nanoSeconds': createdAt.nanoseconds,
      };
  Map<String, dynamic> toSimpleJson() => {
        'gameName': gameName,
        'name': name,
        'type': type.toString(),
        'sendTime': sendTime,
        'id': id,
      };
}

class Alliance {
  Team? team1;
  Team? team2;
  EventType eventType;
  Alliance? opposingAlliance;
  late Score sharedScore;
  String? id;
  String gameName;
  Alliance(this.team1, this.team2, this.eventType, this.gameName) {
    sharedScore =
        Score(Uuid().v4(), Dice.none, gameName, isAllianceScore: true);
  }
  int getPenalty() => penaltyTotal();

  bool hasTeam(Team team) =>
      (team1 != null && team1!.equals(team)) ||
      (team2 != null && team2!.equals(team));
  int penaltyTotal() =>
      (team1?.scores[id]?.penalties.total() ?? 0) +
      (team2?.scores[id]?.penalties.total() ?? 0);

  Score total() {
    Score returnVal = (team1?.scores[id] ?? Score('', Dice.none, gameName)) +
        (team2?.scores[id] ?? Score('', Dice.none, gameName)) +
        (sharedScore);
    return returnVal;
  }

  int allianceTotal(bool? showPenalties, {OpModeType? type}) =>
      (((team1?.scores[id]?.getScoreDivision(type).total() ?? 0) +
                  (team2?.scores[id]?.getScoreDivision(type).total() ?? 0) +
                  ((showPenalties ?? false)
                      ? (getPenalty())
                      : 0)) +
              sharedScore.getScoreDivision(type).total())
          .clamp(0, 999);
  Alliance.fromJson(
    Map<String, dynamic> json,
    Map<String, Team> teamList,
    this.eventType,
    this.gameName,
  )   : team1 = json['team1'] != null ? teamList[json['team1']] : null,
        team2 = json['team2'] != null ? teamList[json['team2']] : null,
        sharedScore = json['sharedScore'] != null
            ? Score.fromJson(
                json['sharedScore'],
                gameName,
                isAllianceScore: true,
              )
            : Score(Uuid().v4(), Dice.none, gameName, isAllianceScore: true);
  Map<String, dynamic> toJson() => {
        'team1': team1?.number,
        'team2': team2?.number,
        'sharedScore': sharedScore.toJson(),
      };
}

class Match {
  EventType type = EventType.live;
  Dice dice = Dice.one;
  Alliance? red;
  Alliance? blue;
  String id = '';
  List<TeamTrackUser>? activeUsers;
  Timestamp timeStamp = Timestamp.now();

  Match(this.red, this.blue, this.type) {
    id = Uuid().v4();
    timeStamp = Timestamp.now();
    red?.opposingAlliance = blue;
    blue?.opposingAlliance = red;
    red?.id = id;
    blue?.id = id;
    activeUsers = [];
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
    }
  }

  Alliance? opposingAlliance(Team? team) {
    if ((red?.team1?.equals(team) ?? false) ||
        (red?.team2?.equals(team) ?? false)) {
      return blue;
    } else if ((blue?.team1?.equals(team) ?? false) ||
        (blue?.team2?.equals(team) ?? false)) {
      return red;
    }
  }

  List<Team?> getTeams() => [red?.team1, red?.team2, blue?.team1, blue?.team2];

  List<Alliance?> getAlliances() => [red, blue];

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
      red?.allianceTotal(showPenalties) ?? 0;

  int blueScore({required bool? showPenalties}) =>
      blue?.allianceTotal(showPenalties) ?? 0;

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
        ?.map((key, value) => MapEntry(key, TeamTrackUser.fromJson(value, key)))
        .values
        .toList();
  }
  Map<String, dynamic> toJson() => {
        'red': red?.toJson(),
        'blue': blue?.toJson(),
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

  Score? getAllianceScore(String? number) {
    if (number == red?.team1?.number || number == red?.team2?.number)
      return red?.total();
    else if (number == blue?.team1?.number || number == blue?.team2?.number)
      return blue?.total();
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
        'changes': changes.map((change) => change.toJson()).toList(),
      };
}
