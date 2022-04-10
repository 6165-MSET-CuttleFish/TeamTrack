import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/models/StatConfig.dart';

extension Ex on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}

double mean(List<num> arr) {
  double sum = 0;
  for (var i = 0; i < arr.length; i++) {
    sum += arr[i];
  }
  return sum / arr.length;
}

double median(List<num> arr) {
  arr.sort();
  if (arr.length % 2 == 0) {
    return (arr[arr.length ~/ 2 - 1] + arr[arr.length ~/ 2]) / 2;
  } else {
    return arr[arr.length ~/ 2].toDouble();
  }
}

double standardDeviation(List<num> arr) {
  double avg = mean(arr);
  double sum = 0;
  for (var i = 0; i < arr.length; i++) {
    sum += pow(arr[i] - avg, 2);
  }
  return sqrt(sum / arr.length);
}

extension Arithmetic on Iterable<num?> {
  double mean() {
    try {
      if (length == 0) return 0.0;
      if (length == 1) return this.first?.toDouble() ?? 0.0;
      return ((reduce((value, element) =>
                      (value?.toDouble() ?? 0) + (element?.toDouble() ?? 0)) ??
                  0.0) /
              length)
          .toDouble();
    } catch (e) {
      print(e);
      return 0.0;
    }
  }

  List<FlSpot> spots() {
    List<FlSpot> val = [];
    for (int i = 0; i < this.length; i++)
      val.add(FlSpot(i.toDouble(), (this.toList()[i]?.toDouble() ?? 0)));
    return val;
  }

  double standardDeviation() {
    if (this.length == 0) return 0;
    double mean = this.mean();
    return sqrt(this
            .map((e) => pow((e ?? 0) - mean, 2).toDouble())
            .reduce((value, element) => value + element) /
        this.length);
  }

  double median() {
    if (this.length == 0) return 0;
    final arr = this.sorted();
    int index = this.length ~/ 2;
    if (this.length % 2 == 0) return [arr[index - 1], arr[index]].mean();
    return arr[index];
  }

  double q1() {
    if (this.length < 3) return 0;
    final arr = this.sorted();
    if (this.length % 2 == 0) {
      return arr.sublist(0, (this.length ~/ 2) - 1).median();
    }
    return arr.sublist(0, this.length ~/ 2).median();
  }

  double iqr() => q3() - q1();

  double q3() {
    if (this.length < 3) return 0;
    final arr = this.sorted();
    if (this.length % 2 == 0) {
      return arr.sublist(this.length ~/ 2).median();
    }
    return arr.sublist(this.length ~/ 2 + 1).median();
  }

  double maxValue() =>
      this.length != 0 ? this.map((e) => e?.toDouble() ?? 0).reduce(max) : 0;
  double minValue() =>
      this.length != 0 ? this.map((e) => e?.toDouble() ?? 0).reduce(min) : 0;

  List<double> sorted() {
    List<double> val = [];
    for (num? i in this) val.add(i?.toDouble() ?? 0);
    val.sort((a, b) => a.compareTo(b));
    return val;
  }

  List<double> removeOutliers(bool removeOutliers) {
    if (this.length < 3 || !removeOutliers)
      return this.map((e) => e?.toDouble() ?? 0).toList();
    return this
        .map((e) => e?.toDouble() ?? 0)
        .where((e) => removeOutliers ? !e.isOutlier(this) : true)
        .toList();
  }
}

extension moreArithmetic on num {
  bool isOutlier(Iterable<num?> list) =>
      this < list.q1() - 1.5 * list.iqr() ||
      this > list.q3() + 1.5 * list.iqr();
  double percentIncrease(num previous) => (this - previous) / previous * 100;
}

extension MatchExtensions on List<Match> {
  List<FlSpot> spots(Team team, Dice dice, bool showPenalties,
      {OpModeType? type}) {
    List<FlSpot> val = [];
    final arr =
        (dice != Dice.none ? this.where((e) => e.dice == dice) : this).toList();
    int i = 0;
    for (var match in arr) {
      final alliance = match.alliance(team);
      if (alliance != null) {
        final allianceTotal = alliance.allianceTotal(showPenalties, type: type);
        val.add(FlSpot(i.toDouble(), allianceTotal.toDouble()));
        i++;
      }
    }
    return val;
  }

  int maxAllianceScore({OpModeType? type, Dice? dice}) {
    var max = 0;
    final matches = dice == null || dice == Dice.none
        ? this
        : this.where((element) => element.dice == dice);
    for (Match match in matches) {
      for (Alliance? alliance in match.getAlliances()) {
        if ((alliance?.allianceTotal(true, type: type) ?? 0) > max)
          max = alliance?.allianceTotal(true, type: type) ?? 0;
        if ((alliance?.allianceTotal(false, type: type) ?? 0) > max)
          max = alliance?.allianceTotal(false, type: type) ?? 0;
      }
    }
    return max;
  }

  double maxScore(bool showPenalties) => this
      .toList()
      .map((e) => e.getMaxScoreVal(showPenalties: showPenalties))
      .maxValue()
      .toDouble();
}

extension SpotExtensions on List<FlSpot> {
  List<FlSpot> removeOutliers(bool remove) {
    if (!remove) return this;
    return this.map((e) => e.y).toList().removeOutliers(remove).spots();
  }
}

extension ListScore on List<Score> {
  List<FlSpot> spots(OpModeType? type, {bool? showPenalties}) {
    final list = this
        .map(
            (e) => e.getScoreDivision(type).total(showPenalties: showPenalties))
        .toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }
}

extension TeamsExtension on Map<String, Team> {
  Team? findAdd(String number, String name, Event event) {
    if (this.containsKey(number)) {
      var team = this[number
          .replaceAll(new RegExp(r' -,[^\w\s]+'), '')
          .replaceAll(' ', '')];
      team?.name = name;
      return team;
    } else {
      var newTeam = Team(
          number.replaceAll(new RegExp(r' -,[^\w\s]+'), '').replaceAll(' ', ''),
          name);
      event.teams[newTeam.number] = newTeam;
      return newTeam;
    }
  }

  List<Team> orderedTeams() {
    final arr = this.values.toList();
    arr.sort((a, b) => int.parse(a.number).compareTo(int.parse(b.number)));
    return arr;
  }

  List<Team> sortedTeams(
      OpModeType? type, StatConfig statConfig, List<Match> matches) {
    List<Team> val = [];
    for (Team team in this.values) {
      val.add(team);
    }
    if (statConfig.allianceTotal) {
      val.sort((a, b) {
        final allianceTotalsB = matches
            .toList()
            .spots(b, Dice.none, statConfig.showPenalties, type: type)
            .removeOutliers(statConfig.removeOutliers)
            .map((spot) => spot.y)
            .mean();
        final allianceTotalsA = matches
            .toList()
            .spots(a, Dice.none, statConfig.showPenalties, type: type)
            .removeOutliers(statConfig.removeOutliers)
            .map((spot) => spot.y)
            .mean();
        return allianceTotalsB.compareTo(allianceTotalsA);
      });
    } else {
      val.sort(
        (a, b) => b.scores.values
            .map(
              ((score) => score.getScoreDivision(type)),
            )
            .toList()
            .meanScore(Dice.none, statConfig.removeOutliers)
            .compareTo(
              a.scores.values
                  .map(
                    ((score) => score.getScoreDivision(type)),
                  )
                  .toList()
                  .meanScore(Dice.none, statConfig.removeOutliers),
            ),
      );
    }
    return val;
  }

  double maxScore(Dice? dice, bool removeOutliers, OpModeType? type) {
    if (this.length == 0) return 1;
    return this
        .values
        .map((e) => e.scores.maxScore(dice, removeOutliers, type))
        .maxValue();
  }

  double minScore(Dice? dice, bool removeOutliers, OpModeType? type) {
    if (this.length == 0) return 0;
    return this
        .values
        .map((e) => e.scores.minScore(dice, removeOutliers, type))
        .minValue();
  }

  double maxMeanScore(Dice? dice, bool removeOutliers, OpModeType? type) {
    if (this.length == 0) return 1;
    return this
        .values
        .map((e) => e.scores.meanScore(dice ?? Dice.none, removeOutliers, type))
        .maxValue();
  }

  double maxMedianScore(Dice? dice, bool removeOutliers, OpModeType? type) {
    if (this.length == 0) return 1;
    var x = this
        .values
        .map((e) =>
            e.scores.medianScore(dice ?? Dice.none, removeOutliers, type))
        .toList();
    return x.maxValue();
  }

  double lowestStandardDeviationScore(
      Dice? dice, bool removeOutliers, OpModeType? type) {
    if (this.length == 0) return 1;
    final arr = this
        .values
        .map((e) => e.scores.standardDeviationScore(dice, removeOutliers, type))
        .where((element) => element != 0);
    return arr.length != 0 ? arr.reduce(min) : 1;
  }
}

extension ScoreDivExtension on List<ScoreDivision> {
  List<FlSpot> spots() => this.map((e) => e.total()).spots();

  double maxScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr
        .map((e) => e.total().toDouble())
        .removeOutliers(removeOutliers)
        .maxValue()
        .toDouble();
  }

  double medianScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr
        .map((e) => e.total().toDouble())
        .removeOutliers(removeOutliers)
        .median();
  }

  double minScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr
        .map((e) => e.total().toDouble())
        .removeOutliers(removeOutliers)
        .minValue()
        .toDouble();
  }

  double funcScore(Dice dice, bool removeOutliers,
      {required double Function(List<num>) func}) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return func(
      arr
          .map(
            (e) => e.total().toDouble(),
          )
          .removeOutliers(
            removeOutliers,
          ),
    );
  }

  double meanScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr
        .map((e) => e.total().toDouble())
        .removeOutliers(removeOutliers)
        .mean();
  }

  double standardDeviationScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr
        .map((e) => e.total().toDouble())
        .removeOutliers(removeOutliers)
        .standardDeviation();
  }

  double devianceScore(Dice dice, bool removeOutliers) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr
        .map((e) => e.total().toDouble())
        .removeOutliers(removeOutliers)
        .standardDeviation();
  }

  List<ScoreDivision> diceScores(Dice dice) {
    var returnList =
        (dice != Dice.none ? this.where((e) => e.getDice() == dice) : this)
            .toList();
    returnList
        .sort((a, b) => a.timeStamp.toDate().compareTo(b.timeStamp.toDate()));
    return returnList;
  }
}

extension ScoresExtension on Map<String, Score> {
  double maxScore(Dice? dice, bool removeOutliers, OpModeType? type) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) => e.getScoreDivision(type).total())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.reduce(max).toDouble();
    return 0;
  }

  double minScore(Dice? dice, bool removeOutliers, OpModeType? type) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) => e.getScoreDivision(type).total())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.reduce(min).toDouble();
    return 0;
  }

  double meanScore(Dice dice, bool removeOutliers, OpModeType? type) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) => e.getScoreDivision(type).total())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.mean();
    return 0;
  }

  double medianScore(Dice dice, bool removeOutliers, OpModeType? type) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) => e.getScoreDivision(type).total())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.median();
    return 0;
  }

  double standardDeviationScore(
      Dice? dice, bool removeOutliers, OpModeType? type) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) => e.getScoreDivision(type).total())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.standardDeviation();
    return 0;
  }

  List<Score> diceScores(Dice? dice) {
    var returnList = ((dice != Dice.none && dice != null)
            ? this.values.where((e) => e.getDice() == dice)
            : this.values)
        .toList();
    returnList
        .sort((a, b) => a.timeStamp.toDate().compareTo(b.timeStamp.toDate()));
    return returnList;
  }

  double? percentIncrease() {
    final sorted = this.values.toList();
    sorted.sort((a, b) => a.timeStamp.toDate().compareTo(b.timeStamp.toDate()));
    if (sorted.length < 2 || sorted[this.values.length - 2].total() == 0)
      return null;
    return sorted.last
        .total()
        .percentIncrease(sorted[this.values.length - 2].total());
  }
}

extension more on Iterable<ScoreDivision> {
  double? percentIncrease() {
    final sorted = this.toList();
    sorted.sort((a, b) => a.timeStamp.toDate().compareTo(b.timeStamp.toDate()));
    if (sorted.length < 2 || sorted[this.length - 2].total() == 0) return null;
    return sorted.last.total().percentIncrease(sorted[this.length - 2].total());
  }

  double? totalPercentIncrease() {
    final sorted = this.toList();
    sorted.sort((a, b) => a.timeStamp.toDate().compareTo(b.timeStamp.toDate()));
    if (sorted.length < 2 || sorted[0].total() == 0) return null;
    return sorted.last.total().percentIncrease(sorted[0].total());
  }
}
