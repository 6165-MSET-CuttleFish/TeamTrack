import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/scores/ScoringElementStats.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/components/statistics/BarGraph.dart';
import 'package:teamtrack/components/misc/CardView.dart';
import 'package:teamtrack/functions/Statistics.dart';

class ScoreCard extends StatelessWidget {
  ScoreCard({
    Key? key,
    required this.scoreDivisions,
    required this.dice,
    required this.team,
    required this.event,
    this.type,
    required this.removeOutliers,
    this.matches,
    required this.allianceTotal,
    required this.title,
    this.targetScore,
    required this.teamMaxScore,
    required this.maxScore,
  }) : super(key: key);
  final List<ScoreDivision> scoreDivisions;
  final Dice dice;
  final Team team;
  final Event event;
  final bool allianceTotal;
  final OpModeType? type;
  final String title;
  final ScoreDivision? targetScore;
  final bool removeOutliers;
  final List<Match>? matches;
  final Score? teamMaxScore;
  final Score? maxScore;
  @override
  Widget build(BuildContext context) {
    final allianceTotals = matches
        ?.where(
          (match) => match.dice == dice || dice == Dice.none,
        )
        .toList()
        .spots(team, dice, false, type: type)
        .removeOutliers(removeOutliers)
        .map((spot) => spot.y);
    final maxAllianceDeviation = event.teams.values
        .map(
          (e) => event.matches.values
              .toList()
              .spots(e, Dice.none, false, type: type)
              .removeOutliers(removeOutliers)
              .map((spot) => spot.y)
              .standardDeviation(),
        )
        .minValue();
    final maxAllianceMean = event.teams.values
        .map(
          (e) => event.matches.values
              .toList()
              .spots(e, Dice.none, false, type: type)
              .removeOutliers(removeOutliers)
              .map((spot) => spot.y)
              .mean(),
        )
        .maxValue();
    final maxAllianceMedian = event.teams.values
        .map(
          (e) => event.matches.values
              .toList()
              .spots(e, Dice.none, false, type: type)
              .removeOutliers(removeOutliers)
              .map((spot) => spot.y)
              .median(),
        )
        .maxValue();
    final maxAllianceBest = event.teams.values
        .map(
          (e) => event.matches.values
              .toList()
              .spots(e, Dice.none, false, type: type)
              .removeOutliers(removeOutliers)
              .map((spot) => spot.y)
              .maxValue(),
        )
        .maxValue();
    final maxY = [
      event.matches.values
          .toList()
          .maxAllianceScore(type: type, dice: dice)
          .toDouble(),
      team.targetScore?.getScoreDivision(type).total() ?? 0
    ].maxValue();
    final minY = [
      event.teams.minScore(
        dice,
        event.statConfig.removeOutliers,
        type,
      ),
      team.targetScore?.getScoreDivision(type).total() ?? 0,
    ].minValue();
    final stats = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BarGraph(
          val: !allianceTotal
              ? scoreDivisions.meanScore(dice, removeOutliers)
              : allianceTotals?.mean() ?? 0,
          max: !allianceTotal
              ? event.teams.maxMeanScore(dice, removeOutliers, type, null)
              : maxAllianceMean,
          title: 'Mean',
          lessIsBetter: type.getLessIsBetter(),
        ),
        BarGraph(
          val: !allianceTotal
              ? scoreDivisions.medianScore(dice, removeOutliers)
              : allianceTotals?.median() ?? 0,
          max: !allianceTotal
              ? event.teams.maxMedianScore(dice, removeOutliers, type, null)
              : maxAllianceMedian,
          title: 'Median',
          lessIsBetter: type.getLessIsBetter(),
        ),
        BarGraph(
          val: !allianceTotal
              ? scoreDivisions.maxScore(dice, removeOutliers)
              : allianceTotals?.maxValue() ?? 0,
          max: !allianceTotal
              ? event.teams.maxScore(dice, removeOutliers, type)
              : maxAllianceBest,
          title: 'Best',
          lessIsBetter: type.getLessIsBetter(),
        ),
        BarGraph(
          val: !allianceTotal
              ? scoreDivisions.standardDeviationScore(dice, removeOutliers)
              : allianceTotals?.standardDeviation() ?? 0,
          max: !allianceTotal
              ? event.teams.lowestStandardDeviationScore(
                  dice, removeOutliers, type, null)
              : maxAllianceDeviation,
          inverted: true,
          title: 'Deviation',
          lessIsBetter: type.getLessIsBetter(),
        ),
      ],
    );
    return CardView(
      type: type,
      title: title,
      isActive: scoreDivisions
              .diceScores(dice)
              .map((score) => score.total())
              .removeOutliers(removeOutliers)
              .length >
          1,
      child: Padding(padding: EdgeInsets.only(left: 5, right: 5), child: stats),
      collapsed: scoreDivisions
                  .diceScores(dice)
                  .map((score) => score.total())
                  .removeOutliers(removeOutliers)
                  .length >
              1
          ? [
              AspectRatio(
                aspectRatio: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(18),
                    ),
                    // color: Color(0xff232d37),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        right: 50.0, left: 12.0, top: 24, bottom: 12),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.transparent,
                            strokeWidth: value % 10 == 0 ? 1 : 0,
                          ),
                          getDrawingVerticalLine: (value) => FlLine(
                            color: Colors.transparent,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              //reservedSize: 22,
                              getTitlesWidget: (value, titleMeta) => Text(
                                (value == value.toInt()
                                        ? (value + 1).toInt()
                                        : "")
                                    .toString(),
                                style: TextStyle(fontSize: 10),
                              ),
                              //interval: 8,
                              showTitles: true,
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              getTitlesWidget: (value, titleMeta) => Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 15,
                                ),
                              ),
                              reservedSize: 35,
                              //interval: 12,
                              showTitles: true,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                              color: const Color(0xff37434d), width: 1),
                        ),
                        minY: minY == maxY ? null : minY,
                        maxY: minY == maxY ? minY + 20 : maxY,
                        lineBarsData: [
                          if (matches != null)
                            LineChartBarData(
                              belowBarData: team.targetScore != null
                                  ? BarAreaData(
                                      show: true,
                                      color: Colors.lightGreenAccent
                                          .withOpacity(0.5),
                                      cutOffY: targetScore?.total()?.toDouble(),
                                      applyCutOffY: true,
                                    )
                                  : null,
                              aboveBarData: team.targetScore != null
                                  ? BarAreaData(
                                      show: true,
                                      color: Colors.redAccent.withOpacity(0.5),
                                      cutOffY: targetScore?.total()?.toDouble(),
                                      applyCutOffY: true,
                                    )
                                  : null,
                              spots: matches
                                  ?.where(
                                    (e) => e.dice == dice || dice == Dice.none,
                                  )
                                  .toList()
                                  .spots(team, dice, false, type: type)
                                  .removeOutliers(removeOutliers),
                              color: Colors.yellow,
                              isCurved: true,
                              preventCurveOverShooting: true,
                              barWidth: 5,
                            ),
                          LineChartBarData(
                            belowBarData: team.targetScore != null
                                ? BarAreaData(
                                    show: true,
                                    color: Colors.lightGreenAccent
                                        .withOpacity(0.5),
                                    cutOffY: targetScore?.total()?.toDouble(),
                                    applyCutOffY: true,
                                  )
                                : null,
                            aboveBarData: team.targetScore != null
                                ? BarAreaData(
                                    show: true,
                                    color: Colors.redAccent.withOpacity(0.5),
                                    cutOffY: targetScore?.total()?.toDouble(),
                                    applyCutOffY: true,
                                  )
                                : null,
                            spots: scoreDivisions
                                .diceScores(dice)
                                .spots()
                                .removeOutliers(removeOutliers),
                            color: type.getColor(),
                            isCurved: true,
                            preventCurveOverShooting: true,
                            barWidth: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (type != null)
                ...teamMaxScore
                        ?.getScoreDivision(type)
                        .getElements()
                        .parse(putNone: false)
                        .map(
                          (element) => ScoringElementStats(
                            elementList: scoreDivisions,
                            element: element,
                            maxElement: maxScore
                                    ?.getScoreDivision(type)
                                    .getElements()
                                    .parse(putNone: false)
                                    .firstWhere(
                                      (e) => e.key == element.key,
                                      orElse: () => ScoringElement(),
                                    ) ??
                                element,
                          ),
                        ) ??
                    []
            ]
          : [],
    );
  }
}
