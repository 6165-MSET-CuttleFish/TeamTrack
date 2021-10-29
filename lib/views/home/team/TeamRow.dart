import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamtrack/components/BarGraph.dart';
import 'package:teamtrack/components/PercentIncrease.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/Statistics.dart';

class TeamRow extends StatelessWidget {
  const TeamRow({
    Key? key,
    required this.team,
    required this.event,
    required this.max,
    this.sortMode,
    this.onTap,
  }) : super(key: key);
  final Team team;
  final Event event;
  final double max;
  final OpModeType? sortMode;
  final void Function()? onTap;

  @override
  Widget build(context) {
    final percentIncrease = team.scores.percentIncrease();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
      ),
      child: ListTile(
        title: Text(team.name, style: GoogleFonts.gugi()),
        leading: Text(team.number, style: Theme.of(context).textTheme.caption),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (percentIncrease != null)
              PercentIncrease(percentIncrease: percentIncrease),
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
                val: team.scores.meanScore(Dice.none, true, sortMode),
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
