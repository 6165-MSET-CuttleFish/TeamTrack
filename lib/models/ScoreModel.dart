import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/functions/Statistics.dart';

Map<String, dynamic> absRef = {
  "AutoScore": {
    "DuckDelivered": {
      "name": "Duck Delivered",
      "min": 0,
      "max": 1,
      "value": 10,
      "isBool": true
    },
    "PartialParkStorage": {
      "name": "Partial",
      "id": "Storage Park",
      "min": 0,
      "maxIsReference": true,
      "max": {"total": 1, "reference": "FullParkStorage"},
      "value": 3,
      "isBool": true
    },
    "FullParkStorage": {
      "name": "Full",
      "id": "Storage Park",
      "min": 0,
      "maxIsReference": true,
      "max": {"total": 1, "reference": "PartialParkStorage"},
      "value": 6,
      "isBool": true
    },
    "PartialParkWarehouse": {
      "name": "Partial",
      "id": "Warehouse Park",
      "min": 0,
      "maxIsReference": true,
      "max": {"total": 1, "reference": "FullParkWarehouse"},
      "value": 5,
      "isBool": true
    },
    "FullParkWarehouse": {
      "name": "Full",
      "id": "Warehouse Park",
      "min": 0,
      "maxIsReference": true,
      "max": {"total": 1, "reference": "PartialParkWarehouse"},
      "value": 10,
      "isBool": true
    },
    "FreightInStorage": {
      "name": "Storage Freight",
      "min": 0,
      "max": 999,
      "value": 2
    },
    "FreightInHub": {"name": "Hub Freight", "min": 0, "max": 999, "value": 6},
    "DuckLevelBonus": {
      "name": "Duck",
      "id": "Bonus",
      "min": 0,
      "maxIsReference": true,
      "max": {"total": 1, "reference": "ShippingLevelBonus"},
      "value": 10,
      "isBool": true
    },
    "ShippingLevelBonus": {
      "name": "Team Element",
      "id": "Bonus",
      "min": 0,
      "maxIsReference": true,
      "max": {"total": 1, "reference": "DuckLevelBonus"},
      "value": 20,
      "isBool": true
    }
  },
  "TeleScore": {
    "sharedFreight": {"name": "Shared Hub", "min": 0, "max": 999, "value": 4},
    "lvl3": {
      "name": "Level 3",
      "min": 0,
      "max": 999,
      "value": 6,
      "id": "Alliance Hub"
    },
    "lvl2": {
      "name": "Level 2",
      "min": 0,
      "max": 999,
      "value": 4,
      "id": "Alliance Hub"
    },
    "lvl1": {
      "name": "Level 1",
      "min": 0,
      "max": 999,
      "value": 2,
      "id": "Alliance Hub"
    },
    "storageFreight": {"name": "Storage Unit", "min": 0, "max": 999, "value": 1}
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
  "Dice": {"1": "Left", "2": "Middle", "3": "Right", "name": "Barcode"},
  "Alliance": {
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
  }
};

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
    setDice(dice, Timestamp.now());
  }
  List<ScoringElement> getElements({bool? showPenalties}) => [
        ...teleScore.getElements(),
        ...autoScore.getElements(),
        ...endgameScore.getElements(),
        ...((showPenalties ?? false) ? penalties.getElements() : [])
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
    if (list.length == 0) return 0;
    return list.sum().toInt().clamp(0, 999);
  }

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

  void reset() => [
        teleScore,
        autoScore,
        endgameScore,
        penalties,
      ].forEach(
        (e) => e.reset(),
      );

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
      element.count = 0;
    }
  }

  late Dice dice;
  void setCount(String key, int n) {
    elements[key]?.count = n;
  }

  dynamic ref;
  Dice getDice() => dice;
  AutoScore(this.ref) {
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

  void maxSet() {
    ref.keys.forEach(
      (e) {
        if (ref[e]['maxIsReference'] ?? false) {
          final reference = elements[ref[e]['max']['reference']];
          int ceil = ref[e]['max']['total'];
          elements[e]?.max = () => (ceil - (reference?.count ?? 0)).toInt();
        } else {
          elements[e]?.max = () => ref[e]['max'];
        }
      },
    );
  }

  AutoScore operator +(AutoScore other) {
    var autoScore = AutoScore(ref);
    for (final key in elements.keys) {
      autoScore.elements[key] = (elements[key] ?? ScoringElement()) +
          (other.elements[key] ?? ScoringElement());
    }
    for (final key in other.elements.keys) {
      if (autoScore.elements[key] == null) {
        autoScore.elements[key] = other.elements[key] ?? ScoringElement();
      }
    }
    return autoScore;
  }

  AutoScore.fromJson(Map<String, dynamic> map, this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          count: map[e] is Map ? map[e]['count'] : map[e],
          misses: map[e] is Map ? map[e]['misses'] : 0,
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
      element.count = 0;
    }
    misses.count = 0;
  }

  late Dice dice;

  ScoringElement misses =
      ScoringElement(name: "Misses", value: 1, key: 'Misses');
  Dice getDice() => dice;
  dynamic ref;
  TeleScore(this.ref) {
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

  void maxSet() {
    ref.keys.forEach(
      (e) {
        if (ref[e]['maxIsReference'] ?? false) {
          int ceil = ref[e]['max']['total'];
          elements[e]?.max = () =>
              (ceil - (elements[ref[e]['max']['reference']]?.count ?? 0))
                  .toInt();
        } else {
          elements[e]?.max = () => ref[e]['max'];
        }
      },
    );
  }

  TeleScore operator +(TeleScore other) {
    var teleScore = TeleScore(ref);
    teleScore.dice = dice;
    teleScore.elements.keys.forEach(
      (key) {
        teleScore.elements[key] = (elements[key] ?? ScoringElement()) +
            (other.elements[key] ?? ScoringElement());
      },
    );
    other.elements.keys.forEach((key) {
      if (teleScore.elements[key] == null) {
        teleScore.elements[key] = other.elements[key] ?? ScoringElement();
      }
    });
    teleScore.misses = misses + other.misses;
    return teleScore;
  }

  TeleScore.fromJson(Map<String, dynamic> map, this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          count: map[e] is Map ? map[e]['count'] : map[e],
          misses: map[e] is Map ? map[e]['misses'] : 0,
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

List<double> decodeArray(List<dynamic>? map) {
  if (map == null) return [];
  final x = List<num>.from(json.decode(map.toString()))
      .map((e) => e.toDouble())
      .toList();
  return x;
}

/// This class is used to represent the endgame score structure of traditional and remote FTC events.
/// Remote config capable, so to change the structure of endgame, do so in the Firebase Remote Config console
class EndgameScore extends ScoreDivision {
  void reset() {
    for (final element in this.getElements()) {
      element.count = 0;
    }
  }

  late Dice dice;
  dynamic ref;
  Dice getDice() => dice;
  EndgameScore(this.ref) {
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

  void maxSet() {
    ref.keys.forEach(
      (e) {
        if (ref[e]['maxIsReference'] ?? false) {
          int ceil = ref[e]['max']['total'];
          elements[e]?.max = () =>
              (ceil - (elements[ref[e]['max']['reference']]?.count ?? 0))
                  .toInt();
        } else {
          elements[e]?.max = () => ref[e]['max'];
        }
      },
    );
  }

  EndgameScore operator +(EndgameScore other) {
    var endgameScore = EndgameScore(ref);
    endgameScore.dice = dice;
    endgameScore.elements.keys.forEach(
      (key) {
        endgameScore.elements[key] = (elements[key] ?? ScoringElement()) +
            (other.elements[key] ?? ScoringElement());
      },
    );
    other.elements.keys.forEach((key) {
      if (endgameScore.elements[key] == null) {
        endgameScore.elements[key] = other.elements[key] ?? ScoringElement();
      }
    });
    return endgameScore;
  }

  EndgameScore.fromJson(Map<String, dynamic> json, this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          count: json[e] is Map ? json[e]['count'] : json[e],
          misses: json[e] is Map ? json[e]['misses'] : 0,
          cycleTimes: json[e] is Map ? decodeArray(json[e]?['cycleTimes']) : [],
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
class Penalty extends ScoreDivision {
  void reset() {
    for (final element in this.getElements()) {
      element.count = 0;
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
      ref.keys.forEach(
        (e) {
          elements[e] = ScoringElement(
            name: ref[e]['name'] ?? e,
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

  void maxSet() {
    ref.keys.forEach(
      (e) {
        if (ref[e]['maxIsReference'] ?? false) {
          int ceil = ref[e]['max']['total'];
          elements[e]?.max = () =>
              (ceil - (elements[ref[e]['max']['reference']]?.count ?? 0))
                  .toInt();
        } else {
          elements[e]?.max = () => ref[e]['max'];
        }
      },
    );
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
          penalty.elements[key] = (elements[key] ?? ScoringElement()) +
              (other.elements[key] ?? ScoringElement());
        },
      );
      other.elements.keys.forEach((key) {
        if (penalty.elements[key] == null) {
          penalty.elements[key] = other.elements[key] ?? ScoringElement();
        }
      });
      return penalty;
    }
  }

  Penalty.fromJson(Map<String, dynamic> json, this.ref) {
    if (ref == null) {
      majorPenalty = ScoringElement(
        name: 'Major Penalty',
        value: -30,
        count: json['major'] is Map ? json['major']['count'] : json['major'],
        key: 'major',
      );
      minorPenalty = ScoringElement(
        name: 'Minor Penalty',
        value: -10,
        count: json['minor'] is Map ? json['minor']['count'] : json['minor'],
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
            count: json[e] is Map ? json[e]['count'] : json[e],
            misses: json[e] is Map ? json[e]['misses'] : 0,
            cycleTimes:
                json[e] is Map ? decodeArray(json[e]?['cycleTimes']) : [],
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

/// This class is used to represent a Scoring Element of FTC events.
class ScoringElement {
  ScoringElement({
    this.name = '',
    this.count = 0,
    this.misses = 0,
    this.cycleTimes = const [],
    this.value = 1,
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
  String name;
  String? key;
  int count;
  int misses;
  int value;
  int? totalValue;
  String? id;
  List<double> cycleTimes;
  List<ScoringElement>? nestedElements;
  bool isBool;
  late int Function()? min = () => 0;
  late int Function()? max = () => 999;
  int incrementValue = 1;
  int decrementValue = 1;

  bool asBool() => count == 0 ? false : true;

  void setStuff() {
    if (min == null) min = () => 0;
    if (max == null) max = () => 999;
  }

  int scoreValue() {
    if (nestedElements != null) {
      return nestedElements!
          .map((e) => e.scoreValue())
          .reduce((value, element) => value + element);
    }
    return totalValue ?? (count * value);
  }

  bool didAttempt() =>
      misses > 0 ||
      count > 0 ||
      (nestedElements?.reduce((value, element) {
            if (element.didAttempt()) value.count = 1;
            return value;
          }).didAttempt() ??
          false);

  int totalAttempted() => count + misses;

  int? countFactoringAttempted() => didAttempt() ? count : null;

  int? scoreValueFactoringAttempted() => didAttempt() ? scoreValue() : null;

  void increment() {
    if (count < max!()) {
      count += incrementValue;
      count = count.clamp(min!(), max!());
    }
  }

  void decrement() {
    if (count > min!()) {
      count -= decrementValue;
      count = count.clamp(min!(), max!());
      misses++;
    }
  }

  Map<String, dynamic> toJson() => {
        'count': count,
        'misses': misses,
        'cycleTimes': cycleTimes,
      };

  ScoringElement operator +(ScoringElement other) {
    return ScoringElement(
      count: other.count + count,
      misses: other.misses + misses,
      value: value,
      key: other.key,
      name: name,
      isBool: isBool,
      min: min,
      max: max,
    );
  }
}

abstract class ScoreDivision {
  int? total({bool? showPenalties, bool markDisconnect = true}) =>
      (markDisconnect && robotDisconnected)
          ? null
          : getElements().length == 0
              ? 0
              : getElements()
                  .map((e) => e
                      .scoreValue()) // map scoring elements to an array of their score values
                  .sum()
                  .toInt(); // sum the array

  Dice getDice(); // get the dice object
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
          orElse: () => ScoringElement(),
        );
    if (scoringElement.didAttempt() && !robotDisconnected)
      return scoringElement.scoreValue();
    return null;
  }
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
