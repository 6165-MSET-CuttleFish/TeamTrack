import 'package:TeamTrack/backend.dart';

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
  int lowGoals = 0;
  int midGoals = 0;
  int hiGoals = 0;
  int total() {
    return lowGoals * 2 + midGoals * 4 + hiGoals * 6;
  }

  TeleScore() {}
  TeleScore.fromJson(Map<String, dynamic> json)
      : hiGoals = json['HighGoals'],
        midGoals = json['MiddleGoals'],
        lowGoals = json['LowGoals'];
  Map<String, dynamic> toJson() => {
        'HighGoals': hiGoals,
        'MiddleGoals': midGoals,
        'LowGoals': lowGoals,
      };
}

class AutoScore {
  int wobbleGoals = 0;
  int lowGoals = 0;
  int midGoals = 0;
  int hiGoals = 0;
  int pwrShots = 0;
  bool navigated = false;
  int total() {
    return wobbleGoals * 15 +
        lowGoals * 3 +
        midGoals * 6 +
        hiGoals * 12 +
        pwrShots * 15 +
        (navigated ? 5 : 0);
  }

  AutoScore() {}
  AutoScore.fromJson(Map<String, dynamic> json)
      : hiGoals = json['HighGoals'],
        midGoals = json['MiddleGoals'],
        lowGoals = json['LowGoals'],
        wobbleGoals = json['WobbleGoals'],
        pwrShots = json['PowerShots'],
        navigated = json['Navigated'];
  Map<String, dynamic> toJson() => {
        'HighGoals': hiGoals,
        'MiddleGoals': midGoals,
        'LowGoals': lowGoals,
        'WobbleGoals': wobbleGoals,
        'PowerShots': pwrShots,
        'Navigated': navigated,
      };
}

class EndgameScore {
  var wobbleGoalsInDrop = 0;
  var wobbleGoalsInStart = 0;
  var pwrShots = 0;
  var ringsOnWobble = 0;
  int total() {
    return wobbleGoalsInDrop * 20 +
        wobbleGoalsInStart * 5 +
        ringsOnWobble * 5 +
        pwrShots * 15;
  }

  EndgameScore() {}
  EndgameScore.fromJson(Map<String, dynamic> json)
      : wobbleGoalsInDrop = json['WobblesInDrop'],
        wobbleGoalsInStart = json['WobblesInStart'],
        pwrShots = json['PowerShots'],
        ringsOnWobble = json['RingsOnWobble'];
  Map<String, dynamic> toJson() => {
        'WobblesInDrop': wobbleGoalsInDrop,
        'WobblesInStart': wobbleGoalsInStart,
        'PowerShots': pwrShots,
        'RingsOnWobble': ringsOnWobble
      };
}
