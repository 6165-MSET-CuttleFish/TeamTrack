import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/rendering.dart';
import 'package:teamtrack/components/misc/EmptyList.dart';
import 'package:teamtrack/functions/Functions.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/StatConfig.dart';
import 'package:teamtrack/views/home/match/ExampleMatchRow.dart';
import 'package:teamtrack/views/home/match/MatchConfig.dart';
import 'package:teamtrack/views/home/match/MatchRow.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'dart:convert';

import 'package:teamtrack/components/statistics/CheckList.dart';

class MatchList extends StatefulWidget {
  MatchList({
    super.key,
    required this.event,
    this.team,
    required this.ascending,
  });
  final Event event;
  final Team? team;
  final bool ascending;
  @override
  State<MatchList> createState() => _MatchList();
}

class _MatchList extends State<MatchList> {
  var scrollController = ScrollController();
  var _fabIsVisible = true;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(
      () => setState(
        () => _fabIsVisible = scrollController.position.userScrollDirection ==
            ScrollDirection.forward,
      ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<DatabaseEvent>(
        stream: widget.event.getRef()?.onValue,
        builder: (context, eventHandler) {
          if (eventHandler.hasData && !eventHandler.hasError) {
            widget.event.updateLocal(
              json.decode(
                json.encode(eventHandler.data?.snapshot.value),
              ),
              context,
            );
          }
          if (!eventHandler.hasData && widget.event.shared) {
            return Center(
              child: PlatformProgressIndicator(),
            );
          }
          if (widget.team == null) {
            return _matches();
          }
          return Scaffold(
            appBar: AppBar(
              title: Text('Matches'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              actions: [
                IconButton(
                  icon: Icon(Icons.settings),
                  tooltip: 'Configure',
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => CheckList(
                      state: this,
                      event: widget.event,
                      statConfig: widget.event.statConfig,
                      showSorting: false,
                    ),
                  ),
                ),
                if (widget.event.type != EventType.remote&&widget.event.type != EventType.analysis)
                  IconButton(
                    icon: Icon(
                      Icons.search,
                    ),
                    onPressed: () {
                      showSearch(
                        context: context,
                        delegate: MatchSearch(
                          statConfig: widget.event.statConfig,
                          matches: widget.event
                              .getSortedMatches(widget.ascending)
                              .where((e) =>
                                  e.alliance(
                                    widget.event.teams[widget.team?.number],
                                  ) !=
                                  null)
                              .toList(),
                          ascending: widget.ascending,
                          event: widget.event,
                        ),
                      );
                    },
                  ),
              ],
            ),
            body: _matches(scrollController),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton:
                _fabIsVisible && widget.event.role != Role.viewer
                    ? FloatingActionButton(
                        tooltip: 'Add Match',
                        onPressed: () async {
                          if (widget.event.type == EventType.remote || widget.event.type == EventType.analysis)
                            showPlatformDialog(
                              context: context,
                              builder: (context) => PlatformAlert(
                                title: Text('New Match'),
                                actions: [
                                  PlatformDialogAction(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      setState(
                                        () {
                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                  ),
                                  PlatformDialogAction(
                                    child: Text('Add'),
                                    onPressed: () {
                                      setState(
                                        () {
                                          widget.event.addMatch(
                                            Match(
                                              Alliance(
                                                widget.event
                                                    .teams[widget.team?.number],
                                                null,
                                                widget.event.type,
                                                widget.event.gameName,
                                              ),
                                              Alliance(
                                                null,
                                                null,
                                                widget.event.type,
                                                widget.event.gameName,
                                              ),
                                              EventType.remote,
                                            ),
                                          );
                                          dataModel.saveEvents();
                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          else {
                            await Navigator.of(context).push(
                              platformPageRoute(
                                builder: (_) => MatchConfig(
                                  event: widget.event,
                                ),
                              ),
                            );
                            setState(() {});
                          }
                        },
                        child: Icon(Icons.add),
                      )
                    : null,
          );
        },
      );

  Widget _matches([ScrollController? scrollController]) {
    final allMatches = widget.event.getSortedMatches(widget.ascending);
    final matches =
        (widget.event.type == EventType.remote || widget.team != null)
            ? allMatches
                .where((e) =>
                    e.alliance(
                      widget.event.teams[widget.team?.number],
                    ) !=
                    null)
                .toList()
            : allMatches;
    if (matches.length == 0) return EmptyList();
    Map<OpModeType?, double> maxScores = {};
    if (widget.team != null) {
      opModeExt.getAll().forEach((type) {
        maxScores[type] = widget.event.statConfig.allianceTotal
            ? widget.event.matches.values
                .toList()
                .spots(widget.team!, Dice.none, false, type: type)
                .removeOutliers(widget.event.statConfig.removeOutliers)
                .map((spot) => spot.y)
                .maxValue()
            : widget.team?.scores.maxScore(Dice.none, false, type, null) ?? 0;
      });
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: ExampleMatchRow(
            event: widget.event,
            team: widget.team,
          ),
        ),
        Expanded(
          child: ListView.builder(
              controller: NewPlatform.isIOS ? null : scrollController,
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                final qualNumber = allMatches.indexOf(match);
                return Slidable(
                  endActionPane: ActionPane(
                    // A motion is a widget used to control how the pane animates.
                    motion: const StretchMotion(),
                    children: [
                      SlidableAction(
                        icon: Icons.delete,
                        backgroundColor: Colors.red,
                        onPressed: (_) {
                          showPlatformDialog(
                            context: context,
                            builder: (BuildContext context) => PlatformAlert(
                              title: Text('Delete Match'),
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
                                    setState(
                                      () => widget.event.deleteMatch(match),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  child: MatchRow(
                    match: match,
                    team: widget.event.teams[widget.team?.number],
                    event: widget.event,
                    index: widget.ascending
                        ? qualNumber + 1
                        : allMatches.length - qualNumber,
                    maxes: maxScores,
                    statConfig: widget.event.statConfig,
                    onTap: () => navigateToMatch(
                      context,
                      match: match,
                      event: widget.event,
                      team: widget.team,
                      state: this,
                    ),
                  ),
                );
              }),
        ),
      ],
    );
  }
}

class MatchSearch extends SearchDelegate<String?> {
  MatchSearch({
    required this.matches,
    required this.event,
    this.ascending = true,
    required this.statConfig,
  });
  final List<Match> matches;
  final Event event;
  final bool ascending;
  StatConfig statConfig;

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => query = '',
          )
      ];
  @override
  Widget buildLeading(context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(context) => buildSuggestions(context);
  @override
  Widget buildSuggestions(context) {
    final suggestionList = matches
        .where(
          (m) =>
              (m.red?.team1?.number.contains(query) ?? false) ||
              (m.red?.team2?.number.contains(query) ?? false) ||
              (m.blue?.team1?.number.contains(query) ?? false) ||
              (m.blue?.team2?.number.contains(query) ?? false) ||
              (m.red?.team1?.name.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (m.red?.team2?.name.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (m.blue?.team1?.name
                      .toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false) ||
              (m.blue?.team2?.name
                      .toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false),
        )
        .toList();
    if (suggestionList.length == 0) return EmptyList();
    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) => MatchRow(
        statConfig: statConfig,
        event: event,
        match: suggestionList[index],
        index: ascending ? index + 1 : suggestionList.length - index,
        onTap: () {
          close(context, null);
          navigateToMatch(
            context,
            match: suggestionList[index],
            event: event,
          );
        },
      ),
    );
  }
}
