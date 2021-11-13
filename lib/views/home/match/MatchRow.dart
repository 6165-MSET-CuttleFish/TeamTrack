import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamtrack/components/BarGraph.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'dart:convert';

class MatchRow extends StatelessWidget {
  const MatchRow({
    Key? key,
    required this.event,
    required this.match,
    required this.index,
    this.onTap,
    this.team,
    this.autoMax = 0,
    this.teleMax = 0,
    this.endMax = 0,
    this.totalMax = 0,
    this.allianceTotalMax = 0,
  }) : super(key: key);
  final Event event;
  final Match match;
  final int index;
  final Team? team;
  final double autoMax;
  final double teleMax;
  final double endMax;
  final double totalMax;
  final double allianceTotalMax;
  final void Function()? onTap;
  final double width = 30;
  final double height = 60;

  @override
  Widget build(context) {
    if (event.type == EventType.remote) {}
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: PlatformText(index.toString()),
        title: matchSummary(context),
        trailing: team != null ? null : scoreDisplay(),
        onTap: onTap,
      ),
    );
  }

  Widget matchSummary(BuildContext context) => team != null
      ? Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (event.type != EventType.remote)
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: BarGraph(
                  height: height,
                  width: width,
                  val: team?.scores[match.id]?.total().toDouble() ?? 0,
                  max: totalMax,
                  title: 'Total',
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: BarGraph(
                height: height,
                width: width,
                val: team?.scores[match.id]?.total().toDouble() ?? 0,
                max: totalMax,
                title: event.type == EventType.remote ? 'Total' : 'Sub',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: BarGraph(
                height: height,
                width: width,
                val: team?.scores[match.id]?.autoScore.total().toDouble() ?? 0,
                max: autoMax,
                title: 'Auto',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: BarGraph(
                height: height,
                width: width,
                val: team?.scores[match.id]?.teleScore.total().toDouble() ?? 0,
                max: teleMax,
                title: 'Tele',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: BarGraph(
                height: height,
                width: width,
                val: team?.scores[match.id]?.endgameScore.total().toDouble() ??
                    0,
                max: endMax,
                title: 'End',
              ),
            ),
            Container(
              width: 80,
              child: PlatformText(
                '${json.decode(
                  remoteConfig.getString(
                    event.gameName,
                  ),
                )['Dice']['name']} : ${match.dice.toVal(event.gameName)}',
                style: Theme.of(context).textTheme.caption,
              ),
            ),
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlatformText(
              (match.red?.team1?.name ?? '?') +
                  ' & ' +
                  (match.red?.team2?.name ?? '?'),
              style: Theme.of(context).textTheme.caption,
            ),
            PlatformText(
              'VS',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            PlatformText(
              (match.blue?.team1?.name ?? '?') +
                  ' & ' +
                  (match.blue?.team2?.name ?? '?'),
              style: Theme.of(context).textTheme.caption,
            )
          ],
        );

  Widget scoreDisplay() {
    int redScore = match.redScore(showPenalties: true);
    int blueScore = match.blueScore(showPenalties: true);
    bool redIsGreater = redScore > blueScore;
    bool blueIsGreater = blueScore > redScore;
    bool teamIsRed = match.alliance(team) == match.red;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlatformText(
          match.redScore(showPenalties: true).toString(),
          style: GoogleFonts.gugi(
            fontWeight: redIsGreater ? FontWeight.bold : null,
            color: team == null
                ? (redIsGreater ? CupertinoColors.systemRed : Colors.grey)
                : (teamIsRed ? CupertinoColors.systemYellow : Colors.grey),
          ),
        ),
        PlatformText(" - ", style: GoogleFonts.gugi()),
        PlatformText(
          match.blueScore(showPenalties: true).toString(),
          style: GoogleFonts.gugi(
            fontWeight: blueIsGreater ? FontWeight.bold : null,
            color: team == null
                ? (blueIsGreater ? CupertinoColors.systemBlue : Colors.grey)
                : (!teamIsRed ? CupertinoColors.systemYellow : Colors.grey),
          ),
        ),
      ],
    );
  }
}
