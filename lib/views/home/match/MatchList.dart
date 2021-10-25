import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:google_fonts/google_fonts.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/match/MatchConfig.dart';
import 'package:teamtrack/views/home/match/MatchView.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamtrack/functions/Extensions.dart';

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
                      (_) => MatchConfig(
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
    int i = widget.event.matches.length + 1;
    if (widget.ascending) i = 0;
    if (widget.event.type != EventType.remote) {
      return ListView(
        children: widget.team == null
            ? widget.event.getSortedMatches(widget.ascending).map((e) {
                widget.ascending ? i++ : i--;
                return Slidable(
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
                                    () {
                                      widget.event.deleteMatch(e);
                                    },
                                  );
                                  dataModel.saveEvents();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Text(i.toString()),
                      title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (e.red?.team1?.name ?? '?') +
                                  ' & ' +
                                  (e.red?.team2?.name ?? '?'),
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
                              (e.blue?.team1?.name ?? '?') +
                                  ' & ' +
                                  (e.blue?.team2?.name ?? '?'),
                              style: Theme.of(context).textTheme.caption,
                            )
                          ]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.redScore(showPenalties: true).toString(),
                            style: GoogleFonts.gugi(
                              color: e.redScore(showPenalties: true) >
                                      e.blueScore(showPenalties: true)
                                  ? CupertinoColors.systemRed
                                  : Colors.grey,
                            ),
                          ),
                          Text(" - ", style: GoogleFonts.gugi()),
                          Text(
                            e.blueScore(showPenalties: true).toString(),
                            style: GoogleFonts.gugi(
                              color: e.redScore(showPenalties: true) <
                                      e.blueScore(showPenalties: true)
                                  ? CupertinoColors.systemBlue
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      onTap: () async {
                        final user = context.read<User?>();
                        final ttuser = widget.event.getTTUserFromUser(user);
                        widget.event
                            .getRef()
                            ?.child('matches/${e.id}/activeUsers/${user?.uid}')
                            .set(ttuser.toJson());
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchView(
                              match: e,
                              event: widget.event,
                            ),
                          ),
                        );
                        widget.event
                            .getRef()
                            ?.child('matches/${e.id}//activeUsers/${user?.uid}')
                            .remove();
                        setState(() {});
                      },
                    ),
                  ),
                );
              }).toList()
            : _teamSpecMatches(),
      );
    } else {
      var arr = <Slidable>[];
      var matches = widget.event
          .getSortedMatches(widget.ascending)
          .where((e) =>
              e.alliance(
                widget.event.teams[widget.team?.number],
              ) !=
              null)
          .toList();
      for (int i = 0; i < matches.length; i++) {
        arr.add(
          Slidable(
            actionPane: slider,
            secondaryActions: [
              IconSlideAction(
                icon: Icons.delete,
                color: Colors.red,
                onTap: () {
                  showPlatformDialog(
                    context: context,
                    builder: (context) => PlatformAlert(
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
                              () => widget.event.deleteMatch(
                                matches[i],
                              ),
                            );
                            dataModel.saveEvents();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              )
            ],
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: Text(
                  (i + 1).toString(),
                ),
                title: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto : ${matches[i].getScore(widget.team?.number)?.autoScore.total()}',
                          style: Theme.of(context).textTheme.caption,
                        ),
                        Text(
                          'Tele : ${matches[i].getScore(widget.team?.number)?.teleScore.total()}',
                          style: Theme.of(context).textTheme.caption,
                        ),
                        Text(
                          'Endgame : ${matches[i].getScore(widget.team?.number)?.endgameScore.total()}',
                          style: Theme.of(context).textTheme.caption,
                        )
                      ],
                    ),
                    Spacer(),
                    Text(
                      '${json.decode(
                        remoteConfig.getString(
                          widget.event.gameName,
                        ),
                      )['Dice']['name']} : ${matches[i].dice.toVal(widget.event.gameName)}',
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ],
                ),
                trailing: Text(
                  matches[i].score(showPenalties: true),
                ),
                onTap: () async {
                  final user = context.read<User?>();
                  final ttuser = widget.event.getTTUserFromUser(user);
                  widget.event
                      .getRef()
                      ?.child(
                          'matches/${matches[i].id}/activeUsers/${user?.uid}')
                      .set(ttuser.toJson());
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MatchView(
                        match: matches[i],
                        event: widget.event,
                      ),
                    ),
                  );
                  widget.event
                      .getRef()
                      ?.child(
                          'matches/${matches[i].id}//activeUsers/${user?.uid}')
                      .remove();
                  setState(() {});
                },
              ),
            ),
          ),
        );
      }
      return ListView(
        children: arr,
      );
    }
  }

  List<Widget> _teamSpecMatches() {
    int i = 0;
    return widget.event
        .getSortedMatches(widget.ascending)
        .where((e) =>
            e.alliance(
              widget.event.teams[widget.team?.number],
            ) !=
            null)
        .toList()
        .map((e) {
      i++;
      return Slidable(
        actionPane: slider,
        secondaryActions: [
          IconSlideAction(
            icon: Icons.delete,
            color: Colors.red,
            onTap: () {
              showPlatformDialog(
                context: context,
                builder: (context) => PlatformAlert(
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
                          () => widget.event.deleteMatch(e),
                        );
                        dataModel.saveEvents();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey,
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Text(i.toString()),
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                (e.red?.team1?.name ?? '?') +
                    ' & ' +
                    (e.red?.team2?.name ?? '?'),
                style: Theme.of(context).textTheme.caption,
              ),
              Text(
                'VS',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
              Text(
                (e.blue?.team1?.name ?? '?') +
                    ' & ' +
                    (e.blue?.team2?.name ?? '?'),
                style: Theme.of(context).textTheme.caption,
              )
            ]),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.redScore(showPenalties: true).toString(),
                  style: GoogleFonts.gugi(
                    color: e.alliance(widget.team) == e.red
                        ? CupertinoColors.systemYellow
                        : Colors.grey,
                  ),
                ),
                Text(" - ", style: GoogleFonts.gugi()),
                Text(
                  e.blueScore(showPenalties: true).toString(),
                  style: GoogleFonts.gugi(
                    color: e.alliance(widget.team) == e.blue
                        ? CupertinoColors.systemYellow
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            onTap: () async {
              final user = context.read<User?>();
              final ttuser = widget.event.getTTUserFromUser(user);
              widget.event
                  .getRef()
                  ?.child('matches/${e.id}/activeUsers/${user?.uid}')
                  .set(ttuser.toJson());
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchView(
                    match: e,
                    event: widget.event,
                  ),
                ),
              );
              widget.event
                  .getRef()
                  ?.child('matches/${e.id}//activeUsers/${user?.uid}')
                  .remove();
              setState(() {});
            },
          ),
        ),
      );
    }).toList();
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
    int i = 0;
    return ListView.builder(
        itemCount: suggestionList.length,
        itemBuilder: (context, index) {
          i++;
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
            ),
            child: ListTile(
              leading: Text(i.toString()),
              title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (suggestionList[index].red?.team1?.name ?? '?') +
                          ' & ' +
                          (suggestionList[index].red?.team2?.name ?? '?'),
                      style: Theme.of(context).textTheme.caption,
                    ),
                    Text(
                      'VS',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                    Text(
                      (suggestionList[index].blue?.team1?.name ?? '?') +
                          ' & ' +
                          (suggestionList[index].blue?.team2?.name ?? '?'),
                      style: Theme.of(context).textTheme.caption,
                    )
                  ]),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    suggestionList[index]
                        .redScore(showPenalties: true)
                        .toString(),
                    style: GoogleFonts.gugi(
                      color:
                          suggestionList[index].redScore(showPenalties: true) >
                                  suggestionList[index]
                                      .blueScore(showPenalties: true)
                              ? CupertinoColors.systemRed
                              : Colors.grey,
                    ),
                  ),
                  Text(" - ", style: GoogleFonts.gugi()),
                  Text(
                    suggestionList[index]
                        .blueScore(showPenalties: true)
                        .toString(),
                    style: GoogleFonts.gugi(
                      color:
                          suggestionList[index].redScore(showPenalties: true) <
                                  suggestionList[index]
                                      .blueScore(showPenalties: true)
                              ? CupertinoColors.systemBlue
                              : Colors.grey,
                    ),
                  ),
                ],
              ),
              onTap: () async {
                close(context, null);
                final user = context.read<User?>();
                final ttuser = event.getTTUserFromUser(user);
                event
                    .getRef()
                    ?.child(
                        'matches/${suggestionList[index].id}/activeUsers/${user?.uid}')
                    .set(ttuser.toJson());
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MatchView(
                      match: suggestionList[index],
                      event: event,
                    ),
                  ),
                );
                event
                    .getRef()
                    ?.child(
                        'matches/${suggestionList[index].id}//activeUsers/${user?.uid}')
                    .remove();
              },
            ),
          );
        });
  }
}
