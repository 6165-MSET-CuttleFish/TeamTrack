import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:teamtrack/backend.dart';

class Score extends ScoreDivision {
  TeleScore teleScore = TeleScore(Dice.none);
  AutoScore autoScore = AutoScore(Dice.none);
  EndgameScore endgameScore = EndgameScore(Dice.none);
  Penalty penalties = Penalty(Dice.none, false);
  Timestamp timeStamp = Timestamp.now();
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
        ...endgameScore.getElements(),
        ...penalties.getElements()
      ];
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

  Dice getDice() => dice;
  Score.fromJson(Map<String, dynamic> json) {
    dice = getDiceFromString(json['dice']);
    autoScore = AutoScore.fromJson(json['AutoScore'], dice);
    teleScore = TeleScore.fromJson(json['TeleScore'], dice);
    endgameScore = EndgameScore.fromJson(json['EndgameScore'], dice);
    id = json['id'];
    try {
      timeStamp = Timestamp(json['seconds'], json['nanoSeconds']);
    } catch (e) {
      timeStamp = Timestamp.now();
    }
  }
  Map<String, dynamic> toJson() => {
        'AutoScore': autoScore.toJson(),
        'TeleScore': teleScore.toJson(),
        'EndgameScore': endgameScore.toJson(),
        'id': id.toString(),
        'dice': dice.toString(),
        'seconds': timeStamp.seconds,
        'nanoSeconds': timeStamp.nanoseconds,
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

extension scoreList on List<Score> {
  void addScore(Score value) {
    var cop = false;
    for (int i = 0; i < this.length; i++)
      if (this[i].id == value.id) cop = true;
    if (!cop) this.add(value);
  }
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

class TeleScore extends ScoreDivision {
  Dice dice;
  ScoringElement lowGoals = ScoringElement(name: "Low Goals", value: 2);
  ScoringElement midGoals = ScoringElement(name: "Middle Goals", value: 4);
  ScoringElement hiGoals = ScoringElement(name: "High Goals", value: 6);
  List<ScoringElement> getElements() => [hiGoals, midGoals, lowGoals];
  List<double> cycles = [];
  int misses = 0;
  Dice getDice() => dice;
  TeleScore(this.dice);
  TeleScore.fromJson(Map<String, dynamic> map, this.dice) {
    hiGoals =
        ScoringElement(name: 'High Goals', count: map['HighGoals'], value: 6);
    midGoals = ScoringElement(
        name: 'Middle Goals', count: map['MiddleGoals'], value: 4);
    lowGoals =
        ScoringElement(name: 'Low Goals', count: map['LowGoals'], value: 2);
    try {
      misses = map['Misses'];
    } catch (e) {
      misses = 0;
    }
    try {
      cycles = List<double>.from(json.decode(map['Cycles'].toString()));
    } catch (e) {
      cycles = [];
    }
  }
  Map<String, dynamic> toJson() => {
        'HighGoals': hiGoals.count,
        'MiddleGoals': midGoals.count,
        'LowGoals': lowGoals.count,
        'Misses': misses,
        'Cycles': json.encode(cycles),
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
      max: () => 2 - wobbleGoalsInStart.count,
    );
    wobbleGoalsInStart = ScoringElement(
      name: 'Wobbles In Start',
      count: json['WobblesInStart'],
      value: 5,
      max: () => 2 - wobbleGoalsInDrop.count,
    );
    pwrShots = ScoringElement(
      name: 'Power Shots',
      count: json['PowerShots'],
      value: 15,
      max: () => 3,
    );
    ringsOnWobble = ScoringElement(
      name: 'Rings On Wobble',
      count: json['RingsOnWobble'],
      value: 5,
    );
  }
  Map<String, dynamic> toJson() => {
        'WobblesInDrop': wobbleGoalsInDrop.count,
        'WobblesInStart': wobbleGoalsInStart.count,
        'PowerShots': pwrShots.count,
        'RingsOnWobble': ringsOnWobble.count
      };
}

class Penalty extends ScoreDivision {
  ScoringElement majorPenalty =
      ScoringElement(name: 'Major Penalty', value: -30);
  ScoringElement minorPenalty =
      ScoringElement(name: 'Minor Penalty', value: -10);
  Dice dice;
  bool show;
  Penalty(this.dice, this.show);

  @override
  Dice getDice() => dice;

  @override
  List<ScoringElement> getElements() =>
      show ? [majorPenalty, minorPenalty] : [];

  Penalty.fromJson(Map<String, dynamic> json, this.dice)
      : majorPenalty = ScoringElement(
          name: 'Major Penalty',
          value: -30,
          count: json['major'],
        ),
        minorPenalty = ScoringElement(
          name: 'Minor Penalty',
          value: -10,
          count: json['minor'],
        ),
        show = false;
  Map<String, dynamic> toJson() => {
        'major': majorPenalty.count,
        'minor': minorPenalty.count,
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
  late int Function()? min = () => 0;
  late int Function()? max = () => 9999;
  int incrementValue = 1;
  int decrementValue = 1;

  bool asBool() => count == 0 ? false : true;

  void setStuff() {
    if (min == null) min = () => 0;
    if (max == null) max = () => 9999;
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
  int total() => getElements()
      .map((e) => e.scoreValue())
      .reduce((value, element) => value += element);
  Dice getDice();
  List<ScoringElement> getElements();
}
