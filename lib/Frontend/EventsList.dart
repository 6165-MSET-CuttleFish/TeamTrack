import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamtrack/Frontend/BlockList.dart';
import 'package:teamtrack/Frontend/Inbox.dart';
import 'package:teamtrack/Frontend/Login.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:teamtrack/Frontend/EventView.dart';
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
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    for (var event in dataModel.events.where((e) => !e.shared)) {
      event.authorEmail = context.read<User?>()?.email;
      event.authorName = context.read<User?>()?.displayName;
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        future: firebaseFirestore
            .collection('users')
            .doc(context.read<User?>()?.uid)
            .get(),
        builder: (context, snapshot) {
          var data = snapshot.data?.data();
          (data?['events'] as Map?)?.keys.forEach((key) {
            try {
              var event = Event.fromJson(data?['events'][key]);
              event.shared = true;
              dataModel.sharedEvents[key] = event;
            } catch (e) {}
          });
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).accentColor,
              title: Builder(
                builder: (_) {
                  switch (_tab) {
                    case 1:
                      return Text("Inbox");
                    case 2:
                      return Text("Blocked Users");
                    default:
                      return Text("Events");
                  }
                },
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(left: 30),
                ),
                IconButton(
                  icon: themeChange.darkTheme
                      ? Icon(CupertinoIcons.sun_max)
                      : Icon(CupertinoIcons.moon),
                  onPressed: () {
                    setState(() =>
                        themeChange.darkTheme = !themeChangeProvider.darkTheme);
                  },
                )
              ],
            ),
            drawer: Drawer(
              elevation: 1,
              child: Material(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DrawerHeader(
                      decoration:
                          BoxDecoration(color: Theme.of(context).accentColor),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.min,
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
                                Text(
                                  context.read<User?>()?.displayName ?? "Guest",
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  context.read<User?>()?.email ?? "",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.list),
                          title: Text("Events"),
                          onTap: () {
                            setState(() => _tab = 0);
                            Navigator.of(context).pop();
                          },
                        ),
                        if (!(context.read<User?>()?.isAnonymous ?? true))
                          ListTile(
                            leading: Icon(Icons.mail_rounded),
                            title: Text("Inbox"),
                            onTap: () {
                              setState(() => _tab = 1);
                              Navigator.of(context).pop();
                            },
                          ),
                        if (!(context.read<User?>()?.isAnonymous ?? true))
                          ListTile(
                            leading: Icon(Icons.people_alt),
                            title: Text("Blocked Users"),
                            onTap: () {
                              setState(() => _tab = 2);
                              Navigator.of(context).pop();
                            },
                          ),
                        if (context.read<User?>()?.isAnonymous ?? false)
                          ListTile(
                            leading: Icon(Icons.link),
                            title: Text("Link Account"),
                            onTap: () => Navigator.of(context).push(
                              platformPageRoute(
                                (context) => LoginView(returnBack: true),
                              ),
                            ),
                          ),
                        ListTile(
                          leading: Icon(Icons.logout),
                          title: Text('Sign Out'),
                          onTap: () {
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
                                        Navigator.of(context).pop(),
                                  ),
                                  PlatformDialogAction(
                                    isDestructive: true,
                                    child: Text('Sign Out'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      context
                                          .read<AuthenticationService>()
                                          .signOut();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            body: Builder(builder: (_) => getHome()),
            floatingActionButton: _tab == 0
                ? FloatingActionButton(
                    child: Icon(Icons.add),
                    onPressed: _onPressed,
                  )
                : null,
          );
        });
  }

  Widget getHome() {
    switch (_tab) {
      case 1:
        return Inbox();
      case 2:
        return BlockList();
      default:
        return SafeArea(
          child: ListView(
            children: [
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
            ],
          ),
        );
    }
  }

  List<Widget> localEvents() => [
        ...dataModel
            .localEvents()
            .map(
              (e) => Slidable(
                actions: [
                  IconSlideAction(
                    onTap: () => _onShare(e),
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
                                setState(
                                  () {
                                    dataModel.events.remove(e);
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
                      CupertinoIcons.person_3_fill,
                      color: Theme.of(context).accentColor,
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name),
                        Text(
                          e.gameName.spaceBeforeCapital(),
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ],
                    ),
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
                  ),
                ),
                actionPane: slider,
              ),
            )
            .toList(),
        ...dataModel.sharedEvents.values
            .where((element) => element.type == EventType.local)
            .map((e) => Slidable(
                  actions: [
                    IconSlideAction(
                      onTap: () => _onShare(e),
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
                                onPressed: () async {
                                  var ref = firebaseFirestore
                                      .collection('users')
                                      .doc(context.read<User?>()?.uid);
                                  await firebaseFirestore
                                      .runTransaction((transaction) async {
                                    var snapshot = await transaction.get(ref);
                                    if (!snapshot.exists) {
                                      throw Exception("User does not exist!");
                                    }
                                    Map<String, dynamic> newEvents =
                                        snapshot.data()?["events"]
                                            as Map<String, dynamic>;
                                    newEvents.remove(e.id);
                                    return transaction.update(
                                      ref,
                                      {
                                        'events': newEvents,
                                      },
                                    );
                                  });
                                  setState(
                                    () => dataModel.sharedEvents.remove(e.id),
                                  );
                                  dataModel.saveEvents();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
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
                        CupertinoIcons.person_3_fill,
                        color: Theme.of(context).accentColor,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name),
                          Text(
                            e.gameName.spaceBeforeCapital(),
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ],
                      ),
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
                    ),
                  ),
                  actionPane: slider,
                ))
            .toList()
      ];

  List<Widget> remoteEvents() => [
        ...dataModel
            .remoteEvents()
            .map(
              (e) => Slidable(
                actions: [
                  IconSlideAction(
                    onTap: () => _onShare(e),
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
                                setState(() => dataModel.events.remove(e));
                                dataModel.saveEvents();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
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
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name),
                        Text(
                          e.gameName.spaceBeforeCapital(),
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ],
                    ),
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
                  ),
                ),
                actionPane: slider,
              ),
            )
            .toList(),
        ...dataModel.sharedEvents.values
            .where((element) => element.type == EventType.remote)
            .map(
              (e) => Slidable(
                actions: [
                  IconSlideAction(
                    onTap: () => _onShare(e),
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
                              onPressed: () async {
                                var ref = firebaseFirestore
                                    .collection('users')
                                    .doc(context.read<User?>()?.uid);
                                await firebaseFirestore
                                    .runTransaction((transaction) async {
                                  var snapshot = await transaction.get(ref);
                                  if (!snapshot.exists) {
                                    throw Exception("User does not exist!");
                                  }
                                  Map<String, dynamic> newEvents =
                                      snapshot.data()?["events"]
                                          as Map<String, dynamic>;
                                  newEvents.remove(e.id);
                                  return transaction.update(
                                    ref,
                                    {
                                      'events': newEvents,
                                    },
                                  );
                                });
                                setState(
                                    () => dataModel.sharedEvents.remove(e.id));

                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
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
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name),
                        Text(
                          e.gameName.spaceBeforeCapital(),
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ],
                    ),
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
                  ),
                ),
                actionPane: slider,
              ),
            )
            .toList()
      ];

  String? _newName;

  void _onPressed() {
    if (NewPlatform.isIOS())
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
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
              ),
            ),
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
                    Icon(CupertinoIcons.rectangle_stack_person_crop_fill),
                    Text('Remote Event'),
                    Text('')
                  ]),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text('Cancel'),
            onPressed: () => {Navigator.pop(context)},
            isDefaultAction: true,
          ),
        ),
      );
    else
      showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).splashColor,
                  width: 1,
                ),
              ),
              child: ListTileTheme(
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
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).splashColor,
                  width: 1,
                ),
              ),
              child: ListTileTheme(
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
            ),
          ],
        ),
      );
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
                setState(
                  () {
                    if (_newName!.isNotEmpty)
                      dataModel.events.add(Event(
                        name: _newName ?? '',
                        type: _newType ?? EventType.remote,
                        gameName: Statics.gameName,
                      ));
                    dataModel.saveEvents();
                    _newName = '';
                  },
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
  TextEditingController _emailController = TextEditingController();
  void _onShare(Event e) {
    if (!(context.read<User?>()?.isAnonymous ?? true))
      showPlatformDialog(
        context: context,
        builder: (context) => PlatformAlert(
          title: Text('Share Event'),
          content: PlatformTextField(
            placeholder: 'Email',
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
          ),
          actions: [
            PlatformDialogAction(
              child: Text('Cancel'),
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            PlatformDialogAction(
              child: Text('Share'),
              onPressed: () async {
                if (!e.shared) {
                  e.shared = true;
                  var json = e.toJson();
                  var uid = context.read<User?>()?.uid;
                  if (uid != null) json['Editors'] = {uid: true};
                  await firebaseDatabase
                      .reference()
                      .child("Events/${Statics.gameName}/${e.id}")
                      .set(json);
                  var ref = firebaseFirestore.collection('users').doc(uid);
                  firebaseFirestore.runTransaction((transaction) async {
                    var doc = await transaction.get(ref);
                    var newEvents = doc.data()?['events'] as Map;
                    newEvents[e.id] = {
                      'name': e.name,
                      'sendDate': Timestamp.now(),
                      'authorName': e.authorName,
                      'authorEmail': e.authorEmail,
                      'id': e.id,
                      'type': e.type.toString(),
                      'gameName': e.gameName,
                    };
                    transaction.update(ref, {'events': newEvents});
                  });
                  dataModel.events.remove(e);
                  setState(dataModel.saveEvents);
                }
                if (_emailController.text.trim().isNotEmpty) {
                  dataModel.shareEvent(
                    name: e.name,
                    authorName: e.authorName ?? '',
                    authorEmail: e.authorEmail ?? '',
                    id: e.id,
                    type: e.type.toString(),
                    email: _emailController.text.trim(),
                    gameName: e.gameName,
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    else
      showPlatformDialog(
        context: context,
        builder: (context) => PlatformAlert(
          title: Text('Cannot Share Event'),
          content: Text('You must be logged in to share an event.'),
          actions: [
            PlatformDialogAction(
              child: Text('OK'),
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
  }
}
