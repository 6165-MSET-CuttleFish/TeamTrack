import 'package:teamtrack/components/misc/EmptyList.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/models/StatConfig.dart';
import 'package:teamtrack/views/home/team/ExampleTeamRow.dart';
import 'package:teamtrack/views/home/team/TeamRow.dart';
import 'package:teamtrack/views/home/team/TeamView.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'dart:convert';

class TeamList extends StatefulWidget {
  TeamList({
    super.key,
    required this.event,
    required this.sortMode,
    required this.statConfig,
    required this.elementSort,
    required this.statistic,
  });

  final Event event;
  final OpModeType? sortMode;
  final ScoringElement? elementSort;
  final StatConfig statConfig;
  final Statistics statistic;

  @override
  State<TeamList> createState() => _TeamList();
}

class _TeamList extends State<TeamList> {
  late bool isUserTeam;

  void initState() {
    super.initState();
    isUserTeam = widget.event.teams.values.any((team) =>
        widget.event.userTeam?.number != null &&
        team.number == widget.event.userTeam?.number);
    print ("heeeee ${widget.event.userTeam.number}");
  }

  Widget build(BuildContext context) => StreamBuilder<DatabaseEvent>(
        stream: widget.event.getRef()?.onValue,
        builder: (context, eventHandler) {
          if (eventHandler.hasData && !eventHandler.hasError) {
            widget.event.updateLocal(
              json.decode(
                json.encode(
                  eventHandler.data?.snapshot.value,
                ),
              ),
              context,
            );
          }
          if (!eventHandler.hasData && widget.event.shared) {
            return Center(
              child: PlatformProgressIndicator(),
            );
          }
          var max = widget.event.teams.maxCustomStatisticScore(
            Dice.none,
            widget.statConfig.removeOutliers,
            widget.statistic,
            widget.sortMode,
            widget.elementSort,
          );
          final teams = widget.statConfig.sorted
              ? widget.event.teams.sortedTeams(
                  widget.sortMode,
                  widget.elementSort,
                  widget.statConfig,
                  widget.event.matches.values.toList(),
                  widget.statistic,
                )
              : widget.event.teams.orderedTeams();
          if (widget.statConfig.allianceTotal) {
            max = teams
                .map(
                  (e) => widget.event.matches.values
                      .toList()
                      .spots(e, Dice.none, widget.statConfig.showPenalties,
                          type: widget.sortMode)
                      .removeOutliers(widget.statConfig.removeOutliers)
                      .map((spot) => spot.y)
                      .getStatistic(widget.statistic.getFunction()),
                )
                .maxValue();
          }
          if (teams.length == 0) return EmptyList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: ExampleTeamRow(
                  sortMode: widget.sortMode,
                  elementSort: widget.elementSort,
                  statistics: widget.statistic,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    return Slidable(
                      child: TeamRow(
                        team: team,
                        event: widget.event,
                        sortMode: widget.sortMode,
                        statConfig: widget.statConfig,
                        elementSort: widget.elementSort,
                        max: max,
                        statistics: widget.statistic,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamView(
                                team: team,
                                event: widget.event,
                              ),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                      endActionPane: ActionPane(
                        motion: const StretchMotion(),
                        children: [
                          SlidableAction(
                            icon: Icons.delete,
                            backgroundColor: Colors.red,
                            onPressed: (_) {
                              showPlatformDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    PlatformAlert(
                                  title: Text('Delete Team'),
                                  content: Text('Are you sure?'),
                                  actions: [
                                    PlatformDialogAction(
                                      isDefaultAction: true,
                                      child: Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    PlatformDialogAction(
                                      isDefaultAction: false,
                                      isDestructive: true,
                                      child: Text('Confirm'),
                                      onPressed: () {
                                        String? s;
                                        setState(() {
                                          s = widget.event.deleteTeam(team);
                                        });
                                        dataModel.saveEvents();
                                        Navigator.of(context).pop();
                                        if (s != null)
                                          showPlatformDialog(
                                            context: context,
                                            builder: (context) => PlatformAlert(
                                              title: Text('Error'),
                                              content: Text(
                                                  'Team is present in matches'),
                                              actions: [
                                                PlatformDialogAction(
                                                  child: Text('Okay'),
                                                  isDefaultAction: true,
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                )
                                              ],
                                            ),
                                          );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
}

class TeamSearch extends SearchDelegate<String?> {
  TeamSearch({
    required this.teams,
    required this.event,
    this.sortMode,
    required this.statConfig,
    required this.elementSort,
    required this.statistics,
    required this.isUserTeam, // New parameter added
  }) {
    max = event.teams.maxCustomStatisticScore(Dice.none,
        statConfig.removeOutliers, statistics, sortMode, elementSort);
    final teams = event.teams.values;
    if (statConfig.allianceTotal) {
      max = teams
          .map(
            (e) => event.matches.values
                .toList()
                .spots(e, Dice.none, statConfig.showPenalties, type: sortMode)
                .removeOutliers(statConfig.removeOutliers)
                .map((spot) => spot.y)
                .getStatistic(statistics.getFunction()),
          )
          .maxValue();
    }
  }

  late double max;
  OpModeType? sortMode;
  ScoringElement? elementSort;
  List<Team> teams;
  Event event;
  StatConfig statConfig;
  Statistics statistics;
  bool isUserTeam; // New parameter

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isNotEmpty
        ? [
            ...teams.where(
              (q) => q.number.contains(query),
            ),
            ...teams.where(
              (q) => q.name.toLowerCase().contains(query.toLowerCase()),
            ),
          ].toList()
        : teams;

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) => TeamRow(
        statistics: statistics,
        statConfig: statConfig,
        team: suggestionList[index],
        event: event,
        max: max,
        sortMode: sortMode,
        elementSort: elementSort,
        onTap: () async {
          close(context, null);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamView(
                team: suggestionList[index],
                event: event,
              ),
            ),
          );
        },
      ),
    );
  }
}
