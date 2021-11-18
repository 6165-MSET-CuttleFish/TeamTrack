import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/BarGraph.dart';
import 'package:teamtrack/components/PercentChange.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/models/StatConfig.dart';

class TeamRow extends StatelessWidget {
  const TeamRow({
    Key? key,
    required this.team,
    required this.event,
    required this.max,
    this.sortMode,
    this.onTap,
    required this.statConfig,
  }) : super(key: key);
  final Team team;
  final Event event;
  final double max;
  final OpModeType? sortMode;
  final void Function()? onTap;
  final StatConfig statConfig;

  @override
  Widget build(context) {
    final percentIncrease = team.scores
        .map((key, value) => MapEntry(key, value.getScoreDivision(sortMode)))
        .values
        .percentIncrease();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
      ),
      child: ListTile(
        title: PlatformText(
          team.name,
          style: Theme.of(context).textTheme.bodyText1,
        ),
        leading: PlatformText(
          team.number,
          style: Theme.of(context).textTheme.caption,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (percentIncrease != null)
              PercentChange(percentIncrease: percentIncrease),
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
                        .spots(team, Dice.none, statConfig.showPenalties,
                            type: sortMode)
                        .removeOutliers(statConfig.removeOutliers)
                        .map((spot) => spot.y)
                        .mean()
                    : team.scores.meanScore(
                        Dice.none, statConfig.removeOutliers, sortMode),
                max: max,
                title: 'Mean',
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
