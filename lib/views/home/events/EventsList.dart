import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:teamtrack/providers/Auth.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/providers/Theme.dart';
import 'package:teamtrack/views/home/events/EventShare.dart';
import 'package:teamtrack/views/inbox/BlockList.dart';
import 'package:teamtrack/views/home/inbox/Inbox.dart';
import 'package:teamtrack/views/auth/Login.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/views/home/events/EventView.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/views/templates/TemplatesList.dart';

class EventsList extends StatefulWidget {
  EventsList({Key? key}) : super(key: key);
  @override
  _EventsList createState() => _EventsList();
}

class _EventsList extends State<EventsList> {
  Map<String, Event> sharedEvents = {};
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
    final themeChange = context.watch<DarkThemeProvider>();
    final TextEditingController controller = new TextEditingController();
    for (var event in dataModel.events.where((e) => !e.shared)) {
      event.authorEmail = context.read<User?>()?.email;
      event.authorName = context.read<User?>()?.displayName;
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      stream: firebaseFirestore
          .collection('users')
          .doc(context.read<User?>()?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        var data = snapshot.data?.data();
        sharedEvents.clear();
        (data?['events'] as Map?)?.keys.forEach((key) {
          try {
            var event = Event.fromJson(data?['events'][key]);
            event.shared = true;
            sharedEvents[key] = event;
          } catch (e) {}
        });
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: Builder(
              builder: (_) {
                switch (_tab) {
                  case 1:
                    return Text("Inbox");
                  case 2:
                    return Text("Blocked Users");
                  case 3:
                    return Text("Templates");
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
                tooltip: themeChange.darkTheme ? "Light Mode" : "Dark Mode",
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
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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
                                    context.read<User?>()?.displayName ??
                                        "Guest",
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
                        Spacer(),
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                showPlatformDialog(
                                  context: context,
                                  builder: (_) => PlatformAlert(
                                    title: Text("Change Display Name"),
                                    content: PlatformTextField(
                                      textInputAction: TextInputAction.done,
                                      placeholder: "Display Name",
                                      keyboardType: TextInputType.name,
                                      controller: controller,
                                    ),
                                    actions: [
                                      PlatformDialogAction(
                                        child: Text("Cancel"),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      PlatformDialogAction(
                                        child: Text("Confirm"),
                                        onPressed: () async {
                                          if (controller.text.isNotEmpty)
                                            await context
                                                .read<User?>()
                                                ?.updateDisplayName(
                                                  controller.text,
                                                );
                                          Navigator.pop(context);
                                          showPlatformDialog(
                                            context: context,
                                            builder: (_) => PlatformAlert(
                                              title: Text("Success"),
                                              content: Text("Reload the App"),
                                              actions: [
                                                PlatformDialogAction(
                                                  child: Text("Okay"),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                              highlightColor: Colors.red,
                            ),
                            Spacer(),
                          ],
                        )
                      ],
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
                      ListTile(
                        leading: Icon(Icons.widgets_outlined),
                        title: Text("Templates"),
                        onTap: () {
                          setState(() => _tab = 3);
                          Navigator.of(context).pop();
                        },
                      ),
                      if (!(context.read<User?>()?.isAnonymous ?? true))
                        ListTile(
                          leading: Icon(Icons.inbox_rounded),
                          title: Text("Inbox"),
                          trailing:
                              (data?['inbox'] as Map?)?.entries.length == 0
                                  ? null
                                  : Container(
                                      decoration: ShapeDecoration(
                                        color: Colors.red,
                                        shape: CircleBorder(),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text((data?['inbox'] as Map?)
                                                ?.entries
                                                .length
                                                .toString() ??
                                            "0"),
                                      ),
                                    ),
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
                              builder: (context) => LoginView(returnBack: true),
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
                                  onPressed: () => Navigator.of(context).pop(),
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
                  tooltip: "Add Event",
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  splashColor: Theme.of(context).colorScheme.secondary,
                  child: Icon(Icons.add),
                  onPressed: _onPressed,
                )
              : null,
        );
      },
    );
  }

  Widget getHome() {
    switch (_tab) {
      case 1:
        return Inbox();
      case 2:
        return BlockList();
      case 3:
        return TemplatesList();
      default:
        return SafeArea(
          child: ListView(
            children: [
              ExpansionTile(
                leading: Icon(CupertinoIcons.person_3),
                initiallyExpanded: true,
                title: Text('In-Person Events'),
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    leading: Icon(
                      CupertinoIcons.person_3_fill,
                      color: Theme.of(context).colorScheme.primary,
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
                          builder: (context) => EventView(
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
        ...sharedEvents.values
            .where((element) => element.type == EventType.local)
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
                    onTap: () => onDelete(e),
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    leading: Icon(
                      CupertinoIcons.person_3_fill,
                      color: Theme.of(context).colorScheme.primary,
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
                          builder: (context) => EventView(
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    leading: Icon(
                      CupertinoIcons.rectangle_stack_person_crop_fill,
                      color: Theme.of(context).colorScheme.primary,
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
                          builder: (context) => EventView(
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
        ...sharedEvents.values
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
                    onTap: () => onDelete(e),
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    leading: Icon(
                      CupertinoIcons.rectangle_stack_person_crop_fill,
                      color: Theme.of(context).colorScheme.primary,
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
                          builder: (context) => EventView(
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
                Navigator.pop(context);
                _chosen();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(CupertinoIcons.person_3_fill),
                  Text('In-Person Event'),
                  Text(''),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                _newType = EventType.remote;
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
                iconColor: Theme.of(context).colorScheme.primary,
                child: ListTile(
                  onTap: () {
                    _newType = EventType.local;
                    Navigator.pop(context);
                    _chosen();
                  },
                  leading: Icon(CupertinoIcons.person_3_fill),
                  title: Text('In-Person Event'),
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
                iconColor: Theme.of(context).colorScheme.primary,
                child: ListTile(
                  onTap: () {
                    _newType = EventType.remote;
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
            textInputAction: TextInputAction.done,
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
                        name: _newName ?? Statics.gameName,
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
          title: Text(e.shared ? 'Share Event' : 'Upload Event'),
          content: EventShare(
            emailController: _emailController,
            event: e,
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
              child: Text(e.shared ? 'Share' : 'Upload'),
              onPressed: () async {
                showPlatformDialog(
                  context: context,
                  builder: (_) => PlatformAlert(
                    content: Center(child: PlatformProgressIndicator()),
                    actions: [
                      PlatformDialogAction(
                        child: Text('Back'),
                        isDefaultAction: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
                if (!e.shared) {
                  var json = e.toJson();
                  json['shared'] = true;
                  final uid = context.read<User?>()?.uid;
                  if (uid != null)
                    json['Permissions'] = {
                      uid: {
                        "role": Role.admin.toRep(),
                        "name": e.authorName,
                        "email": e.authorEmail,
                      },
                    };
                  await firebaseDatabase
                      .reference()
                      .child("Events/${e.gameName}/${e.id}")
                      .set(json);
                  dataModel.events.remove(e);
                  setState(() => dataModel.saveEvents);
                }
                if (_emailController.text.trim().isNotEmpty) {
                  await dataModel.shareEvent(
                    name: e.name,
                    authorName: e.authorName ?? '',
                    authorEmail: e.authorEmail ?? '',
                    id: e.id,
                    type: e.type.toString(),
                    email: _emailController.text.trim(),
                    gameName: e.gameName,
                    role: shareRole,
                  );
                }
                _emailController.clear();
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

  void onDelete(Event e) {
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
              await firebaseFirestore.runTransaction((transaction) async {
                var snapshot = await transaction.get(ref);
                if (!snapshot.exists) {
                  throw Exception("User does not exist!");
                }
                Map<String, dynamic> newEvents =
                    snapshot.data()?["events"] as Map<String, dynamic>;
                newEvents.remove(e.id);
                return transaction.update(
                  ref,
                  {
                    'events': newEvents,
                  },
                );
              });
              setState(
                () => sharedEvents.remove(e.id),
              );
              dataModel.saveEvents();
              if (e.authorEmail == context.read<User?>()?.email)
                e.getRef()?.remove();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
