import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'backend.dart';
import 'package:TeamTrack/Assets/PlatformGraphics.dart';
import 'package:TeamTrack/EventView.dart';

class EventsList extends StatefulWidget {
  EventsList({Key key, this.dataModel}) : super(key: key);
  final DataModel dataModel;
  @override
  _EventsList createState() => _EventsList(dataModel: dataModel);
}

class _EventsList extends State<EventsList> {
  final slider = SlidableStrechActionPane();
  _EventsList({this.dataModel});
  DataModel dataModel;
  final secondaryActions = <Widget>[
    IconSlideAction(
      icon: Icons.delete,
      color: Colors.red,
    )
  ];
  List<Widget> localEvents() {
    return dataModel.localEvents
        .map((e) => Slidable(
              secondaryActions: [
                IconSlideAction(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => PlatformAlert(
                              title: Text('Delete Event'),
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
                                      widget.dataModel.localEvents.remove(e);
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ));
                  },
                  icon: Icons.delete,
                  color: Colors.red,
                )
              ],
              child: ListTileTheme(
                  iconColor: Theme.of(context).primaryColor,
                  child: ListTile(
                    leading: Icon(
                      CupertinoIcons.lock_shield_fill,
                      color: Theme.of(context).accentColor,
                    ),
                    trailing: Icon(
                      CupertinoIcons.person_3_fill,
                      color: Theme.of(context).accentColor,
                    ),
                    title: Text(e.name),
                    onTap: () {
                      if (Platform.isIOS) {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => EventView(
                                      event: e,
                                    )));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EventView(
                                      event: e,
                                    )));
                      }
                    },
                  )),
              actionPane: slider,
            ))
        .toList();
  }

  List<Widget> remoteEvents() {
    return dataModel.remoteEvents
        .map((e) => ListTileTheme(
            iconColor: Theme.of(context).primaryColor,
            child: ListTile(
              leading: Icon(
                CupertinoIcons.lock_shield_fill,
                color: Theme.of(context).accentColor,
              ),
              trailing: Icon(
                CupertinoIcons.rectangle_stack_person_crop_fill,
                color: Theme.of(context).accentColor,
              ),
              title: Text(e.name),
              onTap: () {
                if (Platform.isIOS) {
                  Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (context) => EventView(
                                event: e,
                              )));
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EventView(
                                event: e,
                              )));
                }
              },
            )))
        .toList();
  }

  List<Widget> liveEvents() {
    return dataModel.liveEvents
        .map((e) => ListTileTheme(
            iconColor: Theme.of(context).primaryColor,
            child: ListTile(
              leading: Icon(
                CupertinoIcons.cloud_fill,
                color: Theme.of(context).accentColor,
              ),
              trailing: Icon(
                CupertinoIcons.person_3_fill,
                color: Theme.of(context).accentColor,
              ),
              title: Text(e.name),
              onTap: () {
                if (Platform.isIOS) {
                  Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (context) => EventView(
                                event: e,
                              )));
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EventView(
                                event: e,
                              )));
                }
              },
            )))
        .toList();
  }

  String _newName;
  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
          child: SafeArea(
              child: Scaffold(
                  body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text('Events'),
            previousPageTitle: 'Events',
            trailing: CupertinoButton(
              child: Text('Add'),
              onPressed: _onPressed,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(localEvents()),
          ),
        ],
      ))));
    } else {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).accentColor,
          title: Text('Events'),
        ),
        body: SafeArea(
          child: ListView(
            children: localEvents(),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: _onPressed,
        ),
      );
    }
  }

  void _onPressed() {
    showDialog(
        context: context,
        builder: (BuildContext context) => PlatformAlert(
              title: Text('New Event'),
              content: PlatformTextField(
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                onChanged: (String input) {
                  _newName = input;
                },
                placeholder: 'Enter name',
              ),
              actions: [
                PlatformDialogAction(
                  isDefaultAction: true,
                  child: Text('Cancel'),
                  onPressed: () {
                    _newName = '';
                    Navigator.of(context).pop();
                  },
                ),
                PlatformDialogAction(
                  isDefaultAction: false,
                  child: Text('Save'),
                  onPressed: () {
                    setState(() {
                      if (_newName.isNotEmpty)
                        dataModel.localEvents
                            .add(Event(name: _newName, type: EventType.local));
                      _newName = '';
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }
}
