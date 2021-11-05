import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:teamtrack/components/EmptyList.dart';
import 'package:teamtrack/functions/Functions.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/match/MatchConfig.dart';
import 'package:teamtrack/views/home/match/MatchRow.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'dart:convert';

class MatchList extends StatefulWidget {
  MatchList({
    Key? key,
    required this.event,
    this.team,
    required this.ascending,
  }) : super(key: key);
  final Event event;
  final Team? team;
  final bool ascending;
  @override
  State<StatefulWidget> createState() => _MatchList();
}

class _MatchList extends State<MatchList> {
  final slider = SlidableStrechActionPane();
  @override
  Widget build(BuildContext context) => StreamBuilder<Database.Event>(
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
          if (widget.team == null) {
            return _matches();
          }
          return Scaffold(
            appBar: AppBar(
              title: Text('Matches'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            body: _matches(),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                if (widget.event.type == EventType.remote)
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
                                      widget.event.teams[widget.team?.number],
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
            ),
          );
        },
      );

  Widget _matches() {
    final matches =
        (widget.event.type == EventType.remote || widget.team != null)
            ? widget.event
                .getSortedMatches(widget.ascending)
                .where((e) =>
                    e.alliance(
                      widget.event.teams[widget.team?.number],
                    ) !=
                    null)
                .toList()
            : widget.event.getSortedMatches(widget.ascending);
    if (matches.length == 0) return EmptyList();
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) => Slidable(
        actionPane: slider,
        secondaryActions: [
          IconSlideAction(
            icon: Icons.delete,
            color: Colors.red,
            onTap: () {
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
                          () => widget.event.deleteMatch(matches[index]),
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
        child: MatchRow(
          match: matches[index],
          team: widget.event.teams[widget.team?.number],
          event: widget.event,
          index: widget.ascending ? index + 1 : matches.length - index,
          onTap: () => navigateToMatch(
            context,
            match: matches[index],
            event: widget.event,
            state: this,
          ),
        ),
      ),
    );
  }
}

class MatchSearch extends SearchDelegate<String?> {
  MatchSearch({required this.matches, required this.event});
  List<Match> matches;
  Event event;
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
              (m.red?.team1?.name.contains(query) ?? false) ||
              (m.red?.team2?.name.contains(query) ?? false) ||
              (m.blue?.team1?.name.contains(query) ?? false) ||
              (m.blue?.team2?.name.contains(query) ?? false),
        )
        .toList();
    if (suggestionList.length == 0) return EmptyList();
    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        return MatchRow(
          event: event,
          match: suggestionList[index],
          index: index + 1,
          onTap: () => navigateToMatch(
            context,
            match: suggestionList[index],
            event: event,
          ),
        );
      },
    );
  }
}
