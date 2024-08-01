import 'package:flutter/material.dart';
import 'package:teamtrack/components/statistics/PercentChange.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/functions/Statistics.dart';

class ScoreRangeSummary extends StatelessWidget {
  const ScoreRangeSummary({
    super.key,
    required this.scores,
  });
  final List<Score> scores;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: opModeExt
          .getAll()
          .map(
            (type) => PercentChange(
              scores
                      .map((score) => score.getScoreDivision(type))
                      .totalPercentIncrease(null) ??
                  0,
              label: type.getName(),
            ),
          )
          .toList(),
    );
  }
}
