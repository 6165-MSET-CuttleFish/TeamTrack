import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as Db;
import 'package:flutter/cupertino.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:teamtrack/functions/Functions.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/Change.dart';
import 'package:teamtrack/models/StatConfig.dart';
import 'ScoreModel.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/functions/Statistics.dart';

class Statics {
  static String gameName =
      'PowerPlay'; // default gameName (can be changed remotely)
}

enum EventType {
  local,
  remote,
  analysis,
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

/// Composed of a map of [matches] and [teams] as well as a specified event [type]
class Event {
  Event({
    required this.name,
    required this.type,
    required this.gameName,
    this.eventKey,
    this.role = Role.editor,
  });

  String? eventKey;
  String id = Uuid().v4();
  StatConfig statConfig = StatConfig();

  TeamTrackUser? author;
  String gameName = Statics.gameName;
  Role role =
      Role.editor; // the permissions enabled for the current user in this event
  bool shared = false;
  EventType type = EventType.remote;
  Map<String, Team> teams = {};
  Map<String, Match> matches = {};
  String name = "";
  Timestamp createdAt = Timestamp.now();

  Timestamp? sendTime;

  TeamTrackUser? sender;
  GeoFirePoint? loc;

  List<TeamTrackUser> users = [];

  Future<HttpsCallableResult<dynamic>> shareEvent({
    required String email,
    required Role role,
  }) =>
      functions.httpsCallable('shareEvent').call(
        {
          'email': email,
          'name': name,
          'id': id,
          'author': author?.toJson(),
          'type': type.toString(),
          'gameName': gameName,
          'role': role.toRep(),
          'eventKey':eventKey,
        },
      );

  Future<HttpsCallableResult<dynamic>> modifyUser({
    required String? uid,
    required Role? role,
  }) {
    debugPrint('AHHHHHHHHHHHHHHHHHHHHHHHHHHHHH Events/$gameName/$id/Permissions/$uid');
    return functions.httpsCallable('modifyUserRole').call(
      {
        'uid': uid,
        'id': id,
        'gameName': gameName,
        'role': role?.toRep(),
      },
    );
  }


  String? getKey() => eventKey;

  bool hasKey() => eventKey != null && !(eventKey?.isEmpty ?? true);

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

  List<Match> getAllMatches(T) {
    var arr = <Match>[];
    final matches = getSortedMatches(true);
    for (var match in matches) {
      arr.add(match);
    }
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

  void addChange(Change change, Team team) async {
    await getRef()
        ?.child('teams/${team.number}/changes/${change.id}')
        .update(change.toJson());
    if (!shared) team.addChange(change);
  }

  void deleteChange(Change change, Team team) async {
    await getRef()?.child('teams/${team.number}/changes/${change.id}').remove();
    if (!shared) team.deleteChange(change);
  }

  void addMatch(Match e) async {
    await getRef()?.child('matches/${e.id}').set(e.toJson());
    await getRef()?.child('teams').runTransaction((mutableData) {
      for (var team in e.getTeams()) {
        if (team != null) {
          try {
            var ref = mutableData as Map? ?? {};
            ref.putIfAbsent(team.number, () => team.toJson());
            mutableData = ref;
          } catch (e) {
            var ref;
            if (mutableData != null) {
              ref = List.from(mutableData as dynamic)
                  .where((element) => element != null)
                  .toList();
            } else {
              ref = [];
            }
            var map = Map<String, dynamic>.fromIterable(ref,
                key: (item) => item["number"], value: (item) => item);
            map.putIfAbsent(team.number, () => team.toJson());
            mutableData = map;
          }
          var teamIndex;
          try {
            mutableData as Map;
            teamIndex = team.number;
          } catch (e) {
            teamIndex = int.parse(team.number);
          }
          final ref = (mutableData as Map?)?[teamIndex]['scores'] as Map? ?? {};
          ref.putIfAbsent(e.id, () => Score(e.id, e.dice, gameName).toJson());
          mutableData?[teamIndex]['scores'] = ref;
        }
      }
      return Db.Transaction.success(mutableData);
    });
    if (!shared) {
      matches[e.id] = e;
      e.red?.team1?.scores.addScore(
        Score(e.id, e.dice, gameName),
      );
      if (type != EventType.remote && type != EventType.analysis) {
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
              var newTeams = ((mutableData as Map?)?['teams'] as Map?);
              ids = (newTeams?[team.number]?['scores'] as Map<String, dynamic>?)
                      ?.keys
                      .toList() ??
                  [];
            } catch (e) {
              var newTeams = ((mutableData as Map?)?['teams'] as List?);
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
              var newTeams = mutableData?['teams'] as Map?;
              newTeams?.remove(team.number);
              mutableData?['teams'] = newTeams;
            } catch (e) {
              var newTeams = allowRemove
                  ? ((mutableData as Map)['teams'] as List?)
                      ?.where((element) => element?['number'] != team.number)
                      .toList()
                  : (mutableData as Map)['teams'] as List?;
              mutableData['teams'] = newTeams;
            }
            return Db.Transaction.success(mutableData);
          },
        );
      }
    } else {
      matches.removeWhere((key, element) => element.alliance(team) != null);
      teams.remove(team.number);
      getRef()?.runTransaction((mutableData) {
        List<dynamic> ids = [];
        try {
          var newTeams = ((mutableData as Map)['teams'] as Map?);
          ids =
              (newTeams?[team.number]?['scores'] as Map?)?.keys.toList() ?? [];
          newTeams?.remove(team.number);
          mutableData['teams'] = newTeams;
        } catch (e) {
          var newTeams = ((mutableData as Map)['teams'] as List?);
          ids = (newTeams?.firstWhere((element) =>
                          element['number'] == team.number)?['scores']
                      as Map<String, dynamic>?)
                  ?.keys
                  .toList() ??
              [];
          newTeams?.removeWhere((element) => element['number'] == team.number);
          mutableData['teams'] = newTeams;
        }
        var newMatches = (mutableData['matches'] as Map?);
        for (var id in ids) {
          newMatches?[id] = null;
        }
        mutableData['matches'] = newMatches;
        return Db.Transaction.success(mutableData);
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
        final newMatches = ((mutableData as Map)['matches'] as Map);
        newMatches.removeWhere((key, value) => key == e.id);
        mutableData['matches'] = newMatches;
        for (var team in e.getTeams()) {
          var teamIndex;
          try {
            mutableData['teams'] as Map;
            teamIndex = team?.number;
          } catch (e) {
            teamIndex = int.parse(team?.number ?? '');
          }
          try {
            var tempScores = (mutableData['teams'][teamIndex]['scores'] as Map);
            tempScores.remove(e.id);
            mutableData['teams'][teamIndex]['scores'] = tempScores;
          } catch (e) {}
        }
        return Db.Transaction.success(mutableData);
      },
    );
  }

  void updateLocal(dynamic map, BuildContext context) {
    if (map != null) {
      gameName = map['gameName'] ?? Statics.gameName;
      type = getTypeFromString(map['type']);
      name = map['name'];
      eventKey = map['event_key'];
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
        createdAt = getTimestampFromString(map['createdAt']) ?? Timestamp.now();
      } catch (e) {
        createdAt = map['createdAt'];
      }

      try {
        author = TeamTrackUser.fromJson(map['author'], null);
      } catch (e) {
        // IMPORTANT: these try catches exist for transitionary periods of the db (making sure old users can still access their data)
        author = TeamTrackUser(
          role: Role.editor,
          displayName: map['authorName'],
          email: map['authorEmail'],
        );
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

  Db.DatabaseReference? getRef() {
    if (!shared) return null;
    return firebaseDatabase.ref().child('Events/$gameName').child(id);
  }

  Event.fromJson(Map<String, dynamic>? json) {
    role = Role.editor;
    gameName = json?['gameName'] ?? Statics.gameName;
    type = getTypeFromString(json?['type']);
    statConfig.allianceTotal = (type == EventType.remote||type==EventType.analysis);
    name = json?['name'] ?? "";
    eventKey = json?['event_key'];
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
      createdAt = getTimestampFromString(json?['createdAt']) ?? Timestamp.now();
    } catch (e) {
      createdAt = json?['createdAt'];
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
  Map<String, dynamic> toJson([bool cloudFirestore = false]) => {
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
        'createdAt': cloudFirestore ? createdAt : createdAt.toJson(),
        'event_key': eventKey,
      };
  Map<String, dynamic> toSimpleJson() => {
        'gameName': gameName,
        'name': name,
        'type': type.toString(),
        'sendTime': sendTime,
        'id': id,
      };
}

/// Composed of 2 teams [team1] and [team2]
class Alliance {
  Team? team1;
  Team? team2;
  EventType eventType;
  Alliance? opposingAlliance;
  late Score sharedScore;
  String? id;
  int? totalScore;
  String gameName;
  Alliance(this.team1, this.team2, this.eventType, this.gameName) {
    sharedScore =
        Score(Uuid().v4(), Dice.none, gameName, isAllianceScore: true);
  }
  int getPenalty() {
    if (eventType == EventType.remote)
      return team1?.scores[id]?.penalties.total() ?? 0;
    final penaltiesAddToOpposingAlliance = json.decode(remoteConfig
            .getString(gameName))['PenaltiesAddToOpposingAlliance'] ??
        false;
    if (penaltiesAddToOpposingAlliance)
      return -(opposingAlliance?.penaltyTotal() ?? 0);
    else
      return penaltyTotal();
  }

  bool hasTeam(Team team) =>
      (team1 != null && team1!.equals(team)) ||
      (team2 != null && team2!.equals(team));

  int penaltyTotal() =>
      (team1?.scores[id]?.penalties.total() ?? 0) +
      (team2?.scores[id]?.penalties.total() ?? 0);

  Score combinedScore() {
    Score returnVal = (team1?.scores[id] ?? Score('', Dice.none, gameName)) +
        (team2?.scores[id] ?? Score('', Dice.none, gameName)) +
        (sharedScore);
    return returnVal;
  }

  int allianceTotal(
    bool? showPenalties, {
    OpModeType? type,
    ScoringElement? element,
  }) =>
      (((team1?.scores[id]
                          ?.getScoreDivision(type)
                          .getScoringElementCount(element?.key) ??
                      0) +
                  (team2?.scores[id]
                          ?.getScoreDivision(type)
                          .getScoringElementCount(element?.key) ??
                      0) +
                  ((showPenalties ?? false) && type == null
                      ? getPenalty()
                      : 0)) +
              (sharedScore
                      .getScoreDivision(type)
                      .getScoringElementCount(element?.key) ??
                  0))
          .clamp(type == null ? 0 : -999, 999);
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

/// Composed of 2 nullable alliances [red] and [blue].
/// null alliance indicates no alliance in play for that side (usually a remote event)
class Match {
  EventType type = EventType.local;
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

  /// Returns the alliance that [team] is on
  Alliance? alliance(Team? team) {
    if ((red?.team1?.equals(team) ?? false) ||
        (red?.team2?.equals(team) ?? false)) {
      return red;
    } else if ((blue?.team1?.equals(team) ?? false) ||
        (blue?.team2?.equals(team) ?? false)) {
      return blue;
    }
    return null;
  }

  /// Returns the opposing alliance of the alliance that [team] is on
  Alliance? opposingAlliance(Team? team) {
    if ((red?.team1?.equals(team) ?? false) ||
        (red?.team2?.equals(team) ?? false)) {
      return blue;
    } else if ((blue?.team1?.equals(team) ?? false) ||
        (blue?.team2?.equals(team) ?? false)) {
      return red;
    }
    return null;
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

  void setAPIScore(int redScore, int blueScore) {
    red?.totalScore = redScore;
    blue?.totalScore = blueScore;
  }

  int? getRedAPI() {
    return red?.totalScore;
  }

  int? getBlueAPI() {
    return blue?.totalScore;
  }

  int getMaxScoreVal({required bool? showPenalties}) {
    return [
      redScore(showPenalties: showPenalties),
      blueScore(showPenalties: showPenalties)
    ].maxValue().toInt();
  }

  int redScore({required bool? showPenalties}) =>
      red?.allianceTotal(showPenalties) ?? 0;

  int blueScore({required bool? showPenalties}) =>
      blue?.allianceTotal(showPenalties) ?? 0;

  Alliance? getWinner() {
    if (redScore(showPenalties: true) > blueScore(showPenalties: true)) {
      return red;
    } else if (redScore(showPenalties: true) < blueScore(showPenalties: true)) {
      return blue;
    } else {
      return null;
    }
  }

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
      timeStamp = getTimestampFromString(json['createdAt']) ?? Timestamp.now();
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
        'createdAt': timeStamp.toJson(),
      };
  Score? getScore(String? number) {
    if (number == red?.team1?.number)
      return red?.team1?.scores[id];
    else if (number == red?.team2?.number)
      return red?.team2?.scores[id];
    else if (number == blue?.team1?.number)
      return blue?.team1?.scores[id];
    else if (number == blue?.team2?.number) return blue?.team2?.scores[id];
    return null;
  }

  Score? getAllianceScore(String? number) {
    if (number == red?.team1?.number || number == red?.team2?.number)
      return red?.combinedScore();
    else if (number == blue?.team1?.number || number == blue?.team2?.number)
      return blue?.combinedScore();
    return null;
  }
}

/// Teams are represented by their unique [number] and any [name]
class Team {
  String name = '';
  String number = '';
  int? established;
  String? city;
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

  String? getWLT(Event event) {
    if (event.type == EventType.remote||event.type == EventType.analysis) return null;
    int wins = 0;
    int losses = 0;
    int ties = 0;
    for (final match in event.matches.values) {
      if (match.alliance(this) != null) {
        if (match.getWinner() == match.alliance(this)) {
          wins++;
        } else if (match.getWinner() == null) {
          ties++;
        } else {
          losses++;
        }
      }
    }
    return '$wins-$losses-$ties';
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
      changes = (json['changes'] as Map?)
              ?.map((key, value) => MapEntry(key, Change.fromJson(value)))
              .values
              .toList() ??
          [];
    } catch (e) {
      changes = [];
    }
  }

  void updateWithTOA(dynamic toa) {
    if (toa == null) return;
    // name = toa['team_name_short'] ?? name;
    established = (toa['rookie_year'] ?? this.established) as int?;
    city = toa['city'] ?? city;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'number': number,
        'scores': scores.map((key, value) => MapEntry(key, value.toJson())),
        'targetScore': targetScore?.toJson(),
        'changes': Map.fromIterable(changes.map((change) => change.toJson()),
            key: (change) => change['id']),
      };
}
