import 'package:flutter/material.dart';
import 'package:teamtrack/components/statistics/BarGraph.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';

class ScoreSummary extends StatelessWidget {
  const ScoreSummary({
    Key? key,
    required this.event,
    this.score,
    this.autoMax = 0,
    this.teleMax = 0,
    this.endMax = 0,
    this.totalMax = 0,
    this.height = 60,
    this.width = 30,
    this.auto = 0,
    this.tele = 0,
    this.end = 0,
    this.total = 0,
    required this.showPenalties,
    this.units = '',
  }) : super(key: key);
  final Event event;
  final Score? score;
  final double auto, tele, end, total, autoMax, teleMax, endMax, totalMax;
  final double width, height;
  final bool showPenalties;
  final String units;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        BarGraph(
          height: height,
          width: width,
          val: score?.total(showPenalties: showPenalties)?.toDouble() ?? total,
          max: totalMax,
          title: 'Total',
          units: units,
        ),
        BarGraph(
          height: height,
          width: width,
          val: score?.autoScore.total()?.toDouble() ?? auto,
          max: autoMax,
          title: 'Autonomous',
          units: units,
        ),
        BarGraph(
          height: height,
          width: width,
          val: score?.teleScore.total()?.toDouble() ?? tele,
          max: teleMax,
          title: 'Tele-Op',
          units: units,
        ),
        BarGraph(
          height: height,
          width: width,
          val: score?.endgameScore.total()?.toDouble() ?? end,
          max: endMax,
          title: 'Endgame',
          units: units,
        ),
      ],
    );
  }
}
