import 'dart:math';

import 'package:teamtrack/backend.dart';

class Score {
  TeleScore teleScore = TeleScore();
  AutoScore autoScore = AutoScore();
  EndgameScore endgameScore = EndgameScore();
  String id;
  Dice dice;
  Score(String id, Dice dice) {
    this.id = id;
    this.dice = dice;
  }
  int total() {
    return teleScore.total() + autoScore.total() + endgameScore.total();
  }

  Score.fromJson(Map<String, dynamic> json)
      : autoScore = AutoScore.fromJson(json['AutoScore']),
        teleScore = TeleScore.fromJson(json['TeleScore']),
        endgameScore = EndgameScore.fromJson(json['EndgameScore']),
        id = json['id'],
        dice = getDiceFromString(json['dice']);
  Map<String, dynamic> toJson() => {
        'AutoScore': autoScore.toJson(),
        'TeleScore': teleScore.toJson(),
        'EndgameScore': endgameScore.toJson(),
        'id': id.toString(),
        'dice': dice.toString()
      };
}

Dice getDiceFromString(String statusAsString) {
  for (Dice element in Dice.values) {
    if (element.toString() == statusAsString) {
      return element;
    }
  }
  return null;
}

EventType getTypeFromString(String statusAsString) {
  for (EventType element in EventType.values) {
    if (element.toString() == statusAsString) {
      return element;
    }
  }
  return null;
}

extension scoreList on List<Score> {
  void addScore(Score value) {
    var cop = false;
    for (int i = 0; i < this.length; i++) {
      if (this[i].id == value.id) {
        cop = true;
      }
    }
    if (!cop) {
      this.add(value);
    }
  }
}

class TeleScore {
  ScoringElement lowGoals = ScoringElement(name: "Low Goals", value: 2);
  ScoringElement midGoals = ScoringElement(name: "Middle Goals", value: 4);
  ScoringElement hiGoals = ScoringElement(name: "High Goals", value: 6);

  int total() {
    return lowGoals.scoreValue() + midGoals.scoreValue() + hiGoals.scoreValue();
  }

  TeleScore();
  TeleScore.fromJson(Map<String, dynamic> json)
      : hiGoals = ScoringElement(
            name: 'High Goals', count: json['HighGoals'], value: 6),
        midGoals = ScoringElement(
            name: 'Middle Goals', count: json['MiddleGoals'], value: 4),
        lowGoals = ScoringElement(
            name: 'Low Goals', count: json['LowGoals'], value: 2);
  Map<String, dynamic> toJson() => {
        'HighGoals': hiGoals.count,
        'MiddleGoals': midGoals.count,
        'LowGoals': lowGoals.count,
      };
}

class AutoScore {
  ScoringElement wobbleGoals =
      ScoringElement(name: 'Wobble Goals', value: 15, max: () => 2);
  ScoringElement lowGoals = ScoringElement(name: 'Low Goals', value: 3);
  ScoringElement midGoals = ScoringElement(name: 'Middle Goals', value: 6);
  ScoringElement hiGoals = ScoringElement(name: 'High Goals', value: 12);
  ScoringElement pwrShots =
      ScoringElement(name: 'Power Shots', value: 15, max: () => 3);
  ScoringElement navigated =
      ScoringElement(name: 'Navigated', value: 5, max: () => 1);
  int total() {
    return wobbleGoals.scoreValue() +
        lowGoals.scoreValue() +
        midGoals.scoreValue() +
        hiGoals.scoreValue() +
        pwrShots.scoreValue() +
        navigated.scoreValue();
  }

  AutoScore();
  AutoScore.fromJson(Map<String, dynamic> json) {
    hiGoals =
        ScoringElement(name: 'High Goals', count: json['HighGoals'], value: 12);
    midGoals = ScoringElement(
        name: 'Middle Goals', count: json['MiddleGoals'], value: 6);
    lowGoals =
        ScoringElement(name: 'Low Goals', count: json['LowGoals'], value: 3);
    wobbleGoals = ScoringElement(
        name: 'Wobble Goals',
        count: json['WobbleGoals'],
        value: 15,
        max: () => 2);
    pwrShots = ScoringElement(
        name: 'Power Shots',
        count: json['PowerShots'],
        value: 15,
        max: () => 3);
    navigated =
        ScoringElement(name: 'Navigated', count: json['Navigated'], value: 5);
  }
  Map<String, dynamic> toJson() => {
        'HighGoals': hiGoals.count,
        'MiddleGoals': midGoals.count,
        'LowGoals': lowGoals.count,
        'WobbleGoals': wobbleGoals.count,
        'PowerShots': pwrShots.count,
        'Navigated': navigated.count,
      };
}

class EndgameScore {
  ScoringElement wobbleGoalsInDrop =
      ScoringElement(name: 'Wobbles In Drop', value: 20);
  ScoringElement wobbleGoalsInStart =
      ScoringElement(name: 'Wobbles In Start', value: 5);
  ScoringElement pwrShots =
      ScoringElement(name: 'Power Shots', value: 15, max: () => 3);
  ScoringElement ringsOnWobble =
      ScoringElement(name: 'Rings On Wobble', value: 5);

  int total() {
    return wobbleGoalsInDrop.scoreValue() +
        wobbleGoalsInStart.scoreValue() +
        ringsOnWobble.scoreValue() +
        pwrShots.scoreValue();
  }

  EndgameScore() {
    maxSet();
  }
  void maxSet() {
    wobbleGoalsInStart.max = () => 2 - wobbleGoalsInDrop.count;
    wobbleGoalsInDrop.max = () => 2 - wobbleGoalsInStart.count;
  }

  EndgameScore.fromJson(Map<String, dynamic> json) {
    wobbleGoalsInDrop = ScoringElement(
        name: 'Wobbles In Drop',
        count: json['WobblesInDrop'],
        value: 20,
        max: () => 2 - wobbleGoalsInStart.count);
    wobbleGoalsInStart = ScoringElement(
        name: 'Wobbles In Start',
        count: json['WobblesInStart'],
        value: 5,
        max: () => 2 - wobbleGoalsInDrop.count);
    pwrShots = ScoringElement(
        name: 'Power Shots',
        count: json['PowerShots'],
        value: 15,
        max: () => 3);
    ringsOnWobble = ScoringElement(
        name: 'Rings On Wobble', count: json['RingsOnWobble'], value: 5);
  }
  Map<String, dynamic> toJson() => {
        'WobblesInDrop': wobbleGoalsInDrop.count,
        'WobblesInStart': wobbleGoalsInStart.count,
        'PowerShots': pwrShots.count,
        'RingsOnWobble': ringsOnWobble.count
      };
}

class ScoringElement {
  ScoringElement(
      {this.name = '', this.count = 0, this.value = 1, this.min, this.max}) {
    setStuff();
  }
  String name;
  int count;
  int value;
  int Function() min = () => 0;
  int Function() max = () => 9999;
  int scoreValue() => count * value;
  bool asBool() => count == 0 ? false : true;
  void setStuff() {
    if (min == null) min = () => 0;
    if (max == null) max = () => 9999;
  }
}
