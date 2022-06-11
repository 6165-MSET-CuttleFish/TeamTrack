import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/Extensions.dart';

/// This class is used to represent the scoring structure of traditional and remote FTC events.
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

class Score extends ScoreDivision implements Comparable<Score> {
  late TeleScore teleScore;
  late AutoScore autoScore;
  late EndgameScore endgameScore;
  Penalty penalties = Penalty();
  Map<String, bool> defendedTeamNumbers = {};
  List<Team> defendedTeams(Event event) => defendedTeamNumbers.keys
      .map((number) => event.teams[number])
      .whereType<Team>()
      .toList();
  String id = '';
  String gameName;
  late Dice dice;
  bool isAllianceScore;
  Score(this.id, this.dice, this.gameName, {this.isAllianceScore = false}) {
    var ref = isAllianceScore ? absRef['Alliance'] : absRef;
    teleScore = TeleScore(ref['TeleScore']);
    autoScore = AutoScore(ref['AutoScore']);
    endgameScore = EndgameScore(ref['EndgameScore']);
    penalties = Penalty();
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
    return list.reduce((value, element) => value + element).clamp(0, 999);
  }

  ScoreDivision getScoreDivision(OpModeType? type) {
    switch (type) {
      case OpModeType.auto:
        return autoScore;
      case OpModeType.tele:
        return teleScore;
      case OpModeType.endgame:
        return endgameScore;
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
    Map<String, dynamic> ref = isAllianceScore ? absRef['Alliance'] : absRef;
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
    penalties = Penalty.fromJson(map['Penalty']);
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
  Set keys = {};
  Map<String, ScoringElement> elements = Map();
  void setCount(String key, int n) {
    elements[key]?.count = n;
  }

  dynamic ref;
  List<ScoringElement> getElements() => elements.values.toList();
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
    cycleTimes = [];
    misses.count = 0;
  }

  late Dice dice;
  Map<String, ScoringElement> elements = Map();
  List<ScoringElement> getElements() => elements.values.toList();
  List<double> cycleTimes = [];

  int teleCycles([double engameThreshold = 90]) {
    double cycleSum = 0;
    int cycles = 0;
    for (final cycleTime in cycleTimes) {
      cycleSum += cycleTime;
      if (cycleSum < engameThreshold) {
        cycles++;
      } else {
        break;
      }
    }
    return cycles;
  }

  int totalCycles() => cycleTimes.length;

  int endgameCycles([double engameThreshold = 90]) {
    double cycleSum = 0;
    int cycles = 0;
    for (final cycleTime in cycleTimes) {
      cycleSum += cycleTime;
      if (cycleSum > 90) {
        cycles++;
      }
    }
    return cycles;
  }

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
    teleScore.cycleTimes = cycleTimes + other.cycleTimes;
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
  Map<String, dynamic> toJson() => {
        ...elements.map((key, value) => MapEntry(key, value.toJson())),
        'Misses': misses.toJson(),
        'CycleTimes': json.encode(cycleTimes),
      };
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
  Map<String, ScoringElement> elements = Map();
  List<ScoringElement> getElements() => elements.values.toList();
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
  Penalty() {
    majorPenalty =
        ScoringElement(name: 'Major Penalty', value: -30, key: 'major');
    minorPenalty =
        ScoringElement(name: 'Minor Penalty', value: -10, key: 'minor');
  }

  @override
  Dice getDice() => dice;

  @override
  List<ScoringElement> getElements() => [majorPenalty, minorPenalty];

  @override
  int total({bool? showPenalties, bool markDisconnect = false}) => getElements()
      .map((e) => e.scoreValue())
      .reduce((value, element) => value + element);

  Penalty operator +(Penalty other) {
    var penalty = Penalty();
    penalty.dice = dice;
    penalty.majorPenalty = other.majorPenalty + majorPenalty;
    penalty.minorPenalty = other.minorPenalty + minorPenalty;
    return penalty;
  }

  Penalty.fromJson(Map<String, dynamic> json)
      : majorPenalty = ScoringElement(
          name: 'Major Penalty',
          value: -30,
          count: json['major'] is Map ? json['major']['count'] : json['major'],
          misses: json['major'] is Map ? json['major']['misses'] : 0,
          key: 'major',
        ),
        minorPenalty = ScoringElement(
          name: 'Minor Penalty',
          value: -10,
          count: json['minor'] is Map ? json['minor']['count'] : json['minor'],
          misses: json['minor'] is Map ? json['minor']['misses'] : 0,
          key: 'minor',
        );
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
                  .reduce((value, element) => value + element) // sum the array
                  .clamp(
                      0, 999); // clamp the sum to a min of 0 and a max of 999
  Dice getDice(); // get the dice object
  List<ScoringElement> getElements(); // get the scoring elements
  late Timestamp timeStamp; // the time stamp of the Score object
  void reset(); // reset the scoring elements
  bool robotDisconnected = false; // whether the robot disconnected
  int? getScoringElementCount(String? key) {
    if (key == null && !robotDisconnected) return total();
    final scoringElement = this.getElements().parse().firstWhere(
          (e) => e.key == key,
          orElse: () => ScoringElement(),
        );
    if (scoringElement.didAttempt() && !robotDisconnected)
      return scoringElement.scoreValue();
  }
}
