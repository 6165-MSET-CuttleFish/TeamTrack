import 'package:flutter/services.dart';
import 'package:teamtrack/backend.dart';

class Score extends ScoreDivision {
  TeleScore teleScore = TeleScore(Dice.none);
  AutoScore autoScore = AutoScore(Dice.none);
  EndgameScore endgameScore = EndgameScore(Dice.none);
  String id = '';
  Dice dice = Dice.none;
  Score(this.id, this.dice) {
    teleScore = TeleScore(dice);
    autoScore = AutoScore(dice);
    endgameScore = EndgameScore(dice);
  }
  List<ScoringElement> getElements() => [
        ...teleScore.getElements(),
        ...autoScore.getElements(),
        ...endgameScore.getElements()
      ];
  Dice getDice() => dice;
  Score.fromJson(Map<String, dynamic> json) {
    dice = getDiceFromString(json['dice']);
    autoScore = AutoScore.fromJson(json['AutoScore'], dice);
    teleScore = TeleScore.fromJson(json['TeleScore'], dice);
    endgameScore = EndgameScore.fromJson(json['EndgameScore'], dice);
    id = json['id'];
  }
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
  return Dice.none;
}

EventType getTypeFromString(String statusAsString) {
  for (EventType element in EventType.values) {
    if (element.toString() == statusAsString) {
      return element;
    }
  }
  return EventType.remote;
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

class TeleScore extends ScoreDivision {
  Dice dice;
  ScoringElement lowGoals = ScoringElement(name: "Low Goals", value: 2);
  ScoringElement midGoals = ScoringElement(name: "Middle Goals", value: 4);
  ScoringElement hiGoals = ScoringElement(name: "High Goals", value: 6);
  List<ScoringElement> getElements() => [hiGoals, midGoals, lowGoals];
  BoxAndWhisker cycles = BoxAndWhisker();
  int? misses = 0;
  Dice getDice() => dice;
  TeleScore(this.dice);
  TeleScore.fromJson(Map<String, dynamic> json, this.dice) {
    hiGoals =
        ScoringElement(name: 'High Goals', count: json['HighGoals'], value: 6);
    midGoals = ScoringElement(
        name: 'Middle Goals', count: json['MiddleGoals'], value: 4);
    lowGoals =
        ScoringElement(name: 'Low Goals', count: json['LowGoals'], value: 2);
    misses = json['Misses'];
    cycles = BoxAndWhisker.fromJson(json['CycleMap']);
  }
  Map<String, dynamic> toJson() => {
        'HighGoals': hiGoals.count,
        'MiddleGoals': midGoals.count,
        'LowGoals': lowGoals.count,
        'Misses': misses,
        'CycleMap': cycles.toJson(),
      };
}

class AutoScore extends ScoreDivision {
  Dice dice;
  ScoringElement wobbleGoals =
      ScoringElement(name: 'Wobble Goals', value: 15, max: () => 2);
  ScoringElement lowGoals = ScoringElement(name: 'Low Goals', value: 3);
  ScoringElement midGoals = ScoringElement(name: 'Middle Goals', value: 6);
  ScoringElement hiGoals = ScoringElement(name: 'High Goals', value: 12);
  ScoringElement pwrShots =
      ScoringElement(name: 'Power Shots', value: 15, max: () => 3);
  ScoringElement navigated =
      ScoringElement(name: 'Navigated', value: 5, max: () => 1, isBool: true);
  List<ScoringElement> getElements() =>
      [hiGoals, midGoals, lowGoals, wobbleGoals, pwrShots, navigated];
  Dice getDice() => dice;
  AutoScore(this.dice);
  AutoScore.fromJson(Map<String, dynamic> json, this.dice) {
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
    navigated = ScoringElement(
        name: 'Navigated', count: json['Navigated'], value: 5, isBool: true);
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

class EndgameScore extends ScoreDivision {
  Dice dice;
  ScoringElement wobbleGoalsInDrop =
      ScoringElement(name: 'Wobbles In Drop', value: 20);
  ScoringElement wobbleGoalsInStart =
      ScoringElement(name: 'Wobbles In Start', value: 5);
  ScoringElement pwrShots =
      ScoringElement(name: 'Power Shots', value: 15, max: () => 3);
  ScoringElement ringsOnWobble =
      ScoringElement(name: 'Rings On Wobble', value: 5);
  List<ScoringElement> getElements() =>
      [pwrShots, wobbleGoalsInDrop, wobbleGoalsInStart, ringsOnWobble];

  Dice getDice() => dice;
  EndgameScore(this.dice) {
    maxSet();
  }
  void maxSet() {
    wobbleGoalsInStart.max = () => 2 - wobbleGoalsInDrop.count;
    wobbleGoalsInDrop.max = () => 2 - wobbleGoalsInStart.count;
  }

  EndgameScore.fromJson(Map<String, dynamic> json, this.dice) {
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
      {this.name = '',
      this.count = 0,
      this.value = 1,
      this.min,
      this.max,
      this.isBool = false}) {
    setStuff();
  }
  String name;
  int count;
  int value;
  bool isBool;
  int Function()? min = () => 0;
  int Function()? max = () => 9999;
  int scoreValue() => count * value;
  int incrementValue = 1;
  int decrementValue = 1;
  bool asBool() => count == 0 ? false : true;
  void setStuff() {
    if (min == null) min = () => 0;
    if (max == null) max = () => 9999;
  }

  void increment() {
    if (count < max!()) {
      HapticFeedback.mediumImpact();
      count += incrementValue;
    }
  }

  void decrement() {
    if (count > min!()) {
      HapticFeedback.mediumImpact();
      count -= decrementValue;
    }
  }
}

abstract class ScoreDivision {
  int total() => getElements()
      .map((e) => e.scoreValue())
      .reduce((value, element) => value += element);
  Dice getDice();
  List<ScoringElement> getElements();
}

class BoxAndWhisker {
  double? median;
  double? q1;
  double? q3;
  double? max;
  double? min;
  List<num?> getArray() => [median, q1, q3, max, min];
  BoxAndWhisker(
      {this.max = 0, this.min = 0, this.median = 0, this.q1 = 0, this.q3 = 0});
  Map<String, dynamic> toJson() =>
      {'median': median, 'q1': q1, 'q3': q3, 'max': max, 'min': min};
  BoxAndWhisker.fromJson(Map<String, dynamic> json)
      : median = json['median'].toDouble(),
        q1 = json['q1'].toDouble(),
        q3 = json['q3'].toDouble(),
        max = json['max'].toDouble(),
        min = json['min'].toDouble();
}
