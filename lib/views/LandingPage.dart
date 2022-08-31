import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/providers/Auth.dart';
import 'package:teamtrack/providers/PushNotifications.dart';
import 'package:teamtrack/providers/Theme.dart';
import 'package:teamtrack/views/auth/Login.dart';
import 'package:teamtrack/views/home/events/EventsList.dart';
import 'package:teamtrack/views/inbox/BlockList.dart';
import 'package:teamtrack/views/inbox/Inbox.dart';
import 'package:teamtrack/views/templates/TemplatesList.dart';
import 'package:collection/collection.dart';


class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

enum Tab {
  events,
  inbox,
  blocked_users,
  templates,
}

var tab = Tab.events;

class _LandingPageState extends State<LandingPage> {
  EventType? _newType;
  String? _newName;

  @override
  void initState() {
    super.initState();
    PushNotifications.onNotifications.stream.listen(onClickedNotification);
  }

  void onClickedNotification(String? payload) =>
      setState(() => tab = Tab.inbox);

  Text title() {
    switch (tab) {
      case Tab.inbox:
        return Text("Inbox");
      case Tab.blocked_users:
        return Text("Blocked Users");
      case Tab.templates:
        return Text("Templates");
      case Tab.events:
        return Text("Events");
    }
  }

  Widget body() {
    switch (tab) {
      case Tab.inbox:
        return Inbox();
      case Tab.blocked_users:
        return BlockList();
      case Tab.templates:
        return TemplatesList();
      case Tab.events:
        return EventsList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = context.watch<DarkThemeProvider>();
    final TextEditingController controller = new TextEditingController();
    for (var event in dataModel.events.where((e) => !e.shared)) {
      final user = context.read<User?>();
      event.author = TeamTrackUser.fromUser(user);
      event.role = Role.admin;
    }



    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>
      (

      //get data from database
      stream: firebaseFirestore
          .collection('users')
          .doc(context.read<User?>()?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        var data = snapshot.data?.data();
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
                uid: key,
                email: data?['blockedUsers']?[key]));
          }
        });


        //light mode/dark mode at the top
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: title(),
            actions: [
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


          //idk
          body: body(),
          floatingActionButton: tab == Tab.events
              ? FloatingActionButton(
            tooltip: "Add Event",
            backgroundColor: Theme.of(context).colorScheme.primary,
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


                  //change display name
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
                                              content: Text(
                                                "Restart your app",
                                              ),
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


                      //Events button
                      ListTile(
                        leading: Icon(Icons.list),
                        title: Text("Events"),
                        onTap: () {
                          setState(() => tab = Tab.events);
                          Navigator.of(context).pop();
                        },
                      ),


                      //Templates button
                      if (!NewPlatform.isWeb)
                        ListTile(
                          leading: Icon(CupertinoIcons.square_stack),
                          title: Text("Templates"),
                          onTap: () {
                            setState(() => tab = Tab.templates);
                            Navigator.of(context).pop();
                          },
                        ),


                      //Inbox button
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
                              child: Text(
                                (data?['inbox'] as Map?)
                                    ?.entries
                                    .length
                                    .toString() ??
                                    "0",
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() => tab = Tab.inbox);
                            Navigator.of(context).pop();
                          },
                        ),


                      //If user isn't anon than list blocked users
                      if (!(context.read<User?>()?.isAnonymous ?? true))
                        ListTile(
                          leading: Icon(Icons.people_alt),
                          title: Text("Blocked Users"),
                          onTap: () {
                            setState(() => tab = Tab.blocked_users);
                            Navigator.of(context).pop();
                          },
                        ),


                      //if user anon then list link acc
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


                      //Sign out button
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

                      //delete acc button
                      ListTile(
                        leading: Icon(Icons.delete_forever),
                        title: Text('Delete Account'),
                        onTap: () {
                          showPlatformDialog(
                            context: context,
                            builder: (context) => PlatformAlert(
                              title: Text('Are you sure?'),
                              content: Text('This action cannot be reversed, and all data will be lost permanently.'),
                              actions: [
                                PlatformDialogAction(
                                  isDefaultAction: true,
                                  child: Text('Cancel'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                PlatformDialogAction(
                                  isDestructive: true,
                                  child: Text('Delete Account'),
                                  onPressed: () async {



                                    //User? user=context.read<User?>();
                                    final uid = FirebaseAuth.instance.currentUser?.uid;
                                    final email=FirebaseAuth.instance.currentUser?.email;

                                    setState(() => dataModel.events.clear());
                                    dataModel.saveEvents();

                                    //deal with shared events
                                    List<Event> sharedEvents=dataModel.sharedEvents;

                                    for(Event ev in sharedEvents)
                                    {
                                      debugPrint('REEEEEEEEEE $uid');

                                      //temporary variables
                                      TeamTrackUser? firstEditor;
                                      TeamTrackUser? firstViewer;
                                      TeamTrackUser? targetUser;
                                      setState(() => {});

                                      //update users list from firebase
                                      final map = await ev.getRef()?.once();
                                      ev.updateLocal(
                                        json.decode(
                                          json.encode(
                                            map?.snapshot.value,
                                          ),
                                        ),
                                        context,
                                      );
                                      setState(() => {});

                                      List<TeamTrackUser> users = ev.users;
                                      setState(() => {});


                                      if (users.firstWhereOrNull((element) => element.uid == uid)?.role != Role.admin
                                          || users.firstWhereOrNull((element) => element.role==Role.admin&&element.uid!=uid)!=null)
                                      {
                                        await ev.modifyUser(uid:uid, role: null);

                                        //setState(() => {});
                                      }
                                      else if(users.singleOrNull!=null)
                                      {
                                        await ev.getRef()?.remove();
                                        setState(() => {});
                                        //delete event
                                      }
                                      else
                                      {
                                        firstEditor=users.firstWhereOrNull((element) => element.role==Role.editor);
                                        firstViewer=users.firstWhereOrNull((element) => element.role==Role.viewer);
                                        setState(() => {});

                                        if(firstEditor!=null)
                                          targetUser=firstEditor;
                                        else if(firstViewer!=null)
                                          targetUser=firstViewer;
                                        setState(() => {});


                                        await ev.modifyUser(uid: targetUser?.uid, role: Role.admin);

                                        //setState(() => {});

                                        await ev.modifyUser(uid: uid, role: null);

                                        setState(() => {});
                                      }
                                    }

                                      dataModel.saveEvents();
                                      setState(() => {});

                                      /*user?.delete().then((yikes) async
                                        {
                                          await
                                          FirebaseFirestore.instance.collection("users")
                                              .doc(user?.uid)
                                              .delete();
                                        });*/

                                      context
                                          .read<AuthenticationService>()
                                          .signOut();
                                      Navigator.of(context).pop();


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

  void _onPressed() {
    if (NewPlatform.isIOS)
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
      title: Text(
          'New ${_newType == EventType.remote ? 'Remote' : 'In-Person'} Event'),
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
          child: Text('Add'),
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
