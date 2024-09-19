import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamtrack/components/users/UsersRow.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/models/StatConfig.dart';
import 'package:teamtrack/components/scores/ScoreSummary.dart';

class MatchRow extends StatelessWidget {
  const MatchRow({
    super.key,
    required this.event,
    required this.match,
    required this.index,
    this.onTap,
    this.team,
    this.maxes = const {},
    required this.statConfig,
  });
  final Event event;
  final Match match;
  final int index;
  final Team? team;
  final Map<OpModeType?, double> maxes;
  final StatConfig statConfig;
  final void Function()? onTap;
  final double width = 30;
  final double height = 60;

  @override
  Widget build(context) {
    final alliance = match.alliance(team);
    final opposing = match.opposingAlliance(team);
    final allianceTotal = alliance?.allianceTotal(true);
    final opposingTotal = opposing?.allianceTotal(true);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: team == null ? SizedBox(
          width: 35,
            child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:[
              Text(index.toString(),style: Theme.of(context).textTheme.titleLarge, textScaleFactor: .8,)
            ]
        )
        ): null,
        title: team != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.type != EventType.remote && event.type != EventType.analysis)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(index.toString(),
                            style: Theme.of(context).textTheme.titleLarge, textScaleFactor: .8
                          ),
                          Container(
                            child: matchSummary(context),
                            width: 150,
                          ),
                          scoreDisplay(),
                          Icon(Icons.navigate_next)
                        ],
                      ),
                    ),
                  Hero(
                    tag: match.id,
                    child: UsersRow(
                      users: match.activeUsers ?? [],
                      showRole: false,
                      size: 20,
                    ),
                  ),
                  teamSummary(context),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(padding:EdgeInsets.all(0)),
                  matchSummary(context),
                  Hero(
                    tag: match.id,
                    child: UsersRow(
                      users: match.activeUsers ?? [],
                      showRole: false,
                      size: 20,
                    ),
                  ),
                ],
              ),
        trailing: team != null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [scoreDisplay(), Icon(Icons.navigate_next)]),
        tileColor: (event.type != EventType.remote && event.type != EventType.analysis)
            ? _getColor(allianceTotal ?? 0, opposingTotal ?? 0)
            : null,
        onTap: onTap,
      ),
    );
  }

  Color? _getColor(int allianceScore, int opponentScore) {
    if (allianceScore > opponentScore) {
      return Colors.green.withOpacity(
          (((allianceScore - opponentScore) / allianceScore) * 0.7)
              .clamp(0.2, 0.7));
    } else if (allianceScore < opponentScore) {
      return Colors.red.withOpacity(
          (((opponentScore - allianceScore) / opponentScore) * 0.7)
              .clamp(0.2, 0.7));
    }
    return null;
  }

  ScoreSummary teamSummary(BuildContext context) {
    Score? score = statConfig.allianceTotal
        ? match.alliance(team)?.combinedScore()
        : team?.scores[match.id];
    return ScoreSummary(
      event: event,
      score: score,
      maxes: maxes,
      showPenalties: event.statConfig.showPenalties,
      shortenedNames: true,
    );
  }

  Widget matchSummary(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (match.red?.team1?.name ?? '?') +
                ' & ' +
                (match.red?.team2?.name ?? '?'),
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis
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
            style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis
          )
        ],
      );

  Widget scoreDisplay() {
    int redScore = match.redScore(showPenalties: true);
    int blueScore = match.blueScore(showPenalties: true);
    bool redIsGreater = redScore > blueScore;
    bool blueIsGreater = blueScore > redScore;
    bool teamIsRed = match.alliance(team) == match.red;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              match.redScore(showPenalties: true).toString(),
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: redIsGreater ? FontWeight.bold : null,
                color: team == null
                    ? (redIsGreater ? CupertinoColors.systemRed : Colors.grey)
                    : (teamIsRed ? CupertinoColors.activeOrange : Colors.grey),
              ),
            ),
            Text(" - ", style: GoogleFonts.montserrat()),
            Text(
              match.blueScore(showPenalties: true).toString(),
              style: GoogleFonts.montserrat(
                fontWeight: blueIsGreater ? FontWeight.bold : null,
                fontSize: 17,
                color: team == null
                    ? (blueIsGreater ? Colors.blue : Colors.grey)
                    : (!teamIsRed ? CupertinoColors.activeOrange : Colors.grey),
              ),
            ),
          ],
        ),
        if (event.eventKey != null)
          Text(
            match.getRedAPI() != null
                ? match.getRedAPI().toString() +
                    ' - ' +
                    match.getBlueAPI().toString()
                : 'Not on API',
            style: GoogleFonts.montserrat(
              fontSize: match.getRedAPI() == null ? 10.5 : 12,
              color: match.getRedAPI() == null ? Colors.amber : Colors.green,
            ),
          ),
      ],
    );
  }
}
