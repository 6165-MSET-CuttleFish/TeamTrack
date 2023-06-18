import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:teamtrack/components/scores/ScoreTimeline.dart';
import 'package:teamtrack/components/statistics/BarGraph.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/functions/Statistics.dart';

class ScoringElementStats extends StatefulWidget {
  ScoringElementStats({
    super.key,
    required this.element,
    required this.elementList,
    required this.allElements,
    this.backgroundColor,
    required this.removeOutliers,
    this.target,
    required this.lessIsBetter,
  });
  final ScoringElement element;
  final Color? backgroundColor;
  final List<ScoringElement> elementList;
  final List<List<ScoringElement>> allElements;
  final ScoringElement? target;
  final bool removeOutliers;
  final lessIsBetter;

  @override
  State<ScoringElementStats> createState() => _ScoringElementStatsState();
}

class _ScoringElementStatsState extends State<ScoringElementStats> {
  bool _showCycles = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 5.0, right: 5.0, bottom: 5.0),
      child: Container(
        color: widget.backgroundColor,
        child: ExpansionTile(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.element.name),
              Spacer(),
              widget.element.isBool ? buildAccuracyGraph(context) : buildIntegerGraph(context),
            ],
          ),
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                _showCycles
                    ? SfCartesianChart(
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
                            dataSource: widget.elementList
                                .map((e) => e.cycleTimes)
                                .toList(),
                            boxPlotMode: BoxPlotMode.exclusive,
                            xValueMapper: (cycles, _) => _ + 1,
                            yValueMapper: (cycles, _) =>
                                cycles.length != 0 ? cycles : [0, 0, 0, 0],
                          ),
                          LineSeries<int, int>(
                            xAxisName: "Match",
                            yAxisName: "Total Misses",
                            //dashArray: [10],
                            width: 2,
                            color: Colors.red,
                            dataSource: widget.elementList
                                .map((e) => e.totalMisses())
                                .toList(),
                            xValueMapper: (misses, _) => _ + 1,
                            yValueMapper: (misses, _) => misses,
                          ),
                          LineSeries<int, int>(
                            xAxisName: "Match",
                            yAxisName: "Total Tele-Op Cycles",
                            width: 2,
                            color: OpModeType.tele.getColor(),
                            dataSource: widget.elementList
                                .map((e) => e.normalCycles())
                                .whereType<int>()
                                .toList(),
                            xValueMapper: (misses, _) => _ + 1,
                            yValueMapper: (misses, _) => misses,
                          ),
                          LineSeries<int, int>(
                            xAxisName: "Match",
                            yAxisName: "Total Endgame Cycles",
                            width: 2,
                            color: OpModeType.endgame.getColor(),
                            dataSource: widget.elementList
                                .map(
                                  (e) => e.endgameCycles(),
                                )
                                .whereType<int>()
                                .toList(),
                            xValueMapper: (misses, _) => _ + 1,
                            yValueMapper: (misses, _) => misses,
                          ),
                        ],
                      )
                    : ScoreTimeline(
                        individualTotals: widget.elementList
                            .map((e) => e.total()?.toDouble())
                            .removeOutliers(widget.removeOutliers)
                            .toList(),
                        lineColor:
                            Theme.of(context).canvasColor.inverseColor(1.0),
                        target: widget.target?.totalCount().toDouble(),
                        lessIsBetter: widget.lessIsBetter,
                      ),
                if (!widget.element.isBool)
                  SizedBox(
                    width: 45,
                    height: 90,
                    child: OutlinedButton(
                      onPressed: () => setState(
                        () => _showCycles = !_showCycles,
                      ),
                      child: Text(
                        'Show Cycle Times',
                        style: Theme.of(context).textTheme.labelLarge,
                        textAlign: TextAlign.center,
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          _showCycles
                              ? Colors.grey.withOpacity(0.3)
                              : Colors.cyan.withOpacity(0.3),
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(20),
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        padding: MaterialStateProperty.all(
                          EdgeInsets.all(0),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  BarGraph buildIntegerGraph(BuildContext context) => BarGraph(
        val: widget.elementList
            .map((e) => e.total())
            .removeOutliers(widget.removeOutliers)
            .median(),
        max: widget.allElements
            .map((list) => list.map((e) => e.total()).median())
            .maxValue(),
        width: 20,
        height: 60,
        title: "Median",
        units: ' pts',
        vertical: false,
      );

  BarGraph buildAccuracyGraph(BuildContext context) => BarGraph(
        val: widget.elementList
            .map((e) => e.total())
            .removeOutliers(widget.removeOutliers)
            .accuracy(),
        max: widget.allElements
            .map((list) => list.map((e) => e.total()).accuracy())
            .maxValue(),
        width: 20,
        height: 60,
        vertical: false,
        title: "Accuracy",
        units: '%',
      );
}
