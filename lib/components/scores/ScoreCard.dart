import 'package:flutter/material.dart';
import 'package:teamtrack/components/scores/ScoreTimeline.dart';
import 'package:teamtrack/components/scores/ScoringElementStats.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/components/statistics/BarGraph.dart';
import 'package:teamtrack/components/misc/CardView.dart';
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
    return CardView(
      type: type,
      title: title,
      isActive: scoreDivisions
              .diceScores(dice)
              .map((score) => score.total())
              .removeOutliers(removeOutliers)
              .length >
          1, // only allow card expand if the amount of scores is greater than 1
      child: Padding(
        padding: EdgeInsets.only(left: 25, right:15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: Statistics.values
              .map(
                (statistic) => BarGraph(
                  val: !allianceTotal
                      ? scoreDivisions.customStatisticScore(
                          dice, removeOutliers, statistic)
                      : allianceTotals?.getStatistic(statistic.getFunction()) ??
                          0,
                  max: !allianceTotal
                      ? event.teams.maxCustomStatisticScore(
                          dice, removeOutliers, statistic, type, null)
                      : event.teams.values
                          .map(
                            (e) => event.matches.values
                                .toList()
                                .spots(e, Dice.none, false, type: type)
                                .removeOutliers(removeOutliers)
                                .map((spot) => spot.y)
                                .getStatistic(statistic.getFunction()),
                          )
                          .maxValue(),
                  title: statistic.name,
                  lessIsBetter: (statistic.getLessIsBetter() ||
                          type.getLessIsBetter()) &&
                      !(statistic.getLessIsBetter() && type.getLessIsBetter()),
                ),
              )
              .toList(),
        ),
      ),
      collapsed: scoreDivisions
                  .diceScores(dice)
                  .map((score) => score.total())
                  .removeOutliers(removeOutliers)
                  .length >
              1
          ? [
        Padding(
          padding: EdgeInsets.only(left: 15, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: Statistics.values
                .map(
                  (statistic) => BarGraph(
                val: !allianceTotal
                    ? scoreDivisions.customStatisticScore(
                    dice, removeOutliers, statistic)
                    : allianceTotals?.getStatistic(statistic.getFunction()) ??
                    0,
                max: !allianceTotal
                    ? event.teams.maxCustomStatisticScore(
                    dice, removeOutliers, statistic, type, null)
                    : event.teams.values
                    .map(
                      (e) => event.matches.values
                      .toList()
                      .spots(e, Dice.none, false, type: type)
                      .removeOutliers(removeOutliers)
                      .map((spot) => spot.y)
                      .getStatistic(statistic.getFunction()),
                )
                    .maxValue(),
                title: statistic.name,
                lessIsBetter: (statistic.getLessIsBetter() ||
                    type.getLessIsBetter()) &&
                    !(statistic.getLessIsBetter() && type.getLessIsBetter()),
              ),
            )
                .toList(),
          ),
        ),
              ScoreTimeline(
                minY: minY == maxY ? null : minY,
                maxY: minY == maxY ? minY + 20 : maxY,
                target: targetScore?.total()?.toDouble(),
                individualTotals: scoreDivisions
                    .diceScores(dice)
                    .map((e) => e.total())
                    .removeOutliers(removeOutliers),
                allianceTotals: matches
                    ?.where(
                      (e) => e.dice == dice || dice == Dice.none,
                    )
                    .toList()
                    .spots(team, dice, false, type: type)
                    .map((e) => e.y)
                    .removeOutliers(removeOutliers),
                lineColor: type.getColor(),
                lessIsBetter: type.getLessIsBetter(),
              ),
              if (type != null)
                ...Score('', Dice.none, event.gameName)
                    .getScoreDivision(type)
                    .getElements()
                    .parse(putNone: false)
                    .map(
                      (element) => ScoringElementStats(
                        lessIsBetter: type.getLessIsBetter(),
                        elementList: scoreDivisions
                            .map(
                              (e) => e.getElements().parse().firstWhere(
                                    (f) => f.key == element.key,
                                    orElse: () => ScoringElement.nullScore(),
                                  ),
                            )
                            .toList(),
                        element:
                            element, // TODO: Fix Median calculation for nested elements
                        allElements: event.teams.values
                            .map(
                              (team) => team.scores.values
                                  .map(
                                    (score) => score
                                        .getScoreDivision(type)
                                        .getElements()
                                        .parse()
                                        .firstWhere(
                                          (f) => f.key == element.key,
                                          orElse: () =>
                                              ScoringElement.nullScore(),
                                        ),
                                  )
                                  .toList(),
                            )
                            .toList(),
                        removeOutliers: removeOutliers,
                        target: targetScore
                                ?.getElements()
                                .parse(putNone: false)
                                .firstWhere(
                                  (e) => e.key == element.key,
                                  orElse: () => ScoringElement.nullScore(),
                                ) ??
                            element,
                      ),
                    )
            ]
          : [],
    );
  }
}
