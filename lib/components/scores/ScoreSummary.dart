import 'package:flutter/material.dart';
import 'package:teamtrack/components/statistics/BarGraph.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/functions/Extensions.dart';

class ScoreSummary extends StatelessWidget {
  const ScoreSummary({
    super.key,
    required this.event,
    required this.score,
    required this.maxes,
    this.height = 60,
    this.width = 30,
    required this.showPenalties,
    this.shortenedNames = false,
    this.titleWidthConstraint,
    this.units = '',
  });
  final Event event;
  final Score? score;
  final bool shortenedNames;
  final double? titleWidthConstraint;
  final Map<OpModeType?, double> maxes;
  final double width, height;
  final bool showPenalties;
  final String units;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      children: [
        for (final opModeType in opModeExt.getAll())
          BarGraph(
            height: height,
            width: width,
            val: score
                    ?.getScoreDivision(opModeType)
                    .total(showPenalties: showPenalties)
                    ?.toDouble()
                    .abs() ??
                0,
            max: maxes[opModeType]?.abs() ?? 0,
            title: opModeType.getName(shortened: shortenedNames),
            units: units,
            titleWidthConstraint: titleWidthConstraint,
            lessIsBetter: opModeType.getLessIsBetter(),
          ),
      ],
    );
  }
}
