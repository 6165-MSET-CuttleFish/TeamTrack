import 'package:flutter/material.dart';
import 'package:teamtrack/components/PercentChange.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';

class ScoreRangeSummary extends StatelessWidget {
  const ScoreRangeSummary({
    Key? key,
    required this.event,
    this.score,
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
  final double auto, tele, end, total;
  final double width, height;
  final bool showPenalties;
  final String units;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        PercentChange(
          total,
          label: "Total",
        ),
        PercentChange(
          auto,
          label: "Autonomous",
        ),
        PercentChange(
          tele,
          label: "Tele-Op",
        ),
        PercentChange(
          end,
          label: "Endgame",
        ),
      ],
    );
  }
}
