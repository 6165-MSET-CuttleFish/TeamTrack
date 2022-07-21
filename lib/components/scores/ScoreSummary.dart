import 'package:flutter/material.dart';
import 'package:teamtrack/components/statistics/BarGraph.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/functions/Extensions.dart';

class ScoreSummary extends StatelessWidget {
  const ScoreSummary({
    Key? key,
    required this.event,
    required this.score,
    this.autoMax = 0,
    this.teleMax = 0,
    this.endMax = 0,
    this.totalMax = 0,
    this.penaltyMax = 0,
    this.height = 60,
    this.width = 30,
    required this.showPenalties,
    this.shortenedNames = false,
    this.titleWidthConstraint,
    this.units = '',
  }) : super(key: key);
  final Event event;
  final Score? score;
  final bool shortenedNames;
  final double? titleWidthConstraint;
  final double autoMax, teleMax, endMax, totalMax, penaltyMax;
  final double width, height;
  final bool showPenalties;
  final String units;
  double getMax(OpModeType? opModeType) {
    switch (opModeType) {
      case OpModeType.auto:
        return autoMax;
      case OpModeType.tele:
        return teleMax;
      case OpModeType.endgame:
        return endMax;
      case OpModeType.penalty:
        return penaltyMax;
      default:
        return totalMax;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        for (final opModeType in [null, ...OpModeType.values])
          BarGraph(
            height: height,
            width: width,
            val: score
                    ?.getScoreDivision(opModeType)
                    .total(showPenalties: showPenalties)
                    ?.toDouble() ??
                0,
            max: getMax(opModeType),
            title: opModeType.getName(shortened: shortenedNames),
            units: units,
            titleWidthConstraint: titleWidthConstraint,
          ),
      ],
    );
  }
}
