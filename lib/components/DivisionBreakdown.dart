import 'package:flutter/material.dart';
import 'package:teamtrack/components/ScoringElementStats.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/StatConfig.dart';

class DivisionBreakdown extends StatefulWidget {
  DivisionBreakdown({
    Key? key,
    required this.hero,
    required this.dice,
    required this.tag,
    this.opModeType,
    required this.event,
    this.teamMaxScore,
    required this.team,
    this.maxScore,
    required this.statConfig,
    required this.matches,
  }) : super(key: key);
  final Widget hero;
  final Event event;
  final Team team;
  final String tag;
  final Score? teamMaxScore;
  final Score? maxScore;
  final OpModeType? opModeType;
  final List<Match> matches;
  final StatConfig statConfig;
  final Dice dice;
  @override
  State<StatefulWidget> createState() => _DivisionBreakdown();
}

class _DivisionBreakdown extends State<DivisionBreakdown> {
  @override
  Widget build(BuildContext context) {
    final allianceTotals = widget.matches
        .where(
          (match) => match.dice == widget.dice || widget.dice == Dice.none,
        )
        .toList()
        .spots(widget.team, widget.dice, false, type: widget.opModeType)
        .removeOutliers(widget.statConfig.removeOutliers)
        .map((spot) => spot.y);
    final maxAllianceDeviation = widget.event.teams.values
        .map(
          (e) => widget.event.matches.values
              .toList()
              .spots(e, Dice.none, false, type: widget.opModeType)
              .removeOutliers(widget.statConfig.removeOutliers)
              .map((spot) => spot.y)
              .standardDeviation(),
        )
        .minValue();
    final maxAllianceMean = widget.event.teams.values
        .map(
          (e) => widget.event.matches.values
              .toList()
              .spots(e, Dice.none, false, type: widget.opModeType)
              .removeOutliers(widget.statConfig.removeOutliers)
              .map((spot) => spot.y)
              .mean(),
        )
        .maxValue();
    final maxAllianceMedian = widget.event.teams.values
        .map(
          (e) => widget.event.matches.values
              .toList()
              .spots(e, Dice.none, false, type: widget.opModeType)
              .removeOutliers(widget.statConfig.removeOutliers)
              .map((spot) => spot.y)
              .median(),
        )
        .maxValue();
    final maxAllianceBest = widget.event.teams.values
        .map(
          (e) => widget.event.matches.values
              .toList()
              .spots(e, Dice.none, false, type: widget.opModeType)
              .removeOutliers(widget.statConfig.removeOutliers)
              .map((spot) => spot.y)
              .maxValue(),
        )
        .maxValue();
    final maxY = [
      widget.event.matches.values
          .toList()
          .maxAllianceScore(type: widget.opModeType, dice: widget.dice)
          .toDouble(),
      widget.team.targetScore?.getScoreDivision(widget.opModeType).total() ?? 0
    ].maxValue();
    final minY = [
      widget.event.teams.minScore(
        widget.dice,
        widget.event.statConfig.removeOutliers,
        widget.opModeType,
      ),
      widget.team.targetScore?.getScoreDivision(widget.opModeType).total() ?? 0,
    ].minValue();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            stretch: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              expandedTitleScale: 1.0,
              background: Hero(
                tag: widget.tag,
                child: widget.hero,
              ),
              title: Text(widget.tag),
            ),
          ),
          SliverFillRemaining(
            child: Column(
              children: widget.teamMaxScore
                      ?.getScoreDivision(widget.opModeType)
                      .getElements()
                      .parse(putNone: false)
                      .map(
                        (element) => ScoringElementStats(
                          element: element,
                          maxElement: widget.maxScore
                                  ?.getScoreDivision(widget.opModeType)
                                  .getElements()
                                  .parse(putNone: false)
                                  .firstWhere(
                                    (e) => e.key == element.key,
                                    orElse: () => ScoringElement(),
                                  ) ??
                              element,
                        ),
                      )
                      .toList() ??
                  [],
            ),
          ),
        ],
      ),
    );
  }
}
