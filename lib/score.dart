import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:teamtrack/backend.dart';

class Score extends ScoreDivision {
  TeleScore teleScore = TeleScore();
  AutoScore autoScore = AutoScore();
  EndgameScore endgameScore = EndgameScore();
  Penalty penalties = Penalty();
  Timestamp timeStamp = Timestamp.now();
  String id = '';
  late Dice dice;
  Score(this.id, this.dice) {
    teleScore = TeleScore();
    autoScore = AutoScore();
    endgameScore = EndgameScore();
    penalties = Penalty();
    setDice(dice);
  }
  List<ScoringElement> getElements({bool? showPenalties}) => [
        ...teleScore.getElements(),
        ...autoScore.getElements(),
        ...endgameScore.getElements(),
        ...((showPenalties ?? false) ? penalties.getElements() : [])
      ];
  @override
  int total({bool? showPenalties}) => getElements(showPenalties: showPenalties)
      .map((e) => e.scoreValue())
      .reduce((value, element) => value + element)
      .clamp(0, 999999999999999999);
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

  @override
  Dice getDice() => dice;
  void setDice(Dice value) {
    dice = value;
    autoScore.dice = value;
    teleScore.dice = value;
    endgameScore.dice = value;
    penalties.dice = value;
  }

  Score.fromJson(Map<String, dynamic> json, eventType) {
    autoScore = AutoScore.fromJson(json['AutoScore']);
    teleScore = TeleScore.fromJson(json['TeleScore']);
    endgameScore = EndgameScore.fromJson(json['EndgameScore']);
    penalties = Penalty.fromJson(json['Penalty']);
    id = json['id'];
  }
  Map<String, dynamic> toJson() => {
        'AutoScore': autoScore.toJson(),
        'TeleScore': teleScore.toJson(),
        'EndgameScore': endgameScore.toJson(),
        'Penalty': penalties.toJson(),
        'id': id.toString(),
      };
}

Dice getDiceFromString(String statusAsString) {
  for (Dice element in Dice.values) {
    if (element.toString() == statusAsString) {
      return element;
    }
  }
  return Dice.none;
}

EventType getTypeFromString(String statusAsString) {
  for (EventType element in EventType.values)
    if (element.toString() == statusAsString) return element;
  return EventType.remote;
}

extension scoreList on Map<String, Score> {
  void addScore(Score value, Team? team) {
    this[value.id] = value;
  }
}

class AutoScore extends ScoreDivision {
  late Dice dice;
  Set keys = {};
  Map<String, ScoringElement> elements = {
    'HighGoals':
        ScoringElement(name: 'High Goals', value: 12, key: "HighGoals"),
    'MiddleGoals':
        ScoringElement(name: 'Middle Goals', value: 6, key: "MiddleGoals"),
    'LowGoals': ScoringElement(name: 'Low Goals', value: 3, key: "LowGoals"),
    'WobbleGoals': ScoringElement(
      name: 'Wobble Goals',
      value: 15,
      max: () => 2,
      key: "WobbleGoals",
    ),
    'PowerShots': ScoringElement(
      name: 'Power Shots',
      value: 15,
      max: () => 3,
      key: "PowerShots",
    ),
    'Navigated': ScoringElement(
      name: 'Navigated',
      value: 5,
      max: () => 1,
      isBool: true,
      key: "Navigated",
    )
  };
  void setCount(String key, int n) {
    elements[key]?.count = n;
  }

  List<ScoringElement> getElements() => elements.values.toList();
  Dice getDice() => dice;
  AutoScore() {
    (Statics.skeleton['AutoScore'] as Map).keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          min: () => e['min'] ?? 0,
          value: e['value'] ?? 1,
          isBool: e['isBool'] ?? false,
        );
      },
    );
    maxSet();
  }

  void maxSet() {
    (Statics.skeleton['AutoScore'] as Map).keys.forEach(
      (e) {
        if (e['maxIsReference']) {
          int ceil = e['max']['total'];
          elements[e]?.max = () =>
              (ceil - (elements[e['max']['reference']]?.count ?? 0)).toInt();
        }
      },
    );
  }

  AutoScore.fromJson(Map<String, dynamic> map) {
    (Statics.skeleton['AutoScore'] as Map).keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          count: map[e] ?? 0,
          min: () => e['min'] ?? 0,
          value: e['value'] ?? 1,
          isBool: e['isBool'] ?? false,
        );
      },
    );
    maxSet();
  }
  Map<String, dynamic> toJson() =>
      elements.map((key, value) => MapEntry(key, value.count));
}

class TeleScore extends ScoreDivision {
  late Dice dice;
  Map<String, ScoringElement> elements = {
    'HighGoals': ScoringElement(name: 'High Goals', value: 6, key: "HighGoals"),
    'MiddleGoals':
        ScoringElement(name: 'Middle Goals', value: 4, key: "MiddleGoals"),
    'LowGoals': ScoringElement(name: 'Low Goals', value: 2, key: "LowGoals"),
  };
  List<ScoringElement> getElements() => elements.values.toList();
  List<double> cycles = [];
  ScoringElement misses =
      ScoringElement(name: "Misses", value: 1, key: 'Misses');
  Dice getDice() => dice;
  TeleScore() {
    (Statics.skeleton['TeleScore'] as Map).keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          min: () => e['min'] ?? 0,
          value: e['value'] ?? 1,
          isBool: e['isBool'] ?? false,
        );
      },
    );
    maxSet();
  }

  void maxSet() {
    (Statics.skeleton['TeleScore'] as Map).keys.forEach(
      (e) {
        if (e['maxIsReference']) {
          int ceil = e['max']['total'];
          elements[e]?.max = () =>
              (ceil - (elements[e['max']['reference']]?.count ?? 0)).toInt();
        }
      },
    );
  }

  TeleScore.fromJson(Map<String, dynamic> map) {
    (Statics.skeleton['TeleScore'] as Map).keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          count: map[e] ?? 0,
          min: () => e['min'] ?? 0,
          value: e['value'] ?? 1,
          isBool: e['isBool'] ?? false,
        );
      },
    );
    maxSet();
  }
  Map<String, dynamic> toJson() => {
        ...elements.map((key, value) => MapEntry(key, value.count)),
        'Misses': misses.count,
        'CycleTimes': json.encode(cycles),
      };
}

class EndgameScore extends ScoreDivision {
  late Dice dice;
  Map<String, ScoringElement> elements = {};
  List<ScoringElement> getElements() => elements.values.toList();

  Dice getDice() => dice;
  EndgameScore() {
    (Statics.skeleton['EndgameScore'] as Map).keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          min: () => e['min'] ?? 0,
          value: e['value'] ?? 1,
          isBool: e['isBool'] ?? false,
        );
      },
    );
    maxSet();
  }

  void maxSet() {
    (Statics.skeleton['EndgameScore'] as Map).keys.forEach(
      (e) {
        if (e['maxIsReference']) {
          int ceil = e['max']['total'];
          elements[e]?.max = () =>
              (ceil - (elements[e['max']['reference']]?.count ?? 0)).toInt();
        }
      },
    );
  }

  EndgameScore.fromJson(Map<String, dynamic> json) {
    (Statics.skeleton['EndgameScore'] as Map).keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          count: json[e] ?? 0,
          min: () => e['min'] ?? 0,
          value: e['value'] ?? 1,
          isBool: e['isBool'] ?? false,
        );
      },
    );
    maxSet();
  }
  Map<String, dynamic> toJson() =>
      elements.map((key, value) => MapEntry(key, value.count));
}

class Penalty extends ScoreDivision {
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

class Change {
  String title;
  String? description;
  Timestamp startDate;
  Timestamp? endDate;
  String id;
  Change({
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.id,
  });
  Change.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        description = json['description'],
        startDate = Timestamp(json['startSeconds'], json['startNanoSeconds']),
        endDate = Timestamp(json['endSeconds'], json['endNanoSeconds']),
        id = json['id'];
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'startSeconds': startDate.seconds,
        'startNanoSeconds': startDate.nanoseconds,
        'endSeconds': endDate?.seconds,
        'endNanoSeconds': endDate?.nanoseconds,
        'id': id,
      };
}

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
  late int Function()? max = () => 999999999999999999;
  int incrementValue = 1;
  int decrementValue = 1;

  bool asBool() => count == 0 ? false : true;

  void setStuff() {
    if (min == null) min = () => 0;
    if (max == null) max = () => 999999999999999999;
  }

  int scoreValue() => count * value;

  void increment() {
    if (count < max!()) {
      HapticFeedback.mediumImpact();
      count += incrementValue;
      count = count.clamp(min!(), max!());
    }
  }

  void decrement() {
    if (count > min!()) {
      HapticFeedback.mediumImpact();
      count -= decrementValue;
      count = count.clamp(min!(), max!());
    }
  }
}

abstract class ScoreDivision {
  int total({bool? showPenalties}) => getElements()
      .map((e) => e.scoreValue())
      .reduce((value, element) => value + element)
      .clamp(0, 999999999999999999);
  Dice getDice();
  List<ScoringElement> getElements();
}
