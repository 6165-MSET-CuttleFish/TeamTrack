import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  }) : super(key: key);
  final Event event;
  final Match match;
  final int index;
  final Team? team;
  final void Function()? onTap;

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
        trailing: scoreDisplay(),
        onTap: onTap,
      ),
    );
  }

  Widget matchSummary(BuildContext context) => event.type == EventType.remote
      ? Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlatformText(
                  'Auto : ${match.getAllianceScore(team?.number)?.autoScore.total()}',
                  style: Theme.of(context).textTheme.caption,
                ),
                PlatformText(
                  'Tele : ${match.getAllianceScore(team?.number)?.teleScore.total()}',
                  style: Theme.of(context).textTheme.caption,
                ),
                PlatformText(
                  'Endgame : ${match.getAllianceScore(team?.number)?.endgameScore.total()}',
                  style: Theme.of(context).textTheme.caption,
                )
              ],
            ),
            Spacer(),
            PlatformText(
              '${json.decode(
                remoteConfig.getString(
                  event.gameName,
                ),
              )['Dice']['name']} : ${match.dice.toVal(event.gameName)}',
              style: Theme.of(context).textTheme.caption,
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
    return event.type == EventType.remote
        ? PlatformText(
            match.score(
              showPenalties: true,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlatformText(
                match.redScore(showPenalties: true).toString(),
                style: GoogleFonts.gugi(
                  fontWeight: redIsGreater ? FontWeight.bold : null,
                  color: team == null
                      ? (redIsGreater ? CupertinoColors.systemRed : Colors.grey)
                      : (teamIsRed
                          ? CupertinoColors.systemYellow
                          : Colors.grey),
                ),
              ),
              PlatformText(" - ", style: GoogleFonts.gugi()),
              PlatformText(
                match.blueScore(showPenalties: true).toString(),
                style: GoogleFonts.gugi(
                  fontWeight: blueIsGreater ? FontWeight.bold : null,
                  color: team == null
                      ? (blueIsGreater
                          ? CupertinoColors.systemBlue
                          : Colors.grey)
                      : (!teamIsRed
                          ? CupertinoColors.systemYellow
                          : Colors.grey),
                ),
              ),
            ],
          );
  }
}
