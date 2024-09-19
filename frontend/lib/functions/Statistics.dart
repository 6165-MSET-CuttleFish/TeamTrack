import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/models/StatConfig.dart';

enum Statistics { MEAN, MEDIAN, BEST, DEVIATION }

extension StatisticsExtension on Statistics {
  String get name {
    switch (this) {
      case Statistics.MEAN:
        return 'Mean';
      case Statistics.MEDIAN:
        return 'Median';
      case Statistics.BEST:
        return 'Best';
      case Statistics.DEVIATION:
        return 'Deviation';
    }
  }

  double Function(Iterable<num?>) getFunction() {
    switch (this) {
      case Statistics.MEAN:
        return mean;
      case Statistics.MEDIAN:
        return median;
      case Statistics.BEST:
        return maxValue;
      case Statistics.DEVIATION:
        return standardDeviation;
    }
  }

  bool getLessIsBetter() => this == Statistics.DEVIATION;
}

extension Ex on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}

double mean(Iterable<num?> arr) => arr.mean();

double median(Iterable<num?> arr) => arr.median();

double standardDeviation(Iterable<num?> arr) => arr.standardDeviation();

double maxValue(Iterable<num?> arr) => arr.maxValue();

extension Arithmetic on Iterable<num?> {
  double getStatistic(double Function(Iterable<num?>) statistic) =>
      statistic(this);

  double mean() {
    final arr = this.whereType<num>();
    if (arr.isEmpty) return 0.0;
    if (arr.length == 1) return arr.first.toDouble();
    return arr.reduce((value, element) =>
            (value.toDouble().abs() + element.toDouble().abs())) /
        arr.length;
  }

  List<FlSpot> spots() {
    List<FlSpot> val = [];
    final arr = whereType<num>().toList();
    for (int i = 0; i < arr.length; i++)
      val.add(FlSpot(i.toDouble(), arr[i].toDouble().abs()));
    return val;
  }

  double standardDeviation() {
    final arr = whereType<num>();
    if (arr.length == 0) return 0;
    double mean = arr.mean();
    final ans =
        sqrt(arr.map((e) => pow(e - mean, 2).toDouble()).sum() / arr.length);
    return ans;
  }

  double median() {
    final arr = this.sorted();
    if (arr.length < 2) return 0;
    int index = arr.length ~/ 2;
    if (arr.length % 2 == 0) return [arr[index - 1], arr[index]].mean();
    return arr[index].abs();
  }

  double accuracy() {
    final arr = whereType<num>();
    if (arr.length == 0) return 0;
    var count = 0;
    for (num i in arr.toList()) {
      if (i > 0) count++;
    }
    return count / arr.length * 100;
  }

  double q1() {
    final arr = this.sorted();
    if (arr.length < 3) return 0;
    if (arr.length % 2 == 0) {
      return arr.sublist(0, (arr.length ~/ 2) - 1).median();
    }
    return arr.sublist(0, arr.length ~/ 2).median();
  }

  double iqr() => q3() - q1();

  double q3() {
    final arr = this.sorted();
    if (arr.length < 3) return 0;
    if (arr.length % 2 == 0) {
      return arr.sublist(arr.length ~/ 2).median();
    }
    return arr.sublist(arr.length ~/ 2 + 1).median();
  }

  double maxValue() {
    final arr = whereType<num>();
    if (arr.isEmpty) return 0;
    return arr.reduce(max).toDouble();
  }

  double minValue() {
    final arr = whereType<num>();
    if (arr.isEmpty) return 0;
    return arr.reduce(min).toDouble();
  }

  double sum() {
    final arr = whereType<num>();
    if (arr.isEmpty) return 0;
    return arr
        .reduce((value, element) => value.toDouble() + element.toDouble())
        .toDouble();
  }

  List<double> sorted() {
    List<double> val = [];
    for (num? i in this) {
      if (i != null) val.add(i.toDouble().abs());
    }
    val.sort((a, b) => a.compareTo(b));
    return val;
  }

  List<double> removeOutliers(bool removeOutliers) {
    if (this.length < 3 || !removeOutliers)
      return this.whereType<num>().map((e) => e.toDouble()).toList();
    return this
        .map((e) => e?.toDouble())
        .whereType<double>()
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
      {OpModeType? type, ScoringElement? element}) {
    List<FlSpot> val = [];
    final arr =
        (dice != Dice.none ? this.where((e) => e.dice == dice) : this).toList();
    int i = 0;
    for (var match in arr) {
      final alliance = match.alliance(team);
      if (alliance != null) {
        final allianceTotal =
            alliance.allianceTotal(showPenalties, type: type, element: element);
        val.add(FlSpot(i.toDouble(), allianceTotal.toDouble().abs()));
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
        final withPens = (alliance?.allianceTotal(true, type: type) ?? 0).abs();
        if (withPens > max) max = withPens;
        final withoutPens =
            (alliance?.allianceTotal(false, type: type) ?? 0).abs();
        if (withoutPens > max) max = withoutPens;
      }
    }
    return max;
  }
}

extension SpotExtensions on List<FlSpot> {
  List<FlSpot> removeOutliers(bool remove) {
    if (!remove) return this;
    return this.map((e) => e.y).toList().removeOutliers(remove).spots();
  }
}

extension ListScore on List<Score> {
  List<FlSpot> spots(
    OpModeType? type, {
    bool? showPenalties,
    bool markDisconnect = false,
  }) {
    final list = this
        .map(
          (e) => e.getScoreDivision(type).total(
                showPenalties: showPenalties,
                markDisconnect: markDisconnect,
              ),
        )
        .whereType<int>()
        .toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble().abs()));
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
        name,
      );
      event.teams[newTeam.number] = newTeam;
      return newTeam;
    }
  }
  Team? findAddModified(String number, String name, Event event) {
    if (this.containsKey(number)) {
      var team = this[number
          .replaceAll(new RegExp(r' -,[^\w\s]+'), '')
          .replaceAll(' ', '')];
      team?.name = event.teams[number]?.name ?? name;
      return team;
    } else {
      var newTeam = Team(
        number.replaceAll(new RegExp(r' -,[^\w\s]+'), '').replaceAll(' ', ''),
        name,
      );
      event.teams[newTeam.number] = newTeam;
      return newTeam;
    }
  }

  List<Team> orderedTeams() {
    final arr = this.values.toList();
    arr.sort((a, b) => int.parse(a.number).compareTo(int.parse(b.number)));
    return arr;
  }

  List<Team> sortedTeams(OpModeType? type, ScoringElement? element,
      StatConfig statConfig, List<Match> matches, Statistics statistic) {
    List<Team> val = [];
    for (Team team in this.values) {
      val.add(team);
    }
    if (statConfig.allianceTotal) {
      val.sort((a, b) {
        final allianceTotalsB = matches
            .toList()
            .spots(b, Dice.none, statConfig.showPenalties,
                type: type, element: element)
            .removeOutliers(statConfig.removeOutliers)
            .map((spot) => spot.y.abs())
            .getStatistic(statistic.getFunction());
        final allianceTotalsA = matches
            .toList()
            .spots(a, Dice.none, statConfig.showPenalties,
                type: type, element: element)
            .removeOutliers(statConfig.removeOutliers)
            .map((spot) => spot.y.abs())
            .getStatistic(statistic.getFunction());
        return allianceTotalsB.compareTo(allianceTotalsA);
      });
    } else {
      val.sort(
        (a, b) => b.scores.values
            .map(
              ((score) => score.getScoreDivision(type)),
            )
            .toList()
            .customStatisticScore(
              Dice.none,
              statConfig.removeOutliers,
              statistic,
              element: element,
            )
            .compareTo(
              a.scores.values
                  .map(
                    ((score) => score.getScoreDivision(type)),
                  )
                  .toList()
                  .customStatisticScore(
                    Dice.none,
                    statConfig.removeOutliers,
                    statistic,
                    element: element,
                  ),
            ),
      );
    }
    return val;
  }

  double maxScore(Dice? dice, bool removeOutliers, OpModeType? type) {
    if (this.length == 0) return 1;
    return this
        .values
        .map((e) => e.scores.maxScore(dice, removeOutliers, type, null))
        .maxValue();
  }

  double minScore(Dice? dice, bool removeOutliers, OpModeType? type) {
    if (this.length == 0) return 0;
    return this
        .values
        .map((e) => e.scores.minScore(dice, removeOutliers, type, null))
        .minValue();
  }

  double maxCustomStatisticScore(Dice? dice, bool removeOutliers,
      Statistics statistic, OpModeType? type, ScoringElement? element) {
    if (this.length == 0) return 1;
    final arr = this.values.map((e) => e.scores
        .customStatisticScore(dice, removeOutliers, statistic, type, element));
    return arr.maxValue();
  }
}

extension ScoresExtension on Map<String, Score> {
  double maxScore(
      Dice? dice, bool removeOutliers, OpModeType? type, String? element) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    final temp = arr
        .map((e) =>
            e.getScoreDivision(type).getScoringElementCount(element)?.abs())
        .removeOutliers(removeOutliers);
    return temp.maxValue();
  }

  double minScore(
      Dice? dice, bool removeOutliers, OpModeType? type, String? element) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) =>
            e.getScoreDivision(type).getScoringElementCount(element)?.abs())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.reduce(min).toDouble();
    return 0;
  }

  double customStatisticScore(Dice? dice, bool removeOutliers,
      Statistics statistc, OpModeType? type, ScoringElement? element) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    var temp = arr
        .map((e) => e
            .getScoreDivision(type)
            .getScoringElementCount(element?.key)
            ?.abs())
        .removeOutliers(removeOutliers);
    if (temp.length != 0) return temp.getStatistic(statistc.getFunction());
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
    final sorted = sortedScores();
    if (sorted.length < 2 || sorted[this.values.length - 2].total() == 0)
      return null;
    return sorted.last
        .total()
        ?.percentIncrease(sorted[this.values.length - 2].total() ?? 0);
  }

  List<Score> sortedScores() {
    final sorted = this.values.toList();
    sorted.sort((a, b) => a.timeStamp.toDate().compareTo(b.timeStamp.toDate()));
    return sorted;
  }
}

extension more on Iterable<ScoreDivision> {
  List<FlSpot> spots() => this.map((e) => e.total()).spots();

  double customStatisticScore(
      Dice dice, bool removeOutliers, Statistics statistics,
      {ScoringElement? element}) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr
        .map((e) => e.getScoringElementCount(element?.key)?.toDouble())
        .removeOutliers(removeOutliers)
        .getStatistic(statistics.getFunction());
  }

  /// Returns the scores which had the [dice] autonomous randomization case
  List<ScoreDivision> diceScores(Dice dice) {
    var returnList =
        (dice != Dice.none ? this.where((e) => e.getDice() == dice) : this)
            .toList();
    returnList
        .sort((a, b) => a.timeStamp.toDate().compareTo(b.timeStamp.toDate()));
    return returnList;
  }

  double? percentIncrease(ScoringElement? element) {
    final sorted = this.toList();
    sorted.sort((a, b) => a.timeStamp.toDate().compareTo(b.timeStamp.toDate()));
    if (sorted.length < 2 ||
        sorted[this.length - 2].getScoringElementCount(element?.key) == 0)
      return null;
    return sorted.last
        .getScoringElementCount(element?.key)
        ?.percentIncrease(sorted[this.length - 2].total() ?? 0);
  }

  double? totalPercentIncrease(String? element) {
    final sorted = this.toList();
    sorted.sort((a, b) => a.timeStamp.toDate().compareTo(b.timeStamp.toDate()));
    if (sorted.length < 2 || sorted[0].getScoringElementCount(element) == 0)
      return null;
    return sorted.last
        .getScoringElementCount(element)
        ?.percentIncrease(sorted[0].total() ?? 0);
  }
}
