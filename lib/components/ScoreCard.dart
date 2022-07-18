import 'package:flutter/material.dart';
import 'package:teamtrack/components/DivisionBreakdown.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/components/BarGraph.dart';
import 'package:teamtrack/components/CardView.dart';
import 'package:teamtrack/functions/Statistics.dart';

class ScoreCard extends StatelessWidget {
  ScoreCard({
    Key? key,
    required this.scoreDivisions,
    required this.dice,
    required this.team,
    required this.event,
    this.type,
    required this.removeOutliers,
    this.matches,
    required this.allianceTotal,
    required this.title,
    this.targetScore,
    required this.teamMaxScore,
    required this.maxScore,
  }) : super(key: key);
  final List<ScoreDivision> scoreDivisions;
  final Dice dice;
  final Team team;
  final Event event;
  final bool allianceTotal;
  final OpModeType? type;
  final String title;
  final ScoreDivision? targetScore;
  final bool removeOutliers;
  final List<Match>? matches;
  final Score? teamMaxScore;
  final Score? maxScore;
  @override
  Widget build(BuildContext context) {
    final allianceTotals = matches
        ?.where(
          (match) => match.dice == dice || dice == Dice.none,
        )
        .toList()
        .spots(team, dice, false, type: type)
        .removeOutliers(removeOutliers)
        .map((spot) => spot.y);
    final maxAllianceDeviation = event.teams.values
        .map(
          (e) => event.matches.values
              .toList()
              .spots(e, Dice.none, false, type: type)
              .removeOutliers(removeOutliers)
              .map((spot) => spot.y)
              .standardDeviation(),
        )
        .minValue();
    final maxAllianceMean = event.teams.values
        .map(
          (e) => event.matches.values
              .toList()
              .spots(e, Dice.none, false, type: type)
              .removeOutliers(removeOutliers)
              .map((spot) => spot.y)
              .mean(),
        )
        .maxValue();
    final maxAllianceMedian = event.teams.values
        .map(
          (e) => event.matches.values
              .toList()
              .spots(e, Dice.none, false, type: type)
              .removeOutliers(removeOutliers)
              .map((spot) => spot.y)
              .median(),
        )
        .maxValue();
    final maxAllianceBest = event.teams.values
        .map(
          (e) => event.matches.values
              .toList()
              .spots(e, Dice.none, false, type: type)
              .removeOutliers(removeOutliers)
              .map((spot) => spot.y)
              .maxValue(),
        )
        .maxValue();
    final maxY = [
      event.matches.values
          .toList()
          .maxAllianceScore(type: type, dice: dice)
          .toDouble(),
      team.targetScore?.getScoreDivision(type).total() ?? 0
    ].maxValue();
    final minY = [
      event.teams.minScore(
        dice,
        event.statConfig.removeOutliers,
        type,
      ),
      team.targetScore?.getScoreDivision(type).total() ?? 0,
    ].minValue();
    final stats = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BarGraph(
          val: !allianceTotal
              ? scoreDivisions.meanScore(dice, removeOutliers)
              : allianceTotals?.mean() ?? 0,
          max: !allianceTotal
              ? event.teams.maxMeanScore(dice, removeOutliers, type, null)
              : maxAllianceMean,
          title: 'Mean',
        ),
        BarGraph(
          val: !allianceTotal
              ? scoreDivisions.medianScore(dice, removeOutliers)
              : allianceTotals?.median() ?? 0,
          max: !allianceTotal
              ? event.teams.maxMedianScore(dice, removeOutliers, type, null)
              : maxAllianceMedian,
          title: 'Median',
        ),
        BarGraph(
          val: !allianceTotal
              ? scoreDivisions.maxScore(dice, removeOutliers)
              : allianceTotals?.maxValue() ?? 0,
          max: !allianceTotal
              ? event.teams.maxScore(dice, removeOutliers, type)
              : maxAllianceBest,
          title: 'Best',
        ),
        BarGraph(
          val: !allianceTotal
              ? scoreDivisions.standardDeviationScore(dice, removeOutliers)
              : allianceTotals?.standardDeviation() ?? 0,
          max: !allianceTotal
              ? event.teams.lowestStandardDeviationScore(
                  dice, removeOutliers, type, null)
              : maxAllianceDeviation,
          inverted: true,
          title: 'Deviation',
        ),
      ],
    );
    return CardView(
      type: type,
      title: title,
      isActive: scoreDivisions
              .diceScores(dice)
              .map((score) => score.total())
              .removeOutliers(removeOutliers)
              .length >
          1,
      child: Padding(padding: EdgeInsets.only(left: 5, right: 5), child: stats),
      collapsed: scoreDivisions
                  .diceScores(dice)
                  .map((score) => score.total())
                  .removeOutliers(removeOutliers)
                  .length >
              1
          ? DivisionBreakdown(
              targetScore: targetScore,
              minY: minY,
              maxY: maxY,
              team: team,
              scoreDivisions: scoreDivisions,
              statConfig: event.statConfig,
              dice: dice,
              opModeType: type,
              teamMaxScore: teamMaxScore,
              maxScore: maxScore,
              matches: matches,
            )
          : Text(''),
    );
  }
}
