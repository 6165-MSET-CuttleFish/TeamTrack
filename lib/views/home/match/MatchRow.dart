import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamtrack/models/GameModel.dart';

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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Text(index.toString()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        ]),
        trailing: scoreDisplay(),
        onTap: onTap,
      ),
    );
  }

  Widget scoreDisplay() => Row(
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
