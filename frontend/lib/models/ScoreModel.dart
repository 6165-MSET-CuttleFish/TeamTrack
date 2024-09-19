import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/functions/Statistics.dart';

/// This class is used to represent the scoring structure of traditional and remote FTC events via [teleScore], [autoScore], [endgameScore], and [penalties]
class Score extends ScoreDivision implements Comparable<Score> {
  late TeleScore teleScore;
  late AutoScore autoScore;
  late EndgameScore endgameScore;
  late Penalty penalties;
  Map<String, bool> defendedTeamNumbers = {};
  List<Team> defendedTeams(Event event) => defendedTeamNumbers.keys
      .map((number) => event.teams[number])
      .whereType<Team>()
      .toList(); // for future Defensive Power Rating stuff
  String id = '';
  String gameName;
  late Dice dice;
  bool isAllianceScore;
  Score(this.id, this.dice, this.gameName, {this.isAllianceScore = false}) {
    var ref = isAllianceScore
        ? json.decode(remoteConfig.getString(gameName))['Alliance']
        : json.decode(remoteConfig.getString(gameName));
    teleScore = TeleScore(ref['TeleScore']);
    autoScore = AutoScore(ref['AutoScore']);
    endgameScore = EndgameScore(ref['EndgameScore']);
    penalties = Penalty(ref['Penalty']);
    for (ScoringElement element in autoScore.getElements()) {
      element.doubleScoresElement = teleScore.elements[element.key];
      teleScore.elements[element.key]?.initialCount = element.totalCount();
    }
    setDice(dice, Timestamp.now());
  }
  List<ScoringElement> getElements({bool? showPenalties}) => [
        ...teleScore.getElements(),
        ...autoScore.getElements(),
        ...endgameScore.getElements(),
        if (showPenalties ?? false) ...penalties.getElements(),
      ];
  @override
  int? total({bool? showPenalties, bool markDisconnect = false}) {
    bool disconnected = autoScore.robotDisconnected ||
        teleScore.robotDisconnected ||
        endgameScore.robotDisconnected;
    if (disconnected && markDisconnect) return null;
    final list = getElements(showPenalties: showPenalties)
        .map((e) => e.scoreValue())
        .toList();
    if (list.isEmpty) return 0;
    return list.sum().toInt().clamp(0, 999);
  }

  /// Returns the total division score specified by the [type]
  ScoreDivision getScoreDivision(OpModeType? type) {
    switch (type) {
      case OpModeType.auto:
        return autoScore;
      case OpModeType.tele:
        return teleScore;
      case OpModeType.endgame:
        return endgameScore;
      case OpModeType.penalty:
        return penalties;
      default:
        return this;
    }
  }

  /// Resets all the scores in the score division
  void reset() =>
      OpModeType.values.forEach((type) => getScoreDivision(type).reset());

  Score operator +(Score other) {
    Score result = Score(id, dice, gameName, isAllianceScore: isAllianceScore);
    result.autoScore = this.autoScore + other.autoScore;
    result.teleScore = this.teleScore + other.teleScore;
    result.endgameScore = this.endgameScore + other.endgameScore;
    result.penalties = this.penalties + other.penalties;
    return result;
  }

  @override
  Dice getDice() => dice;
  void setDice(Dice value, Timestamp time) {
    dice = value;
    autoScore.dice = value;
    teleScore.dice = value;
    endgameScore.dice = value;
    penalties.dice = value;
    timeStamp = time;
    autoScore.timeStamp = time;
    teleScore.timeStamp = time;
    endgameScore.timeStamp = time;
    penalties.timeStamp = time;
  }

  Score.fromJson(Map<String, dynamic> map, this.gameName,
      {this.isAllianceScore = false}) {
    var ref = isAllianceScore
        ? json.decode(remoteConfig.getString(gameName))['Alliance']
        : json.decode(remoteConfig.getString(gameName));
    //Map<String, dynamic> ref = isAllianceScore ? absRef['Alliance'] : absRef;
    autoScore = map['AutoScore'] != null && (map['AutoScore'] as Map).isNotEmpty
        ? AutoScore.fromJson(map['AutoScore'], ref['AutoScore'])
        : AutoScore(ref['AutoScore']);
    teleScore = map['TeleScore'] != null && (map['TeleScore'] as Map).isNotEmpty
        ? TeleScore.fromJson(map['TeleScore'], ref['TeleScore'])
        : TeleScore(ref['TeleScore']);
    endgameScore =
        map['EndgameScore'] != null && (map['EndgameScore'] as Map).isNotEmpty
            ? EndgameScore.fromJson(map['EndgameScore'], ref['EndgameScore'])
            : EndgameScore(ref['EndgameScore']);
    penalties = map['Penalty'] != null && (map['Penalty'] as Map).isNotEmpty
        ? Penalty.fromJson(map['Penalty'], ref['Penalty'])
        : Penalty(ref['Penalty']);
    id = map['id'];
    autoScore.robotDisconnected = map['autoDc'] ?? false;
    teleScore.robotDisconnected = map['teleDc'] ?? false;
    endgameScore.robotDisconnected = map['endDc'] ?? false;
    try {
      defendedTeamNumbers = map['defendedTeams'] ?? {};
    } catch (e) {
      defendedTeamNumbers = {};
    }
    for (ScoringElement element in autoScore.getElements()) {
      element.doubleScoresElement = teleScore.elements[element.key];
      teleScore.elements[element.key]?.initialCount = element.totalCount();
    }
    setDice(Dice.one, Timestamp.now());
  }
  Map<String, dynamic> toJson() => {
        'AutoScore': autoScore.toJson(),
        'TeleScore': teleScore.toJson(),
        'EndgameScore': endgameScore.toJson(),
        'Penalty': penalties.toJson(),
        'id': id.toString(),
        'autoDC': autoScore.robotDisconnected,
        'teleDC': teleScore.robotDisconnected,
        'endgameDC': endgameScore.robotDisconnected,
        'defendedTeams': defendedTeamNumbers,
      };

  @override
  int compareTo(Score other) => (total() ?? 0).compareTo(other.total() ?? 0);
}

extension scoreList on Map<String, Score> {
  void addScore(Score value) {
    this[value.id] = value;
  }
}

/// This class is used to represent the autonomous score structure of traditional and remote FTC events.
/// Remote config capable, so to change the structure of autonomous, do so in the Firebase Remote Config console
class AutoScore extends ScoreDivision {
  void reset() {
    for (final element in this.getElements()) {
      element.resetCount();
      element.resetMisses();
    }
  }

  late Dice dice;
  dynamic ref;
  Dice getDice() => dice;
  AutoScore(this.ref) {
    init();
  }

  AutoScore operator +(AutoScore other) {
    var autoScore = AutoScore(ref);
    for (final key in elements.keys) {
      autoScore.elements[key] = (elements[key] ?? ScoringElement.nullScore()) +
          (other.elements[key] ?? ScoringElement.nullScore());
    }
    for (final key in other.elements.keys) {
      if (autoScore.elements[key] == null) {
        autoScore.elements[key] =
            other.elements[key] ?? ScoringElement.nullScore();
      }
    }
    return autoScore;
  }

  AutoScore.fromJson(Map<String, dynamic> map, this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          normalCount: map[e] is Map ? (map[e]['count'] ?? 0) : (map[e] ?? 0),
          normalMisses: map[e] is Map ? (map[e]['misses'] ?? 0) : 0,
          endgameCount: map[e] is Map ? (map[e]['endgameCount'] ?? 0) : 0,
          endgameMisses: map[e] is Map ? (map[e]['endgameMisses'] ?? 0) : 0,
          cycleTimes: map[e] is Map ? decodeArray(map[e]?['cycleTimes']) : [],
          min: () => ref[e]['min'] ?? 0,
          value: ref[e]['value'] ?? 1,
          isBool: ref[e]['isBool'] ?? false,
          key: e,
          id: ref[e]['id'],
        );
      },
    );
    maxSet();
  }
  Map<String, dynamic> toJson() =>
      elements.map((key, value) => MapEntry(key, value.toJson()));
}

/// This class is used to represent the teleop score structure of traditional and remote FTC events.
/// Remote config capable, so to change the structure of teleop, do so in the Firebase Remote Config console
class TeleScore extends ScoreDivision {
  void reset() {
    for (final element in this.getElements()) {
      element.resetCount();
      element.resetMisses();
    }
  }

  late Dice dice;

  Dice getDice() => dice;
  dynamic ref;
  TeleScore(this.ref) {
    init();
  }

  TeleScore operator +(TeleScore other) {
    var teleScore = TeleScore(ref);
    teleScore.dice = dice;
    teleScore.elements.keys.forEach(
      (key) {
        teleScore.elements[key] =
            (elements[key] ?? ScoringElement.nullScore()) +
                (other.elements[key] ?? ScoringElement.nullScore());
      },
    );
    other.elements.keys.forEach((key) {
      if (teleScore.elements[key] == null) {
        teleScore.elements[key] =
            other.elements[key] ?? ScoringElement.nullScore();
      }
    });
    return teleScore;
  }

  TeleScore.fromJson(Map<String, dynamic> map, this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          normalCount: map[e] is Map ? (map[e]['count'] ?? 0) : (map[e] ?? 0),
          normalMisses: map[e] is Map ? map[e]['misses'] : 0,
          endgameCount: map[e] is Map ? (map[e]['endgameCount'] ?? 0) : 0,
          endgameMisses: map[e] is Map ? (map[e]['endgameMisses'] ?? 0) : 0,
          cycleTimes: map[e] is Map ? decodeArray(map[e]?['cycleTimes']) : [],
          min: () => ref[e]['min'] ?? 0,
          value: ref[e]['value'] ?? 1,
          isBool: ref[e]['isBool'] ?? false,
          key: e,
          id: ref[e]['id'],
        );
      },
    );
    maxSet();
  }
  Map<String, dynamic> toJson() =>
      elements.map((key, value) => MapEntry(key, value.toJson()));
}

List<double> decodeArray(List<dynamic>? map) => map == null
    ? []
    : List<num>.from(json.decode(map.toString()))
        .map((e) => e.toDouble())
        .toList();

/// This class is used to represent the endgame score structure of traditional and remote FTC events.
/// Remote config capable, so to change the structure of endgame, do so in the Firebase Remote Config console
class EndgameScore extends ScoreDivision {
  void reset() {
    for (final element in this.getElements()) {
      element.resetCount();
      element.resetMisses();
    }
  }

  late Dice dice;
  dynamic ref;
  Dice getDice() => dice;
  EndgameScore(this.ref) {
    init();
  }

  EndgameScore operator +(EndgameScore other) {
    var endgameScore = EndgameScore(ref);
    endgameScore.dice = dice;
    endgameScore.elements.keys.forEach(
      (key) {
        endgameScore.elements[key] =
            (elements[key] ?? ScoringElement.nullScore()) +
                (other.elements[key] ?? ScoringElement.nullScore());
      },
    );
    other.elements.keys.forEach((key) {
      if (endgameScore.elements[key] == null) {
        endgameScore.elements[key] =
            other.elements[key] ?? ScoringElement.nullScore();
      }
    });
    return endgameScore;
  }

  EndgameScore.fromJson(Map<String, dynamic> map, this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          normalCount: map[e] is Map ? (map[e]['count'] ?? 0) : (map[e] ?? 0),
          normalMisses: map[e] is Map ? map[e]['misses'] : 0,
          endgameCount: map[e] is Map ? (map[e]['endgameCount'] ?? 0) : 0,
          endgameMisses: map[e] is Map ? (map[e]['endgameMisses'] ?? 0) : 0,
          cycleTimes: map[e] is Map ? decodeArray(map[e]?['cycleTimes']) : [],
          min: () => ref[e]['min'] ?? 0,
          value: ref[e]['value'] ?? 1,
          isBool: ref[e]['isBool'] ?? false,
          key: e,
          id: ref[e]['id'],
        );
      },
    );
    maxSet();
  }
  Map<String, dynamic> toJson() =>
      elements.map((key, value) => MapEntry(key, value.toJson()));
}

/// This class is used to represent the penalty structure of traditional and remote FTC events.
/// Remote config capable, so to change the structure of penalties, do so in the Firebase Remote Config console
class Penalty extends ScoreDivision {
  void reset() {
    for (final element in this.getElements()) {
      element.resetCount();
      element.resetMisses();
    }
  }

  late ScoringElement majorPenalty;
  late ScoringElement minorPenalty;
  late Dice dice;
  dynamic ref;
  Penalty(this.ref) {
    if (ref == null) {
      majorPenalty =
          ScoringElement(name: 'Major Penalty', value: -30, key: 'major');
      minorPenalty =
          ScoringElement(name: 'Minor Penalty', value: -10, key: 'minor');
      elements = {
        'major': majorPenalty,
        'minor': minorPenalty,
      };
    } else {
      init();
    }
  }

  @override
  Dice getDice() => dice;

  @override
  int total({bool? showPenalties, bool markDisconnect = false}) {
    final list = elements.values.map((e) => e.scoreValue());
    final sum = list.sum().toInt();
    return sum;
  }

  Penalty operator +(Penalty other) {
    if (ref == null) {
      final penalty = Penalty(ref);
      penalty.dice = dice;
      penalty.majorPenalty = other.majorPenalty + majorPenalty;
      penalty.minorPenalty = other.minorPenalty + minorPenalty;
      penalty.elements = {
        'major': penalty.majorPenalty,
        'minor': penalty.minorPenalty,
      };
      return penalty;
    } else {
      final penalty = Penalty(ref);
      penalty.dice = dice;
      penalty.elements.keys.forEach(
        (key) {
          penalty.elements[key] =
              (elements[key] ?? ScoringElement.nullScore()) +
                  (other.elements[key] ?? ScoringElement.nullScore());
        },
      );
      other.elements.keys.forEach((key) {
        if (penalty.elements[key] == null) {
          penalty.elements[key] =
              other.elements[key] ?? ScoringElement.nullScore();
        }
      });
      return penalty;
    }
  }

  Penalty.fromJson(Map<String, dynamic> map, this.ref) {
    if (ref == null) {
      majorPenalty = ScoringElement(
        name: 'Major Penalty',
        value: -30,
        normalCount: map['major'] is Map ? map['major']['count'] : map['major'],
        key: 'major',
      );
      minorPenalty = ScoringElement(
        name: 'Minor Penalty',
        value: -10,
        normalCount: map['minor'] is Map ? map['minor']['count'] : map['minor'],
        key: 'minor',
      );
      elements = {
        'major': majorPenalty,
        'minor': minorPenalty,
      };
    } else {
      ref.keys.forEach(
        (e) {
          elements[e] = ScoringElement(
            name: ref[e]['name'] ?? e,
            normalCount: map[e] is Map ? (map[e]['count'] ?? 0) : (map[e] ?? 0),
            normalMisses: map[e] is Map ? map[e]['misses'] : 0,
            endgameCount: map[e] is Map ? (map[e]['endgameCount'] ?? 0) : 0,
            endgameMisses: map[e] is Map ? (map[e]['endgameMisses'] ?? 0) : 0,
            cycleTimes: map[e] is Map ? decodeArray(map[e]?['cycleTimes']) : [],
            min: () => ref[e]['min'] ?? 0,
            value: ref[e]['value'] ?? 1,
            isBool: ref[e]['isBool'] ?? false,
            key: e,
            id: ref[e]['id'],
          );
        },
      );
      maxSet();
    }
  }
  Map<String, dynamic> toJson() => {
        'major': majorPenalty.toJson(),
        'minor': minorPenalty.toJson(),
      };
}

enum ScoreELement {
  Incrementable,

}

/// This class is used to represent a Scoring Element of an FTC event.
class ScoringElement implements Scorable {
  ScoringElement({
    required this.name,
    this.normalCount = 0,
    this.normalMisses = 0,
    this.endgameCount = 0,
    this.endgameMisses = 0,
    this.initialCount = 0,
    this.cycleTimes = const [],
    required this.value,
    this.min,
    this.max,
    this.isBool = false,
    this.key,
    this.id,
    this.nestedElements,
    this.totalValue,
  }) {
    setStuff();
  }

  ScoringElement.nullScore()
      : name = '',
        normalCount = 0,
        normalMisses = 0,
        cycleTimes = const [],
        value = 1,
        isBool = false,
        key = '';

  String name;
  String? key;
  int normalCount = 0;
  int normalMisses = 0;

  int endgameCount = 0;
  int endgameMisses = 0;

  int initialCount = 0;

  int value;
  int? totalValue; // can be used in place of count for total value
  String? id;
  List<double> cycleTimes = [];
  List<ScoringElement>? nestedElements;
  ScoringElement? doubleScoresElement;

  bool isBool;
  late int Function()? min = () => 0;
  late int Function()? max = () => 999;
  int incrementValue = 1;
  int decrementValue = 1;

  bool asBool() => totalCount() == 0 ? false : true;

  void setStuff() {
    if (min == null) min = () => 0;
    if (max == null) max = () => 999;
  }

  void setCount(double seconds, int count) {
    if (seconds > 90) {
      endgameCount = count;
    } else {
      normalCount = count;
    }
  }

  void setMisses(double seconds, int misses) {
    if (seconds > 90) {
      endgameMisses = misses;
    } else {
      normalMisses = misses;
    }
  }

  void changeMisses(double seconds, int misses) {
    if (seconds > 90) {
      endgameMisses += misses;
      endgameMisses = endgameMisses.clamp(0, 999);
    } else {
      normalMisses += misses;
      normalMisses = normalMisses.clamp(0, 999);
    }
  }

  // normalCount + endgameCount + initialCount >= min()
  // normalCount + endgameCount + initialCount <= max()
  void changeCount(double seconds, int count) {
    if (seconds > 90) {
      endgameCount += count;
      endgameCount = endgameCount.clamp(
        min!() - normalCount - initialCount,
        max!() - normalCount - initialCount,
      );
    } else {
      normalCount += count;
      normalCount = normalCount.clamp(
        min!() - endgameCount - initialCount,
        max!() - endgameCount - initialCount,
      );
    }
    doubleScoresElement?.initialCount += count;
  }

  void resetCount() {
    print(netCount());
    normalCount = 0;
    endgameCount = 0;

    print(netCount());
  }

  void resetMisses() {
    normalMisses = 0;
    endgameMisses = 0;
  }

  int scoreValue() {
    if (nestedElements != null) {
      return nestedElements!.map((e) => e.scoreValue()).sum().toInt();
    }
    return totalValue ?? ((normalCount + endgameCount + initialCount) * value);
  }

  int netCount() => totalCount() + initialCount;

  int totalCount() => normalCount + endgameCount;

  int totalMisses() => normalMisses + endgameMisses;

  int normalCycles() => normalCount + normalMisses;

  int endgameCycles() => endgameCount + endgameMisses;

  bool didAttempt() =>
      totalMisses() > 0 ||
      totalCount() > 0 ||
      (nestedElements
      ?.reduce(
            (value, element) {
              if (element.didAttempt()) value.normalCount = 1;
              return value;
            },
          ).didAttempt() ??
          false);

  int? totalAttempted() => didAttempt() ? totalCount() + totalMisses() : null;

  int? countFactoringAttempted() => didAttempt() ? normalCount : null;

  int? total() => didAttempt() ? scoreValue() : null;

  int? scoreValueFactoringAttempted() => didAttempt() ? scoreValue() : null;

  Map<String, dynamic> toJson() => {
        'count': normalCount,
        'misses': normalMisses,
        'cycleTimes': cycleTimes,
        'endgameCount': endgameCount,
        'endgameMisses': endgameMisses,
      };

  ScoringElement.fromJson(
    Map<String, dynamic> map, {
    required this.name,
    required this.value,
    required this.key,
    this.isBool = false,
    this.max,
    this.min,
  }) {
    normalCount = map['count'];
    normalMisses = map['misses'];
    cycleTimes = decodeArray(map['cycleTimes']);
    endgameMisses = map['endgameMisses'] ?? 0;
    endgameCount = map['endgameCount'] ?? 0;
    setStuff();
  }

  ScoringElement operator +(ScoringElement other) {
    return ScoringElement(
      normalCount: other.normalCount + normalCount,
      normalMisses: other.normalMisses + normalMisses,
      endgameCount: other.endgameCount + endgameCount,
      endgameMisses: other.endgameMisses + endgameMisses,
      initialCount: other.initialCount + initialCount,
      value: value,
      key: other.key,
      name: name,
      isBool: isBool,
      min: min,
      max: max,
    );
  }
}

abstract class ScoreDivision implements Scorable {
  void maxSet() {
    ref.keys.forEach(
      (e) {
        if (ref[e]['maxIsReference'] ?? false) {
          final reference = elements[ref[e]['max']['reference']];
          int ceil = ref[e]['max']['total'];
          elements[e]?.max =
              () => (ceil - (reference?.netCount() ?? 0)).toInt();
        } else {
          elements[e]?.max = () => ref[e]['max'];
        }
      },
    );
  }

  void init() {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          min: () => ref[e]['min'] ?? 0,
          value: ref[e]['value'] ?? 1,
          isBool: ref[e]['isBool'] ?? false,
          key: e,
          id: ref[e]['id'],
        );
      },
    );
    maxSet();
  }

  int? total({bool? showPenalties, bool markDisconnect = true}) =>
      (markDisconnect && robotDisconnected)
          ? null
          : getElements().length == 0
              ? 0
              : getElements()
                  .map((e) => e.scoreValue())
                  .sum()
                  .toInt();

  Dice getDice();
  List<ScoringElement> getElements() =>
      elements.values.toList(); // get the scoring elements
  dynamic ref; // get the reference object
  Map<String, ScoringElement> elements = {};
  late Timestamp timeStamp; // the time stamp of the Score object
  void reset(); // reset the scoring elements
  bool robotDisconnected = false; // whether the robot disconnected
  int? getScoringElementCount(String? key) {
    if (key == null && !robotDisconnected) {
      final x = total();
      return x;
    }
    final scoringElement = this.getElements().parse().firstWhere(
          (e) => e.key == key,
          orElse: () => ScoringElement.nullScore(),
        );
    if (scoringElement.didAttempt() && !robotDisconnected)
      return scoringElement.scoreValue();
    return null;
  }
}

abstract class Scorable {
  int? total();
}

// example skeleton for the firabase remote config game skeleton (current example is not optimal and there are probably areas in the config where you can reduce redundancies)
const exampleSkeleton = {
  "AutoScore": {
    "ExampleScoringElement1": {
      "name": "Duck Delivered", // name shown in the app
      "min":
          0, // minimum score for this element (probably redundant for when isBool is true)
      "max":
          1, // maximum score for this element (probably redundant for when isBool is false)
      "value": 10, // scoring value of the element
      "isBool": true // represented by a toggle switch on the UI
    },
    "ExampleScoringElement2": {
      "id":
          "Storage Park", // the group this element belongs to (UI shows this in either a cupertino segmented bar or a expandable list tile)
      "isBool":
          true, // represented by a cupertino segmented bar on the UI in this case. if this is false then the UI shows this element in an expandable list tile
      "name": "Partial", // name shown in the app
      "min": 0,
      "maxIsReference":
          true, // set to true if the maximum references a different element (does not have to be in the same group)
      "max": {
        "total":
            1, // the max value for the sum of both the current element and the referenced element
        "reference":
            "FullParkStorage" // the key of the element that is referenced (not the id)
      },
      "value": 3,
    },
  },
  "TeleScore": {
    "sharedFreight": {
      "name": "Freight in Shared Hub",
      "min": 0,
      "max": 999,
      "value": 4
    },
    "lvl3": {"name": "Level 3", "min": 0, "max": 999, "value": 6},
    "lvl2": {"name": "Level 2", "min": 0, "max": 999, "value": 4},
    "lvl1": {"name": "Level 1", "min": 0, "max": 999, "value": 2},
    "storageFreight": {
      "name": "Freight in Storage Unit",
      "min": 0,
      "max": 999,
      "value": 1
    }
  },
  "EndgameScore": {
    "DucksDelivered": {
      "name": "Ducks Delivered",
      "min": 0,
      "max": 10,
      "value": 6
    },
    "PartialWarehouseParked": {
      "name": "Partial",
      "id": "Warehouse Park",
      "min": 0,
      "maxIsReference": true,
      "max": {"total": 1, "reference": "FullWarehouseParked"},
      "value": 3,
      "isBool": true
    },
    "FullWarehouseParked": {
      "name": "Full",
      "id": "Warehouse Park",
      "min": 0,
      "maxIsReference": true,
      "max": {"total": 1, "reference": "PartialWarehouseParked"},
      "value": 6,
      "isBool": true
    },
    "Element": {
      "name": "Team Element Capped",
      "min": 0,
      "max": 1,
      "value": 15,
      "isBool": true
    }
  },
  "Dice": {
    // initial dice roll for the autonomous period
    "1": "Left", // the first die roll
    "2": "Middle", // the second die roll
    "3": "Right", // the third die roll
    "name":
        "Barcode", // the name of the thing being randomized ; will show as 'Barcode: Left' etc.
  },
  "Alliance": {
    // general alliance scoring elements not attributed to any team in particular but to the alliance as a whole
    "AutoScore": {},
    "TeleScore": {},
    "EndgameScore": {
      "AllianceHubBalanced": {
        "name": "Alliance Hub Balanced",
        "min": 0,
        "max": 1,
        "value": 10,
        "isBool": true
      },
      "SharedHubTipped": {
        "name": "Shared Hub Tipped",
        "min": 0,
        "max": 1,
        "value": 20,
        "isBool": true
      }
    }
  },
  "PenaltiesAddToOpposingAlliance":
      false // if true then penalties are added to the opposing alliance's score
};
