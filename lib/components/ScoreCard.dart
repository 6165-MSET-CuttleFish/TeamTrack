import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/components/BarGraph.dart';
import 'package:teamtrack/components/CardView.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/functions/Extensions.dart';

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
  }) : super(key: key) {
    switch (type) {
      case OpModeType.auto:
        targetScore = team.targetScore?.autoScore;
        break;
      case OpModeType.tele:
        targetScore = team.targetScore?.teleScore;
        break;
      case OpModeType.endgame:
        targetScore = team.targetScore?.endgameScore;
        break;
      default:
        targetScore = team.targetScore;
        break;
    }
  }
  final List<ScoreDivision> scoreDivisions;
  final Dice dice;
  final Team team;
  final Event event;
  final bool allianceTotal;
  final OpModeType? type;
  ScoreDivision? targetScore;
  final bool removeOutliers;
  final List<Match>? matches;
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
    return CardView(
      isActive: scoreDivisions.diceScores(dice).length >= 1,
      child: Padding(
        padding: EdgeInsets.only(left: 5, right: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BarGraph(
              val: !allianceTotal
                  ? scoreDivisions.meanScore(dice, removeOutliers)
                  : allianceTotals?.mean() ?? 0,
              max: !allianceTotal
                  ? event.teams.maxMeanScore(dice, removeOutliers, type)
                  : maxAllianceMean,
              title: 'Mean',
            ),
            BarGraph(
              val: !allianceTotal
                  ? scoreDivisions.medianScore(dice, removeOutliers)
                  : allianceTotals?.median() ?? 0,
              max: !allianceTotal
                  ? event.teams.maxMedianScore(dice, removeOutliers, type)
                  : maxAllianceMedian,
              title: 'Median',
            ),
            BarGraph(
              val: !allianceTotal
                  ? scoreDivisions.maxScore(dice, removeOutliers)
                  : allianceTotals?.maxValue() ?? 0,
              max: !allianceTotal
                  ? event.teams.maxScore(dice, removeOutliers, type)
                  : maxAllianceBest,
              title: 'Best',
            ),
            BarGraph(
              val: !allianceTotal
                  ? scoreDivisions.standardDeviationScore(dice, removeOutliers)
                  : allianceTotals?.standardDeviation() ?? 0,
              max: !allianceTotal
                  ? event.teams
                      .lowestStandardDeviationScore(dice, removeOutliers, type)
                  : maxAllianceDeviation,
              inverted: true,
              title: 'Deviation',
            ),
          ],
        ),
      ),
      collapsed: scoreDivisions
                  .diceScores(dice)
                  .map((score) => score.total())
                  .removeOutliers(removeOutliers)
                  .length >=
              1
          ? AspectRatio(
              aspectRatio: 2,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(18),
                  ),
                  color: Color(0xff232d37),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      right: 50.0, left: 12.0, top: 24, bottom: 12),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: value % 10 == 0
                                ? Color(0xff37434d)
                                : Colors.transparent,
                            strokeWidth: value % 10 == 0 ? 1 : 0,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: const Color(0xff37434d),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTextStyles: (value, size) => const TextStyle(
                              color: Color(0xff68737d), fontSize: 10),
                          getTitles: (value) {
                            return (value + 1).toInt().toString();
                          },
                          margin: 8,
                        ),
                        leftTitles: SideTitles(
                          showTitles: true,
                          getTextStyles: (value, size) => const TextStyle(
                            color: Color(0xff67727d),
                            fontSize: 15,
                          ),
                          getTitles: (value) {
                            if (value % 30 == 0) {
                              return value.toInt().toString();
                            }
                            return '';
                          },
                          reservedSize: 28,
                          margin: 12,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                            color: const Color(0xff37434d), width: 1),
                      ),
                      minY: [
                        scoreDivisions.minScore(dice, removeOutliers),
                        targetScore?.total().toDouble() ?? 0.0
                      ].reduce(min),
                      maxY: [
                        event.matches.values
                            .toList()
                            .maxAllianceScore(type: type, dice: dice)
                            .toDouble(),
                        targetScore?.total().toDouble() ?? 0.0
                      ].reduce(max),
                      lineBarsData: [
                        if (matches != null)
                          LineChartBarData(
                            belowBarData: team.targetScore != null
                                ? BarAreaData(
                                    show: true,
                                    colors: [
                                      Colors.lightGreenAccent.withOpacity(0.5)
                                    ],
                                    cutOffY: targetScore?.total().toDouble(),
                                    applyCutOffY: true,
                                  )
                                : null,
                            aboveBarData: team.targetScore != null
                                ? BarAreaData(
                                    show: true,
                                    colors: [Colors.redAccent.withOpacity(0.5)],
                                    cutOffY: targetScore?.total().toDouble(),
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
                            colors: [
                              Color.fromRGBO(255, 166, 0, 1),
                            ],
                            isCurved: true,
                            preventCurveOverShooting: true,
                            barWidth: 5,
                          ),
                        LineChartBarData(
                          belowBarData: team.targetScore != null
                              ? BarAreaData(
                                  show: true,
                                  colors: [
                                    Colors.lightGreenAccent.withOpacity(0.5)
                                  ],
                                  cutOffY: targetScore?.total().toDouble(),
                                  applyCutOffY: true,
                                )
                              : null,
                          aboveBarData: team.targetScore != null
                              ? BarAreaData(
                                  show: true,
                                  colors: [Colors.redAccent.withOpacity(0.5)],
                                  cutOffY: targetScore?.total().toDouble(),
                                  applyCutOffY: true,
                                )
                              : null,
                          spots: scoreDivisions
                              .diceScores(dice)
                              .spots()
                              .removeOutliers(removeOutliers),
                          colors: [type.getColor()],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : PlatformText(''),
    );
  }
}
