import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/change/ChangeConfig.dart';
import 'dart:convert';
import 'package:teamtrack/views/home/change/ChangeRow.dart';

class ChangeList extends StatefulWidget {
  ChangeList({super.key, required this.team, required this.event});
  final Team team;
  final Event event;
  @override
  State<ChangeList> createState() => _ChangeList(team);
}

class _ChangeList extends State<ChangeList> {
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
                                  builder: (BuildContext context) =>
                                      PlatformAlert(
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
                                          widget.event
                                              .deleteChange(change, team);
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
                        ),
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
