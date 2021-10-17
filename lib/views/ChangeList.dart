import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teamtrack/logic/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:firebase_database/firebase_database.dart' as Database;
import 'dart:convert';

import 'package:teamtrack/logic/score.dart';
import 'package:uuid/uuid.dart';

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
  final controller = TextEditingController();
  var _date = DateTime.now();
  Team team;
  _ChangeList({required this.team});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Changes'),
          backgroundColor: Theme.of(context).accentColor,
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () => Navigator.of(context)
              .push(
                platformPageRoute(
                  (context) => Scaffold(
                    appBar: AppBar(
                      title: Text('New Change'),
                      backgroundColor: Theme.of(context).accentColor,
                    ),
                    body: ListView(
                      children: [
                        Text(_date.toString()),
                        PlatformButton(
                          child: Text('Date'),
                          onPressed: () => showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020, 1, 1),
                            lastDate: DateTime.now(),
                          ).then(
                            (date) =>
                                setState(() => _date = date ?? DateTime.now()),
                          ),
                          color: Colors.blue,
                        ),
                        PlatformTextField(
                          keyboardType: TextInputType.name,
                          controller: controller,
                          placeholder: 'Name',
                        ),
                        PlatformButton(
                          child: Text('Save'),
                          onPressed: () {
                            widget.team.addChange(
                              Change(
                                title: controller.text,
                                startDate: Timestamp.fromDate(_date),
                                id: Uuid().v4(),
                              ),
                            );
                            controller.clear();
                            _date = DateTime.now();
                            Navigator.pop(context);
                          },
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
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
                          onTap: () {
                            // await Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => TeamView(
                            //       team: e,
                            //       event: widget.event,
                            //     ),
                            //   ),
                            // );
                            setState(() {});
                          },
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
