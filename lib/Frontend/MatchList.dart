import 'package:TeamTrack/Frontend/MatchView.dart';
import 'package:TeamTrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:TeamTrack/Frontend/Assets/PlatformGraphics.dart';

class MatchList extends StatefulWidget {
  MatchList({Key key, this.event, this.team}) : super(key: key);
  final Event event;
  final Team team;
  @override
  State<StatefulWidget> createState() => _MatchList();
}

class _MatchList extends State<MatchList> {
  final slider = SlidableStrechActionPane();
  final secondaryActions = <Widget>[
    IconSlideAction(
      caption: 'Delete',
      icon: Icons.delete,
      color: Colors.red,
      onTap: () {},
    )
  ];
  @override
  Widget build(BuildContext context) {
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
                showDialog(
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
                                        Alliance(widget.team, Team.nullTeam()),
                                        Alliance(
                                            Team.nullTeam(), Team.nullTeam()),
                                        EventType.remote),
                                  );
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
  }

  Widget _matches() {
    if (widget.event.type != EventType.remote) {
      return ListView(
        semanticChildCount: widget.event.matches.length,
        children: widget.team == null
            ? widget.event.matches
                .map((e) => Slidable(
                    actionPane: slider,
                    secondaryActions: [
                      IconSlideAction(
                        icon: Icons.delete,
                        color: Colors.red,
                        onTap: () {
                          showDialog(
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
                                            e.red.item1.scores.removeWhere(
                                                (f) => f.id == e.id);
                                            e.red.item2.scores.removeWhere(
                                                (f) => f.id == e.id);
                                            e.blue.item1.scores.removeWhere(
                                                (f) => f.id == e.id);
                                            e.blue.item2.scores.removeWhere(
                                                (f) => f.id == e.id);
                                            widget.event.matches.remove(e);
                                          });
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
                            Text(e.red.item1.name + ' & ' + e.red.item2.name),
                            Text(
                              'VS',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(e.blue.item1.name + ' & ' + e.blue.item2.name)
                          ]),
                          trailing: Text(e.score()),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MatchView(match: e)));
                          },
                        ))))
                .toList()
            : _teamSpecMatches(),
      );
    } else {
      var arr = <Slidable>[];
      var matches = widget.event.matches
          .where((e) => e.alliance(widget.team) != null)
          .toList();
      for (int i = 0; i < matches.length; i++) {
        arr.add(Slidable(
            actionPane: slider,
            secondaryActions: [
              IconSlideAction(
                icon: Icons.delete,
                color: Colors.red,
                onTap: () {
                  showDialog(
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
                                    matches[i].red.item1.scores.removeWhere(
                                        (f) => f.id == matches[i].id);
                                    matches.remove(matches[i]);
                                  });
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
                  title: Text(widget.team.name),
                  trailing: Text(matches[i].score()),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                MatchView(match: matches[i])));
                  },
                ))));
      }
      return ListView(
        children: arr,
      );
    }
  }

  List<Widget> _teamSpecMatches() {
    if (widget.team != null) {
      return widget.event.matches
          .where((e) => e.alliance(widget.team) != null)
          .toList()
          .map((e) => Slidable(
              actionPane: slider,
              secondaryActions: [
                IconSlideAction(
                  icon: Icons.delete,
                  color: Colors.red,
                  onTap: () {
                    showDialog(
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
                                      e.red.item1.scores
                                          .removeWhere((f) => f.id == e.id);
                                      e.red.item2.scores
                                          .removeWhere((f) => f.id == e.id);
                                      e.blue.item1.scores
                                          .removeWhere((f) => f.id == e.id);
                                      e.blue.item2.scores
                                          .removeWhere((f) => f.id == e.id);
                                      widget.event.matches.remove(e);
                                    });
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
                      Text(e.red.item1.name + ' & ' + e.red.item2.name),
                      Text(
                        'VS',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      Text(e.blue.item1.name + ' & ' + e.blue.item2.name)
                    ]),
                    trailing: Text(e.score()),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MatchView(match: e)));
                    },
                  ))))
          .toList();
    } else {
      return [];
    }
  }
}
