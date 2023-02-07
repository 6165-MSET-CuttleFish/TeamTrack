import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/functions/Statistics.dart';

class ScoreTimeline extends StatelessWidget {
  const ScoreTimeline({
    super.key,
    this.minY,
    this.maxY,
    required this.individualTotals,
    this.target,
    this.allianceTotals,
    required this.lineColor,
    required this.lessIsBetter,
  });
  final double? minY;
  final double? maxY;
  final bool lessIsBetter;
  final List<double> individualTotals;
  final List<double>? allianceTotals;
  final double? target;
  final Color lineColor;
  @override
  Widget build(BuildContext context) => AspectRatio(
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
                  border: Border.all(color: const Color(0xff37434d), width: 1),
                ),
                minY: minY == maxY ? null : minY,
                maxY: minY == maxY && minY != 0 && minY != null
                    ? (minY ?? 0) + 20
                    : maxY,
                lineBarsData: [
                  if (allianceTotals != null)
                    LineChartBarData(
                      belowBarData: target != null
                          ? BarAreaData(
                              show: true,
                              color: lessIsBetter
                                  ? Colors.redAccent.withOpacity(0.5)
                                  : Colors.lightGreenAccent.withOpacity(0.5),
                              cutOffY: target,
                              applyCutOffY: true,
                            )
                          : null,
                      aboveBarData: target != null
                          ? BarAreaData(
                              show: true,
                              color: lessIsBetter
                                  ? Colors.lightGreenAccent.withOpacity(0.5)
                                  : Colors.redAccent.withOpacity(0.5),
                              cutOffY: target,
                              applyCutOffY: true,
                            )
                          : null,
                      spots: allianceTotals?.spots(),
                      color: Colors.yellow,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      barWidth: 5,
                    ),
                  LineChartBarData(
                    belowBarData: target != null
                        ? BarAreaData(
                            show: true,
                            color: lessIsBetter
                                ? Colors.redAccent.withOpacity(0.5)
                                : Colors.lightGreenAccent.withOpacity(0.5),
                            cutOffY: target,
                            applyCutOffY: true,
                          )
                        : null,
                    aboveBarData: target != null
                        ? BarAreaData(
                            show: true,
                            color: lessIsBetter
                                ? Colors.lightGreenAccent.withOpacity(0.5)
                                : Colors.redAccent.withOpacity(0.5),
                            cutOffY: target,
                            applyCutOffY: true,
                          )
                        : null,
                    spots: individualTotals.spots(),
                    color: lineColor,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    barWidth: 5,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
