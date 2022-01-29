import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/change/ChangeConfig.dart';
import 'dart:convert';
import 'package:teamtrack/views/home/change/ChangeRow.dart';

class ChangeList extends StatefulWidget {
  ChangeList({Key? key, required this.team, required this.event})
      : super(key: key);
  final Team team;
  final Event event;
  @override
  State<StatefulWidget> createState() => _ChangeList(team);
}

class _ChangeList extends State<ChangeList> {
  final slider = SlidableStrechActionPane();
  Team team;
  _ChangeList(this.team);

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
        team = widget.event.teams[widget.team.number] ?? Team.nullTeam();
        team.changes.sort((a, b) => a.startDate.compareTo(b.startDate));
        return Scaffold(
          appBar: AppBar(
            title: PlatformText('Changes'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () => Navigator.of(context)
                .push(
                  platformPageRoute(
                    builder: (context) => ChangeConfig(
                      team: team,
                      event: widget.event,
                    ),
                  ),
                )
                .then((_) => setState(() {})),
          ),
          body: StreamBuilder<DatabaseEvent>(
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
                children: team.changes
                    .map(
                      (change) => Slidable(
                        actionPane: slider,
                        secondaryActions: [
                          IconSlideAction(
                            icon: Icons.delete,
                            color: Colors.red,
                            onTap: () {
                              showPlatformDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    PlatformAlert(
                                  title: PlatformText('Delete Change'),
                                  content: PlatformText('Are you sure?'),
                                  actions: [
                                    PlatformDialogAction(
                                      isDefaultAction: true,
                                      child: PlatformText('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    PlatformDialogAction(
                                      isDefaultAction: false,
                                      isDestructive: true,
                                      child: PlatformText('Confirm'),
                                      onPressed: () {
                                        widget.event.deleteChange(change, team);
                                        setState(() {});
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
                        child: ChangeRow(
                          onTap: () => Navigator.of(context)
                              .push(
                                platformPageRoute(
                                  builder: (context) => ChangeConfig(
                                    change: change,
                                    event: widget.event,
                                    team: team,
                                  ),
                                ),
                              )
                              .then((_) => setState(() {})),
                          change: change,
                          event: widget.event,
                          team: team,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        );
      });
}
