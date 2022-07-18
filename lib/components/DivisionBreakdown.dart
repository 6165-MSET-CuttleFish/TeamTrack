import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/ScoringElementStats.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/StatConfig.dart';

class DivisionBreakdown extends StatelessWidget {
  const DivisionBreakdown({
    Key? key,
    required this.targetScore,
    required this.minY,
    required this.maxY,
    required this.team,
    this.matches,
    required this.scoreDivisions,
    required this.statConfig,
    required this.dice,
    this.opModeType,
    this.teamMaxScore,
    this.maxScore,
  }) : super(key: key);
  final ScoreDivision? targetScore;
  final double minY;
  final double maxY;
  final Team team;
  final List<Match>? matches;
  final List<ScoreDivision> scoreDivisions;
  final StatConfig statConfig;
  final Dice dice;
  final OpModeType? opModeType;
  final Score? teamMaxScore;
  final Score? maxScore;
  @override
  Widget build(BuildContext context) => Column(
        children: [
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
                            (value == value.toInt() ? (value + 1).toInt() : "")
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
                      border:
                          Border.all(color: const Color(0xff37434d), width: 1),
                    ),
                    minY: minY == maxY ? null : minY,
                    maxY: minY == maxY ? minY + 20 : maxY,
                    lineBarsData: [
                      if (matches != null)
                        LineChartBarData(
                          belowBarData: team.targetScore != null
                              ? BarAreaData(
                                  show: true,
                                  color:
                                      Colors.lightGreenAccent.withOpacity(0.5),
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
                              .spots(team, dice, false, type: opModeType)
                              .removeOutliers(statConfig.removeOutliers),
                          color: Color.fromRGBO(255, 166, 0, 1),
                          isCurved: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                        ),
                      LineChartBarData(
                        belowBarData: team.targetScore != null
                            ? BarAreaData(
                                show: true,
                                color: Colors.lightGreenAccent.withOpacity(0.5),
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
                            .removeOutliers(statConfig.removeOutliers),
                        color: opModeType.getColor(),
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
          if (opModeType != null)
            ...teamMaxScore
                    ?.getScoreDivision(opModeType)
                    .getElements()
                    .parse(putNone: false)
                    .map(
                      (element) => ScoringElementStats(
                        elementList: scoreDivisions,
                        element: element,
                        maxElement: maxScore
                                ?.getScoreDivision(opModeType)
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
        ],
      );
}
