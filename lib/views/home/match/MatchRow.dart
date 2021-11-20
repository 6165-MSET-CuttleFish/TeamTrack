import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamtrack/components/BarGraph.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/models/StatConfig.dart';
import 'package:teamtrack/components/ScoreSummary.dart';

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
    required this.statConfig,
  }) : super(key: key);
  final Event event;
  final Match match;
  final int index;
  final Team? team;
  final double autoMax;
  final double teleMax;
  final double endMax;
  final double totalMax;
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
        leading: PlatformText(index.toString()),
        title: team != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.type != EventType.remote)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            child: matchSummary(context),
                            width: 200,
                          ),
                          scoreDisplay(),
                        ],
                      ),
                    ),
                  teamSummary(context),
                ],
              )
            : matchSummary(context),
        trailing: team != null ? null : scoreDisplay(),
        tileColor: event.type != EventType.remote
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
  }

  ScoreSummary teamSummary(BuildContext context) {
    Score? score = statConfig.allianceTotal
        ? match.alliance(team)?.total()
        : team?.scores[match.id];
    return ScoreSummary(
      event: event,
      score: score,
      autoMax: autoMax,
      teleMax: teleMax,
      endMax: endMax,
      totalMax: totalMax,
      showPenalties: event.statConfig.showPenalties,
    );
  }

  Widget matchSummary(BuildContext context) => Column(
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
                : (teamIsRed ? CupertinoColors.activeOrange : Colors.grey),
          ),
        ),
        PlatformText(" - ", style: GoogleFonts.gugi()),
        PlatformText(
          match.blueScore(showPenalties: true).toString(),
          style: GoogleFonts.gugi(
            fontWeight: blueIsGreater ? FontWeight.bold : null,
            color: team == null
                ? (blueIsGreater ? Colors.blue : Colors.grey)
                : (!teamIsRed ? CupertinoColors.activeOrange : Colors.grey),
          ),
        ),
      ],
    );
  }
}
