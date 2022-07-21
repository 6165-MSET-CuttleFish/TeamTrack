import 'package:flutter/material.dart';
import 'package:teamtrack/components/statistics/BarGraph.dart';
import 'package:teamtrack/components/statistics/PercentChange.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/models/StatConfig.dart';
import 'package:teamtrack/functions/Extensions.dart';

class TeamRow extends StatelessWidget {
  const TeamRow({
    Key? key,
    required this.team,
    required this.event,
    required this.max,
    this.sortMode,
    this.onTap,
    required this.statConfig,
    required this.elementSort,
  }) : super(key: key);
  final Team team;
  final Event event;
  final double max;
  final OpModeType? sortMode;
  final ScoringElement? elementSort;
  final void Function()? onTap;
  final StatConfig statConfig;
  Color wltColor(int i) {
    if (i == 0) {
      return Colors.green;
    } else if (i == 1) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(context) {
    final percentIncrease = statConfig.allianceTotal
        ? event
            .getMatches(team)
            .map((e) => e.alliance(team)?.total())
            .whereType<Score>()
            .percentIncrease(elementSort)
        : team.scores
            .map(
                (key, value) => MapEntry(key, value.getScoreDivision(sortMode)))
            .values
            .percentIncrease(elementSort);
    final elementName = elementSort?.name ?? "";
    final wlt = (team.getWLT(event) ?? '').split('-');
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
      ),
      child: ListTile(
        title: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                team.name,
                style: Theme.of(context).textTheme.bodyText1,
              ),
              Row(
                children: [
                  for (int i = 0; i < wlt.length; i++)
                    Row(
                      children: [
                        Text(
                          wlt[i],
                          style: TextStyle(color: wltColor(i)),
                        ),
                        if (i < wlt.length - 1) Text('-')
                      ],
                    ),
                ],
              )
            ],
          ),
        ),
        leading: Text(
          team.number,
          style: Theme.of(context).textTheme.caption,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (elementName.isNotEmpty)
              SizedBox(
                width: 50,
                child: Text(
                  elementName,
                  style: Theme.of(context).textTheme.caption,
                ),
              ),
            if (percentIncrease != null && elementName.isEmpty)
              PercentChange(
                percentIncrease,
                lessIsBetter: sortMode.getLessIsBetter(),
              ),
            Padding(
              padding: EdgeInsets.all(
                10,
              ),
            ),
            RotatedBox(
              quarterTurns: 1,
              child: BarGraph(
                height: 70,
                width: 30,
                val: statConfig.allianceTotal
                    ? event.matches.values
                        .toList()
                        .spots(
                          team,
                          Dice.none,
                          statConfig.showPenalties,
                          type: sortMode,
                          element: elementSort,
                        )
                        .removeOutliers(statConfig.removeOutliers)
                        .map((spot) => spot.y)
                        .median()
                    : team.scores.medianScore(
                        Dice.none,
                        statConfig.removeOutliers,
                        sortMode,
                        elementSort,
                      ),
                max: max,
                title: 'Median',
              ),
            ),
            Icon(Icons.navigate_next)
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
