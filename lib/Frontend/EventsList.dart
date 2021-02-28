import 'dart:io';

import 'package:TeamTrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:TeamTrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:TeamTrack/Frontend/EventView.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return dataModel
        .localEvents()
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
                                      dataModel.events.remove(e);
                                    });
                                    dataModel.saveEvents();
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
                    trailing: Icon(
                      CupertinoIcons.lock_shield_fill,
                      color: Theme.of(context).accentColor,
                    ),
                    leading: Icon(
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
                                      dataModel: dataModel,
                                    )));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EventView(
                                      event: e,
                                      dataModel: dataModel,
                                    )));
                      }
                    },
                  )),
              actionPane: slider,
            ))
        .toList();
  }

  List<Widget> remoteEvents() {
    return dataModel
        .remoteEvents()
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
                                      dataModel.events.remove(e);
                                    });
                                    dataModel.saveEvents();
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
                    trailing: Icon(
                      CupertinoIcons.lock_shield_fill,
                      color: Theme.of(context).accentColor,
                    ),
                    leading: Icon(
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
                                      dataModel: dataModel,
                                    )));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EventView(
                                      event: e,
                                      dataModel: dataModel,
                                    )));
                      }
                    },
                  )),
              actionPane: slider,
            ))
        .toList();
  }

  List<Widget> liveEvents() {
    return dataModel
        .liveEvents()
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
                                      dataModel.localEvents().remove(e);
                                    });
                                    dataModel.saveEvents();
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
                    trailing: Icon(
                      CupertinoIcons.location,
                      color: Theme.of(context).accentColor,
                    ),
                    leading: Icon(
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
                                      dataModel: dataModel,
                                    )));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EventView(
                                      event: e,
                                      dataModel: dataModel,
                                    )));
                      }
                    },
                  )),
              actionPane: slider,
            ))
        .toList();
  }

  void saveBool(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  String _newName;
  @override
  Widget build(BuildContext context) {
    restoreEvents();
    final themeChange = Provider.of<DarkThemeProvider>(context);
    if (isLoaded) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).accentColor,
          title: Text('Events'),
          actions: [
            IconButton(
              icon: themeChange.darkTheme
                  ? Icon(CupertinoIcons.sun_max)
                  : Icon(CupertinoIcons.moon),
              onPressed: () async {
                setState(() {
                  themeChange.darkTheme = !themeChangeProvider.darkTheme;
                });
              },
            )
          ],
        ),
        body: SafeArea(
          child: ListView(children: [
            ExpansionTile(
              leading: Icon(CupertinoIcons.person_3),
              initiallyExpanded: true,
              title: Text('Local Events'),
              children: localEvents(),
            ),
            ExpansionTile(
              leading: Icon(CupertinoIcons.rectangle_stack_person_crop),
              initiallyExpanded: true,
              title: Text('Remote Events'),
              children: remoteEvents(),
            ),
            // ExpansionTile(
            //   title: Text('Live Events'),
            //   children: liveEvents(),
            // ),
          ]),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: _onPressed,
        ),
      );
    } else {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  bool isLoaded = false;
  restoreEvents() async {
    await SharedPreferences.getInstance();
    setState(() {
      isLoaded = true;
    });
  }

  void _onPressed() {
    showModalBottomSheet(
        context: context,
        builder: (context) => Container(
            height: 120,
            decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).splashColor,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ListTileTheme(
                  iconColor: Theme.of(context).accentColor,
                  child: ListTile(
                    onTap: () {
                      _newType = EventType.local;
                      setState(() {});
                      Navigator.pop(context);
                      _chosen();
                    },
                    leading: Icon(CupertinoIcons.person_3_fill),
                    title: Text('Local Event'),
                  ),
                ),
                ListTileTheme(
                  iconColor: Theme.of(context).accentColor,
                  child: ListTile(
                    onTap: () {
                      _newType = EventType.remote;
                      setState(() {});
                      Navigator.pop(context);
                      _chosen();
                    },
                    leading:
                        Icon(CupertinoIcons.rectangle_stack_person_crop_fill),
                    title: Text('Remote Event'),
                  ),
                ),
                // ListTileTheme(
                //   iconColor: Theme.of(context).accentColor,
                //   child: ListTile(
                //     onTap: () {
                //       _newType = EventType.live;
                //       setState(() {});
                //       Navigator.pop(context);
                //       _chosen();
                //     },
                //     leading: Icon(CupertinoIcons.cloud_fill),
                //     title: Text('Live Event'),
                //   ),
                // )
              ],
            )));
  }

  EventType _newType;
  void _chosen() {
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
                        dataModel.events
                            .add(Event(name: _newName, type: _newType));
                      dataModel.saveEvents();
                      _newName = '';
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }
}
