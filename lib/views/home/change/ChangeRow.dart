import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/scores/ScoreRangeSummary.dart';
import 'package:teamtrack/models/Change.dart';
import 'package:teamtrack/models/GameModel.dart';

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
  Widget build(BuildContext context) => Container(
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
              Text(change.title),
              Text(
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
                scores: team.scores.values
                    .where((score) =>
                        score.timeStamp.compareTo(change.startDate) >= 0 &&
                        score.timeStamp
                                .compareTo(change.endDate ?? Timestamp.now()) <=
                            0)
                    .toList(),
              ),
            ],
          ),
        ),
      );
}
