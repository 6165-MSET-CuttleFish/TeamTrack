import 'package:TeamTrack/backend.dart';
import 'package:uuid/uuid.dart';

class Score {
  TeleScore teleScore = TeleScore();
  AutoScore autoScore = AutoScore();
  EndgameScore endgameScore = EndgameScore();
  Uuid id;
  Dice dice;
  Score(Uuid id, Dice dice) {
    this.id = id;
    this.dice = dice;
  }
  int total() {
    return teleScore.total() + autoScore.total() + endgameScore.total();
  }

  Map<String, dynamic> toJson() => {
        'AutoScore': autoScore,
        'TeleScore': teleScore,
        'EndgameScore': endgameScore,
      };
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

  Map<String, dynamic> toJson() => {
        'WobblesInDrop': wobbleGoalsInDrop,
        'WobblesInStart': wobbleGoalsInStart,
        'PowerShots': pwrShots,
        'RingsOnWobble': ringsOnWobble
      };
}
