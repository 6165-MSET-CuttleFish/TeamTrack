import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:teamtrack/components/statistics/BarGraph.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/functions/Extensions.dart';

class ScoringElementStats extends StatelessWidget {
  ScoringElementStats({
    Key? key,
    required this.element,
    required this.maxElement,
    required this.elementList,
    this.backgroundColor,
  }) : super(key: key);
  final ScoringElement element;
  final Color? backgroundColor;
  final ScoringElement maxElement;
  final List<ScoreDivision> elementList;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5.0, right: 5.0, bottom: 5.0),
      child: Container(
        color: backgroundColor,
        child: Column(
          children: [
            ExpansionTile(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(element.name),
                  Spacer(),
                  if (!element.isBool)
                    buildIntegerGraph(context)
                  else
                    buildAccuracyGraph(context)
                ],
              ),
              children: [
                SfCartesianChart(
                  tooltipBehavior: TooltipBehavior(enable: true),
                  title: ChartTitle(
                    text: 'Cycle Times and Misses',
                    borderWidth: 2,
                    // Aligns the chart title to left
                    alignment: ChartAlignment.near,
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  series: <ChartSeries>[
                    BoxAndWhiskerSeries<List<double>, int>(
                      xAxisName: "Match",
                      yAxisName: "Cycle Times (seconds)",
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.deepPurple, Colors.green],
                      ),
                      dataSource: elementList
                          .map(
                            (e) => e
                                .getElements()
                                .parse()
                                .firstWhere((f) => f.key == element.key)
                                .cycleTimes,
                          )
                          .toList(),
                      boxPlotMode: BoxPlotMode.exclusive,
                      xValueMapper: (List<double> cycles, _) => _ + 1,
                      yValueMapper: (List<double> cycles, _) =>
                          cycles.length != 0 ? cycles : [0, 0, 0, 0],
                    ),
                    LineSeries<int, int>(
                      xAxisName: "Match",
                      yAxisName: "Total Misses",
                      dashArray: [10],
                      width: 2,
                      color: Colors.red,
                      dataSource: elementList
                          .map(
                            (e) => e
                                .getElements()
                                .parse()
                                .firstWhere((f) => f.key == element.key)
                                .misses,
                          )
                          .toList(),
                      xValueMapper: (int misses, _) => _ + 1,
                      yValueMapper: (int misses, _) => misses,
                    ),
                    LineSeries<int, int>(
                      xAxisName: "Match",
                      yAxisName: "Total Tele-Op Cycles",
                      width: 2,
                      color: OpModeType.tele.getColor(),
                      dataSource: elementList
                          .map(
                            (e) => e
                                .getElements()
                                .parse()
                                .firstWhere((f) => f.key == element.key)
                                .totalAttempted(),
                          )
                          .toList(),
                      xValueMapper: (int misses, _) => _ + 1,
                      yValueMapper: (int misses, _) => misses,
                    ),
                    LineSeries<int, int>(
                      xAxisName: "Match",
                      yAxisName: "Total Endgame Cycles",
                      width: 2,
                      color: OpModeType.endgame.getColor(),
                      dataSource: elementList
                          .map(
                            (e) => e
                                .getElements()
                                .parse()
                                .firstWhere((f) => f.key == element.key)
                                .totalAttempted(), // TODO: add tele/end cycles
                          )
                          .toList(),
                      xValueMapper: (int misses, _) => _ + 1,
                      yValueMapper: (int misses, _) => misses,
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  BarGraph buildIntegerGraph(BuildContext context) => BarGraph(
        val: element.scoreValue().toDouble(),
        max: maxElement.scoreValue().toDouble(),
        width: 20,
        height: 60,
        title: "Median",
        units: ' pts',
        vertical: false,
      );
  // BarGraph buildNestedGraph(BuildContext context) => BarGraph(
  //       val: element.scoreValue().toDouble(),
  //       max: maxElement.scoreValue().toDouble(),
  //       width: 20,
  //       height: 60,
  //       title: "Median",
  //       vertical: false,
  //     );
  BarGraph buildAccuracyGraph(BuildContext context) => BarGraph(
        val: element.count.toDouble(),
        max: maxElement.count.toDouble(),
        width: 20,
        height: 60,
        vertical: false,
        title: "Accuracy",
        units: '%',
      );
}
