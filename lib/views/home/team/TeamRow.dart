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
    super.key,
    required this.team,
    required this.event,
    required this.max,
    this.sortMode,
    this.onTap,
    required this.statConfig,
    required this.elementSort,
    required this.statistics,
  });
  final Team team;
  final Event event;
  final double max;
  final OpModeType? sortMode;
  final ScoringElement? elementSort;
  final Statistics statistics;
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
            .map((e) => e.alliance(team)?.combinedScore())
            .whereType<Score>()
            .percentIncrease(elementSort)
        : team.scores.values
            .map((e) => e.getScoreDivision(sortMode))
            .percentIncrease(elementSort);
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
                style: Theme.of(context).textTheme.bodyLarge,
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
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (percentIncrease != null && percentIncrease.isFinite)
              PercentChange(
                percentIncrease,
                lessIsBetter: sortMode.getLessIsBetter(),
              ),
            Padding(
              padding: EdgeInsets.all(
                10,
              ),
            ),
            BarGraph(
              height: 60,
              width: 15,
              vertical: false,
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
                      .getStatistic(statistics.getFunction())
                  : team.scores.customStatisticScore(
                      Dice.none,
                      statConfig.removeOutliers,
                      statistics,
                      sortMode,
                      elementSort,
                    ),
              max: max,
              title: '',
              lessIsBetter: (statistics.getLessIsBetter() ||
                      sortMode.getLessIsBetter()) &&
                  !(statistics.getLessIsBetter() && sortMode.getLessIsBetter()),
            ),
            Icon(Icons.navigate_next)
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
