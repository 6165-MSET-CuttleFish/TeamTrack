import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:teamtrack/Frontend/MatchView.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'dart:convert';

class MatchList extends StatefulWidget {
  MatchList({Key? key, required this.event, this.team}) : super(key: key);
  final Event event;
  final Team? team;
  @override
  State<StatefulWidget> createState() => _MatchList();
}

class _MatchList extends State<MatchList> {
  final slider = SlidableStrechActionPane();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Database.Event>(
        stream: DatabaseServices(id: widget.event.id).getEventChanges,
        builder: (context, eventHandler) {
          if (eventHandler.hasData &&
              !eventHandler.hasError &&
              !dataModel.isProcessing) {
            widget.event.updateLocal(
                json.decode(json.encode(eventHandler.data?.snapshot.value)));
          }
          if (widget.team == null) {
            return _matches();
          }
          return Scaffold(
            appBar: AppBar(
              title: Text('Matches'),
              backgroundColor: Theme.of(context).accentColor,
            ),
            body: _matches(),
            floatingActionButton: widget.event.type == EventType.remote
                ? FloatingActionButton(
                    onPressed: () {
                      showPlatformDialog(
                          context: context,
                          builder: (context) => PlatformAlert(
                                title: Text('New Match'),
                                actions: [
                                  PlatformDialogAction(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      setState(() {
                                        Navigator.pop(context);
                                      });
                                    },
                                  ),
                                  PlatformDialogAction(
                                    child: Text('Add'),
                                    onPressed: () {
                                      setState(() {
                                        widget.event.matches.add(
                                          Match(
                                              Alliance(
                                                  widget.event.teams.firstWhere(
                                                      (element) =>
                                                          element.number ==
                                                          widget.team!.number),
                                                  Team.nullTeam()),
                                              Alliance(Team.nullTeam(),
                                                  Team.nullTeam()),
                                              EventType.remote),
                                        );
                                        dataModel.saveEvents();
                                        dataModel.uploadEvent(widget.event);
                                        Navigator.pop(context);
                                      });
                                    },
                                  ),
                                ],
                              ));
                    },
                    child: Icon(Icons.add),
                  )
                : null,
          );
        });
  }

  Widget _matches() {
    if (widget.event.type != EventType.remote) {
      return ListView(
        children: widget.team == null
            ? widget.event.matches
                .map((e) => Slidable(
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
                                          setState(() {
                                            widget.event.deleteMatch(e);
                                          });
                                          dataModel.saveEvents();
                                          dataModel.uploadEvent(widget.event);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ));
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
                          leading: Column(children: [
                            Text(e.red?.item1?.name ??
                                '?' + ' & ' + (e.red?.item2?.name ?? '?')),
                            Text(
                              'VS',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(e.blue?.item1?.name ??
                                '?' + ' & ' + (e.blue?.item2?.name ?? '?'))
                          ]),
                          trailing: Text(e.score()),
                          onTap: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MatchView(
                                          match: e,
                                          event: widget.event,
                                        )));
                            setState(() {});
                          },
                        ))))
                .toList()
            : _teamSpecMatches(),
      );
    } else {
      var arr = <Slidable>[];
      var matches = widget.event.matches
          .where((e) =>
              e.alliance(widget.event.teams.firstWhere(
                  (element) => element.number == widget.team!.number)) !=
              null)
          .toList();
      for (int i = 0; i < matches.length; i++) {
        arr.add(Slidable(
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
                                  matches[i].red?.item1?.scores.removeWhere(
                                      (f) => f.id == matches[i].id);
                                  widget.event.matches.remove(matches[i]);
                                  setState(() {});
                                  dataModel.saveEvents();
                                  dataModel.uploadEvent(widget.event);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ));
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
                  leading: Text((i + 1).toString()),
                  title: Text(widget.event.teams
                      .firstWhere(
                          (element) => element.number == widget.team?.number)
                      .name),
                  trailing: Text(matches[i].score()),
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MatchView(
                                  match: matches[i],
                                  event: widget.event,
                                )));
                    setState(() {});
                  },
                ))));
      }
      return ListView(
        children: arr,
      );
    }
  }

  List<Widget> _teamSpecMatches() => widget.event.matches
      .where((e) =>
          e.alliance(widget.event.teams.firstWhere(
              (element) => element.number == widget.team!.number)) !=
          null)
      .toList()
      .map(
        (e) => Slidable(
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
                          setState(() {
                            e.red?.item1?.scores
                                .removeWhere((f) => f.id == e.id);
                            e.red?.item2?.scores
                                .removeWhere((f) => f.id == e.id);
                            e.blue?.item1?.scores
                                .removeWhere((f) => f.id == e.id);
                            e.blue?.item2?.scores
                                .removeWhere((f) => f.id == e.id);
                            widget.event.matches.remove(e);
                          });
                          dataModel.saveEvents();
                          dataModel.uploadEvent(widget.event);
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
              leading: Column(children: [
                Text(e.red?.item1?.name ??
                    '?' + ' & ' + (e.red?.item2?.name ?? '?')),
                Text(
                  'VS',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                Text(e.blue?.item1?.name ??
                    '?' + ' & ' + (e.blue?.item2?.name ?? '?'))
              ]),
              trailing: Text(e.score()),
              onTap: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MatchView(
                              match: e,
                              event: widget.event,
                            )));
                setState(() {});
              },
            ),
          ),
        ),
      )
      .toList();
}
