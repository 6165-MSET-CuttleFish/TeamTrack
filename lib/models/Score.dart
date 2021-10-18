import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';

/// This class is used to represent the scoring structure of traditional and remote FTC events.
class Score extends ScoreDivision implements Comparable<Score> {
  TeleScore teleScore = TeleScore({});
  AutoScore autoScore = AutoScore({});
  EndgameScore endgameScore = EndgameScore({});
  Penalty penalties = Penalty();
  String id = '';
  late Dice dice;
  bool isAllianceScore;
  Score(this.id, this.dice, String gameName, {this.isAllianceScore = false}) {
    var ref = isAllianceScore
        ? json.decode(remoteConfig.getValue(gameName).asString())['Alliance']
        : json.decode(remoteConfig.getValue(gameName).asString());
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
  int total({bool? showPenalties}) {
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

  void reset() {
    teleScore.reset();
    autoScore.reset();
    endgameScore.reset();
    penalties.reset();
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

  Score.fromJson(Map<String, dynamic> map, String gameName,
      {this.isAllianceScore = false}) {
    var ref = isAllianceScore
        ? json.decode(remoteConfig.getValue(gameName).asString())['Alliance']
        : json.decode(remoteConfig.getValue(gameName).asString());
    autoScore = map['AutoScore'] != null
        ? AutoScore.fromJson(map['AutoScore'], ref['AutoScore'])
        : AutoScore(ref['AutoScore']);
    teleScore = map['TeleScore'] != null
        ? TeleScore.fromJson(map['TeleScore'], ref['TeleScore'])
        : TeleScore(ref['TeleScore']);
    endgameScore = map['EndgameScore'] != null
        ? EndgameScore.fromJson(map['EndgameScore'], ref['EndgameScore'])
        : EndgameScore(ref['EndgameScore']);
    penalties = Penalty.fromJson(map['Penalty']);
    id = map['id'];
  }
  Map<String, dynamic> toJson() => {
        'AutoScore': autoScore.toJson(),
        'TeleScore': teleScore.toJson(),
        'EndgameScore': endgameScore.toJson(),
        'Penalty': penalties.toJson(),
        'id': id.toString(),
      };

  @override
  int compareTo(Score other) => total().compareTo(other.total());
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

  Map<String, dynamic> ref;
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

  AutoScore operator +(AutoScore other) {
    var autoScore = AutoScore(ref);
    autoScore.elements.keys.forEach(
      (key) {
        autoScore.elements[key] = (elements[key] ?? ScoringElement()) +
            (other.elements[key] ?? ScoringElement());
      },
    );
    return autoScore;
  }

  AutoScore.fromJson(Map<String, dynamic> map, this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          count: map[e] ?? 0,
          min: () => ref[e]['min'] ?? 0,
          value: ref[e]['value'] ?? 1,
          isBool: ref[e]['isBool'] ?? false,
          key: e,
        );
      },
    );
    maxSet();
  }
  Map<String, dynamic> toJson() =>
      elements.map((key, value) => MapEntry(key, value.count));
}

/// This class is used to represent the teleop score structure of traditional and remote FTC events.
/// Remote config capable, so to change the structure of teleop, do so in the Firebase Remote Config console
class TeleScore extends ScoreDivision {
  void reset() {
    for (final element in this.getElements()) {
      element.count = 0;
    }
    teleCycles = 0;
    endgameCycles = 0;
    cycleTimes = [];
    misses.count = 0;
  }

  late Dice dice;
  Map<String, ScoringElement> elements = Map();
  List<ScoringElement> getElements() => elements.values.toList();
  List<double> cycleTimes = [];
  int teleCycles = 0;
  int endgameCycles = 0;
  ScoringElement misses =
      ScoringElement(name: "Misses", value: 1, key: 'Misses');
  Dice getDice() => dice;
  Map<String, dynamic> ref;
  TeleScore(this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          min: () => ref[e]['min'] ?? 0,
          value: ref[e]['value'] ?? 1,
          isBool: ref[e]['isBool'] ?? false,
          key: e,
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
    return teleScore;
  }

  TeleScore.fromJson(Map<String, dynamic> map, this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          count: map[e] ?? 0,
          min: () => ref[e]['min'] ?? 0,
          value: ref[e]['value'] ?? 1,
          isBool: ref[e]['isBool'] ?? false,
          key: e,
        );
      },
    );
    try {
      cycleTimes = List<num>.from(json.decode(map['CycleTimes'].toString()))
          .map((e) => e.toDouble())
          .toList();
    } catch (e) {
      cycleTimes = [];
    }
    teleCycles = map['TeleCycles'] ?? 0;
    endgameCycles = map['EndgameCycles'] ?? 0;
    misses = ScoringElement(
        name: 'Misses', count: map['Misses'] ?? 0, key: 'Misses', value: 1);

    maxSet();
  }
  Map<String, dynamic> toJson() => {
        ...elements.map((key, value) => MapEntry(key, value.count)),
        'Misses': misses.count,
        'CycleTimes': json.encode(cycleTimes),
        'TeleCycles': teleCycles,
        'EndgameCycles': endgameCycles,
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
  Map<String, dynamic> ref;
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
    return endgameScore;
  }

  EndgameScore.fromJson(Map<String, dynamic> json, this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          count: json[e] ?? 0,
          min: () => ref[e]['min'] ?? 0,
          value: ref[e]['value'] ?? 1,
          isBool: ref[e]['isBool'] ?? false,
          key: e,
        );
      },
    );
    maxSet();
  }
  Map<String, dynamic> toJson() =>
      elements.map((key, value) => MapEntry(key, value.count));
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
  int total({bool? showPenalties}) => getElements()
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
          count: json['major'],
          key: 'major',
        ),
        minorPenalty = ScoringElement(
          name: 'Minor Penalty',
          value: -10,
          count: json['minor'],
          key: 'minor',
        );
  Map<String, dynamic> toJson() => {
        'major': majorPenalty.count,
        'minor': minorPenalty.count,
      };
}

/// This class is used to represent a Scoring Element of FTC events.
class ScoringElement {
  ScoringElement(
      {this.name = '',
      this.count = 0,
      this.value = 1,
      this.min,
      this.max,
      this.isBool = false,
      this.key}) {
    setStuff();
  }
  String name;
  String? key;
  int count;
  int value;
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

  int scoreValue() => count * value;

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
    }
  }

  ScoringElement operator +(ScoringElement other) {
    return ScoringElement(
        count: other.count + count,
        value: value,
        key: other.key,
        name: name,
        isBool: isBool,
        min: min,
        max: max);
  }
}

abstract class ScoreDivision {
  int total({bool? showPenalties}) => getElements()
      .map((e) => e.scoreValue())
      .reduce((value, element) => value + element)
      .clamp(0, 999);
  Dice getDice();
  List<ScoringElement> getElements();
  late Timestamp timeStamp;
}
