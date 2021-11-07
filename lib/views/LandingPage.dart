import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:teamtrack/providers/Auth.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/providers/Theme.dart';
import 'package:teamtrack/views/home/events/EventShare.dart';
import 'package:teamtrack/views/home/events/EventsList.dart';
import 'package:teamtrack/views/inbox/BlockList.dart';
import 'package:teamtrack/views/inbox/Inbox.dart';
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

class LandingPage extends StatefulWidget {
  LandingPage({Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

enum Page {
  events,
  inbox,
  templates,
  blockedUsers,
}

class _LandingPageState extends State<LandingPage> {
  Page selectedPage = Page.events;
  final TextEditingController controller = new TextEditingController();
  @override
  Widget build(context) {
    final themeChange = context.watch<DarkThemeProvider>();
    for (var event in dataModel.events.where((e) => !e.shared)) {
      final user = context.read<User?>();
      event.authorEmail = user?.email;
      event.authorName = user?.displayName;
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      stream: firebaseFirestore
          .collection('users')
          .doc(context.read<User?>()?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        dataModel.sharedEvents.clear();
        dataModel.inbox.clear();
        dataModel.blockedUsers.clear();
        (data?['events'] as Map?)?.values.forEach((value) {
          try {
            final event = Event.fromJson(value);
            event.shared = true;
            dataModel.sharedEvents.add(event);
          } catch (e) {}
        });
        (data?['inbox'] as Map?)?.values.forEach((value) {
          try {
            final event = Event.fromJson(value);
            event.shared = true;
            dataModel.inbox.add(event);
          } catch (e) {}
        });
        (data?['blockedUsers'] as Map?)?.keys.forEach((key) {
          try {
            final ttuser =
                TeamTrackUser.fromJson(data?['blockedUsers']?[key], key);
            dataModel.blockedUsers.add(ttuser);
          } catch (e) {
            dataModel.blockedUsers.add(TeamTrackUser(
                role: Role.viewer,
                id: key,
                email: data?['blockedUsers']?[key]));
          }
        });
        return Scaffold(
          appBar: AppBar(
            title: Text(_buildTitle()),
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
              ),
            ],
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          body: _buildBody(),
          floatingActionButton: selectedPage == Page.events
              ? FloatingActionButton(
                  tooltip: "Add Event",
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  splashColor: Theme.of(context).colorScheme.secondary,
                  child: Icon(Icons.add),
                  onPressed: _onPressed,
                )
              : null,
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
                          setState(() => selectedPage = Page.events);
                          Navigator.of(context).pop();
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.widgets_outlined),
                        title: Text("Templates"),
                        onTap: () {
                          setState(() => selectedPage = Page.templates);
                          Navigator.of(context).pop();
                        },
                      ),
                      if (!(context.read<User?>()?.isAnonymous ?? true))
                        ListTile(
                          leading: Icon(Icons.inbox_rounded),
                          title: Text("Inbox"),
                          trailing: dataModel.inbox.length == 0
                              ? null
                              : Container(
                                  decoration: ShapeDecoration(
                                    color: Colors.red,
                                    shape: CircleBorder(),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child:
                                        Text(dataModel.inbox.length.toString()),
                                  ),
                                ),
                          onTap: () {
                            setState(() => selectedPage = Page.inbox);
                            Navigator.of(context).pop();
                          },
                        ),
                      if (!(context.read<User?>()?.isAnonymous ?? true))
                        ListTile(
                          leading: Icon(Icons.people_alt),
                          title: Text("Blocked Users"),
                          onTap: () {
                            setState(() => selectedPage = Page.blockedUsers);
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
        );
      },
    );
  }

  Widget _buildBody() {
    switch (selectedPage) {
      case Page.events:
        return EventsList();
      case Page.inbox:
        return Inbox();
      case Page.templates:
        return TemplatesList();
      case Page.blockedUsers:
        return BlockList();
    }
  }

  String _buildTitle() {
    switch (selectedPage) {
      case Page.events:
        return 'Events';
      case Page.inbox:
        return 'Inbox';
      case Page.templates:
        return 'Templates';
      case Page.blockedUsers:
        return 'Blocked Users';
    }
  }

  String? _newName;
  EventType? _newType;
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
}
