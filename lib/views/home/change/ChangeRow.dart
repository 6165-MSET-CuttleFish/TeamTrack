import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/components/ScoreRangeSummary.dart';
import 'package:teamtrack/models/Change.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/Statistics.dart';

class ChangeRow extends StatelessWidget {
  const ChangeRow({
    Key? key,
    required this.change,
    required this.event,
    this.onTap,
    required this.team,
  }) : super(key: key);
  final Change change;
  final Event event;
  final Team team;
  final void Function()? onTap;
  @override
  Widget build(BuildContext context) {
    final scores = team.scores.values.where((score) =>
        score.timeStamp.compareTo(change.startDate) >= 0 &&
        score.timeStamp.compareTo(change.endDate ?? Timestamp.now()) <= 0);
    final autoIncrease =
        scores.map((score) => score.autoScore).totalPercentIncrease() ?? 0;
    final teleIncrease =
        scores.map((score) => score.teleScore).totalPercentIncrease() ?? 0;
    final endgameIncrease =
        scores.map((score) => score.endgameScore).totalPercentIncrease() ?? 0;
    final totalIncrease = scores.totalPercentIncrease() ?? 0;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Column(
          children: [
            PlatformText(change.title),
            PlatformText(
              '${formatDate(
                change.startDate.toDate(),
                [
                  mm,
                  '/',
                  dd,
                  '/',
                  yyyy,
                ],
              )} - ${change.endDate != null ? formatDate(
                  change.endDate!.toDate(),
                  [
                    mm,
                    '/',
                    dd,
                    '/',
                    yyyy,
                  ],
                ) : "Present"}',
              style: Theme.of(context).textTheme.caption,
            ),
            ScoreRangeSummary(
              event: event,
              showPenalties: event.statConfig.showPenalties,
              auto: autoIncrease,
              tele: teleIncrease,
              end: endgameIncrease,
              total: totalIncrease,
            ),
          ],
        ),
      ),
    );
  }
}