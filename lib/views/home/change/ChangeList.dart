import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/change/ChangeConfig.dart';
import 'dart:convert';

class ChangeList extends StatefulWidget {
  ChangeList({Key? key, required this.team, required this.event})
      : super(key: key);
  final Team team;
  final Event event;
  @override
  State<StatefulWidget> createState() => _ChangeList(team: team);
}

class _ChangeList extends State<ChangeList> {
  final slider = SlidableStrechActionPane();
  Team team;
  _ChangeList({required this.team});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Changes'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () => Navigator.of(context)
              .push(
                platformPageRoute(
                    builder: (context) => ChangeConfig(
                          team: team,
                        )),
              )
              .then((value) => setState(() {})),
        ),
        body: StreamBuilder<Database.Event>(
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
            return ListView(
              children: widget.team.changes
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
                                title: Text('Delete Change'),
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
                                        () => widget.team.deleteChange(e),
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
                          title: Text(e.title),
                          leading: Text(e.startDate.toDate().toString(),
                              style: Theme.of(context).textTheme.caption),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      );
}
