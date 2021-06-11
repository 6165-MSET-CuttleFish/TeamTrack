import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:teamtrack/Frontend/EventView.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

class EventsList extends StatefulWidget {
  EventsList({Key? key}) : super(key: key);
  @override
  _EventsList createState() => _EventsList();
}

class _EventsList extends State<EventsList> {
  final slider = SlidableStrechActionPane();
  final secondaryActions = <Widget>[
    IconSlideAction(
      icon: Icons.delete,
      color: Colors.red,
    )
  ];

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
            RawMaterialButton(
              shape: CircleBorder(),
              fillColor: Colors.grey,
              child: Text(
                '👀',
                style: TextStyle(fontSize: 30),
              ),
              onPressed: () {
                launch(
                    "https://www.youtube.com/playlist?list=PLDxjFQFO9emFugiSoMBMbJpAlyqztXKce");
              },
            ),
            Padding(
              padding: EdgeInsets.only(left: 30),
            ),
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
        drawer: Drawer(
            elevation: 0,
            child: Container(
              color: Theme.of(context).cardColor,
              child: ListView(
                children: [
                  DrawerHeader(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                      child: Row(
                        children: [
                          if (context.read<User?>()?.photoURL != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(300),
                              child: Image.network(
                                context.read<User?>()!.photoURL!,
                                height: 70,
                              ),
                            )
                          else
                            Icon(Icons.account_circle, size: 70),
                          Spacer(),
                          PlatformButton(
                              child: Text('Sign Out'),
                              onPressed: () {
                                showPlatformDialog(
                                    context: context,
                                    builder: (context) => PlatformAlert(
                                          title: Text('Sign Out'),
                                          content: Text('Are you sure?'),
                                          actions: [
                                            PlatformDialogAction(
                                                isDefaultAction: true,
                                                child: Text('Cancel'),
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop()),
                                            PlatformDialogAction(
                                                isDestructive: true,
                                                child: Text('Sign Out'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  context
                                                      .read<
                                                          AuthenticationService>()
                                                      .signOut();
                                                }),
                                          ],
                                        ));
                              }),
                        ],
                      ),
                    ),
                  ),
                  Text(context.read<User?>()?.displayName ?? "Guest"),
                  Text(context.read<User?>()?.email ?? ""),
                ],
              ),
            )),
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

  List<Widget> localEvents() => dataModel
      .localEvents()
      .map((e) => Slidable(
            actions: [
              IconSlideAction(
                onTap: () {},
                icon: Icons.share,
                color: Colors.blue,
              )
            ],
            secondaryActions: [
              IconSlideAction(
                onTap: () {
                  showPlatformDialog(
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
                  title: Text(e.name!),
                  onTap: () {
                    Navigator.push(
                      context,
                      platformPageRoute(
                        (context) => EventView(
                          event: e,
                        ),
                      ),
                    );
                  },
                )),
            actionPane: slider,
          ))
      .toList();

  List<Widget> remoteEvents() => dataModel
      .remoteEvents()
      .map((e) => Slidable(
            actions: [
              IconSlideAction(
                onTap: () async {
                  e.shared = true;
                  firebaseDatabase.reference().child(e.id).set(e.toJson());
                  dataModel.saveEvents();
                },
                icon: Icons.share,
                color: Colors.blue,
              )
            ],
            secondaryActions: [
              IconSlideAction(
                onTap: () {
                  showPlatformDialog(
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
                    e.shared
                        ? CupertinoIcons.cloud_fill
                        : CupertinoIcons.lock_shield_fill,
                    color: Theme.of(context).accentColor,
                  ),
                  leading: Icon(
                    CupertinoIcons.rectangle_stack_person_crop_fill,
                    color: Theme.of(context).accentColor,
                  ),
                  title: Text(e.name!),
                  onTap: () {
                    Navigator.push(
                        context,
                        platformPageRoute((context) => EventView(
                              event: e,
                            )));
                  },
                )),
            actionPane: slider,
          ))
      .toList();

  List<Widget> liveEvents() => dataModel
      .liveEvents()
      .map((e) => Slidable(
            actions: [
              IconSlideAction(
                onTap: () {},
                icon: Icons.share,
                color: Colors.blue,
              )
            ],
            secondaryActions: [
              IconSlideAction(
                onTap: () {
                  showPlatformDialog(
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
                  title: Text(e.name!),
                  onTap: () {
                    Navigator.push(
                        context,
                        platformPageRoute((context) => EventView(
                              event: e,
                            )));
                  },
                )),
            actionPane: slider,
          ))
      .toList();

  void saveBool(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  String? _newName;

  bool isLoaded = false;
  restoreEvents() async {
    await SharedPreferences.getInstance();
    setState(() {
      isLoaded = true;
    });
  }

  void _onPressed() {
    Future materialModal = showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 120,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).splashColor,
              width: 1.0,
            ),
            color: Theme.of(context).canvasColor,
          ),
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
          ),
        ),
      ),
    );
    if (NewPlatform.isIOS())
      showCupertinoModalPopup(
          context: context,
          builder: (context) => CupertinoActionSheet(
                //title: Text('New Event'),
                message: Text('Select Event Type'),
                actions: [
                  CupertinoActionSheetAction(
                      onPressed: () {
                        _newType = EventType.local;
                        setState(() {});
                        Navigator.pop(context);
                        _chosen();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(CupertinoIcons.person_3_fill),
                          Text('Local Event'),
                          Text(''),
                        ],
                      )),
                  CupertinoActionSheetAction(
                      onPressed: () {
                        _newType = EventType.remote;
                        setState(() {});
                        Navigator.pop(context);
                        _chosen();
                      },
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(CupertinoIcons
                                .rectangle_stack_person_crop_fill),
                            Text('Remote Event'),
                            Text('')
                          ])),
                ],
                cancelButton: CupertinoActionSheetAction(
                  child: Text('Cancel'),
                  onPressed: () => {Navigator.pop(context)},
                  isDefaultAction: true,
                ),
              ));
    else
      materialModal;
  }

  EventType? _newType;
  void _chosen() => showPlatformDialog(
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
                  if (_newName!.isNotEmpty)
                    dataModel.events.add(Event(name: _newName, type: _newType));
                  dataModel.saveEvents();
                  _newName = '';
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
}
