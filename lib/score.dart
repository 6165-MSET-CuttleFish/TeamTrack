class Score {
  TeleScore teleScore;
  AutoScore autoScore;
  EndgameScore endgameScore;
  final id = 0;
  Score() {}
  int total() {
    return teleScore.total() + autoScore.total() + endgameScore.total();
  }
}

class TeleScore {
  int lowGoals = 0;
  int midGoals = 0;
  int hiGoals = 0;
  int total() {
    return lowGoals * 2 + midGoals * 4 + hiGoals * 6;
  }
}

class AutoScore {
  int wobbleGoals;
  int lowGoals;
  int midGoals;
  int hiGoals;
  int pwrShots;
  bool navigated;
  int total() {
    return wobbleGoals * 15 +
        lowGoals * 3 +
        midGoals * 6 +
        hiGoals * 12 +
        pwrShots * 15 +
        (navigated ? 5 : 0);
  }
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
}
