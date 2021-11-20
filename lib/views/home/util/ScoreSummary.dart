import 'package:flutter/material.dart';
import 'package:teamtrack/components/BarGraph.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';

class ScoreSummary extends StatelessWidget {
  const ScoreSummary({
    Key? key,
    required this.event,
    required this.score,
    this.autoMax = 0,
    this.teleMax = 0,
    this.endMax = 0,
    this.totalMax = 0,
    this.height = 60,
    this.width = 30,
    required this.showPenalties,
  }) : super(key: key);
  final Event event;
  final Score? score;
  final double autoMax;
  final double teleMax;
  final double endMax;
  final double totalMax;
  final double width;
  final double height;
  final bool showPenalties;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        BarGraph(
          height: height,
          width: width,
          val: score
                  ?.total(showPenalties: showPenalties)
                  .toDouble() ??
              0,
          max: totalMax,
          title: 'Total',
        ),
        BarGraph(
          height: height,
          width: width,
          val: score?.autoScore.total().toDouble() ?? 0,
          max: autoMax,
          title: 'Autonomous',
        ),
        BarGraph(
          height: height,
          width: width,
          val: score?.teleScore.total().toDouble() ?? 0,
          max: teleMax,
          title: 'Tele-Op',
        ),
        BarGraph(
          height: height,
          width: width,
          val: score?.endgameScore.total().toDouble() ?? 0,
          max: endMax,
          title: 'Endgame',
        ),
      ],
    );
  }
}
