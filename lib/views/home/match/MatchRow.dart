import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        leading: Text(index.toString()),
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
                Text(
                  'Auto : ${match.getAllianceScore(team?.number)?.autoScore.total()}',
                  style: Theme.of(context).textTheme.caption,
                ),
                Text(
                  'Tele : ${match.getAllianceScore(team?.number)?.teleScore.total()}',
                  style: Theme.of(context).textTheme.caption,
                ),
                Text(
                  'Endgame : ${match.getAllianceScore(team?.number)?.endgameScore.total()}',
                  style: Theme.of(context).textTheme.caption,
                )
              ],
            ),
            Spacer(),
            Text(
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
            Text(
              (match.red?.team1?.name ?? '?') +
                  ' & ' +
                  (match.red?.team2?.name ?? '?'),
              style: Theme.of(context).textTheme.caption,
            ),
            Text(
              'VS',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              (match.blue?.team1?.name ?? '?') +
                  ' & ' +
                  (match.blue?.team2?.name ?? '?'),
              style: Theme.of(context).textTheme.caption,
            )
          ],
        );

  Widget scoreDisplay() => event.type == EventType.remote
      ? Text(
          match.score(
            showPenalties: true,
          ),
        )
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              match.redScore(showPenalties: true).toString(),
              style: GoogleFonts.gugi(
                color: team == null
                    ? (match.redScore(showPenalties: true) >
                            match.blueScore(showPenalties: true)
                        ? CupertinoColors.systemRed
                        : Colors.grey)
                    : (match.alliance(team) == match.red
                        ? CupertinoColors.systemYellow
                        : Colors.grey),
              ),
            ),
            Text(" - ", style: GoogleFonts.gugi()),
            Text(
              match.blueScore(showPenalties: true).toString(),
              style: GoogleFonts.gugi(
                color: team == null
                    ? (match.redScore(showPenalties: true) <
                            match.blueScore(showPenalties: true)
                        ? CupertinoColors.systemBlue
                        : Colors.grey)
                    : (match.alliance(team) == match.blue
                        ? CupertinoColors.systemYellow
                        : Colors.grey),
              ),
            ),
          ],
        );
}
