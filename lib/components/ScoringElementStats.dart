import 'package:flutter/material.dart';
import 'package:teamtrack/components/BarGraph.dart';
import 'package:teamtrack/models/ScoreModel.dart';

class ScoringElementStats extends StatelessWidget {
  ScoringElementStats({
    Key? key,
    required this.element,
    required this.maxElement,
    this.backgroundColor,
  }) : super(key: key);
  final ScoringElement element;
  final Color? backgroundColor;
  final ScoringElement maxElement;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5.0, right: 5.0, bottom: 5.0),
      child: Container(
        color: backgroundColor,
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(element.name),
                Spacer(),
                if (!element.isBool)
                  buildIntegerGraph(context)
                else
                  buildAccuracyGraph(context)
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
