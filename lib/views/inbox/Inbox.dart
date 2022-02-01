import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/EmptyList.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/Extensions.dart';

class Inbox extends StatefulWidget {
  const Inbox({Key? key}) : super(key: key);
  @override
  _InboxState createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  late DocumentReference<Map<String, dynamic>> docRef;

  @override
  void initState() {
    super.initState();
    docRef =
        firebaseFirestore.collection('users').doc(context.read<User?>()?.uid);
  }

  @override
  Widget build(BuildContext context) => dataModel.inbox.length == 0
      ? EmptyList()
      : ListView.builder(
          itemCount: dataModel.inbox.length,
          itemBuilder: (context, index) {
            final e = dataModel.inbox[index];
            return Slidable(
              endActionPane: ActionPane(
                // A motion is a widget used to control how the pane animates.
                motion: const StretchMotion(),

                // All actions are defined in the children parameter.
                children: [
                  SlidableAction(
                    icon: Icons.warning,
                    backgroundColor: Colors.yellow,
                    onPressed: (_) {
                      showPlatformDialog(
                        context: context,
                        builder: (BuildContext context) => PlatformAlert(
                          title: PlatformText('Block user'),
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
                              onPressed: () async {
                                await firebaseFirestore.runTransaction(
                                  (transaction) async {
                                    var snapshot =
                                        await transaction.get(docRef);
                                    if (!snapshot.exists) {
                                      throw Exception("User does not exist!");
                                    }
                                    Map newBlocks =
                                        snapshot.data()?['blockedUsers'];
                                    newBlocks[e.sender?.uid] =
                                        e.sender?.toJson();
                                    Map<String, dynamic> newInbox =
                                        snapshot.data()?["inbox"]
                                            as Map<String, dynamic>;
                                    newInbox.removeWhere((key, value) =>
                                        value['senderID'] == e.sender?.uid);
                                    return transaction.update(
                                      docRef,
                                      {
                                        'blockedUsers': newBlocks,
                                        'inbox': newInbox
                                      },
                                    );
                                  },
                                );
                                Navigator.of(context).pop();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Icon(
                          e.type == EventType.remote
                              ? CupertinoIcons.rectangle_stack_person_crop_fill
                              : CupertinoIcons.person_3_fill,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      PlatformText(e.gameName.spaceBeforeCapital())
                    ],
                  ),
                  title: Column(
                    children: [
                      PlatformText(
                        e.name,
                      ),
                      PlatformText(
                        e.sender?.displayName ?? "Guest",
                      ),
                      PlatformText(
                        e.sender?.email ?? "Suspicious Email",
                        style: TextStyle(fontSize: 12),
                      )
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.check,
                          color: Colors.green,
                        ),
                        onPressed: () async {
                          showPlatformDialog(
                            context: context,
                            builder: (_) => PlatformAlert(
                              title: PlatformText('Accept Event'),
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
                                  child: PlatformText('Confirm'),
                                  onPressed: () async {
                                    await firebaseFirestore.runTransaction(
                                      (transaction) async {
                                        var snapshot =
                                            await transaction.get(docRef);
                                        if (!snapshot.exists) {
                                          throw Exception(
                                            "User does not exist!",
                                          );
                                        }
                                        Map<String, dynamic> newInbox =
                                            snapshot.data()?["inbox"]
                                                as Map<String, dynamic>;
                                        newInbox.removeWhere(
                                            (key, value) => key == e.id);
                                        Map<String, dynamic> newEvents =
                                            snapshot.data()?["events"]
                                                as Map<String, dynamic>;
                                        newEvents[e.id] = e.toSimpleJson();
                                        List newTokens =
                                            snapshot.data()?['FCMtokens'];
                                        if (!newTokens
                                                .contains(dataModel.token) &&
                                            dataModel.token != null) {
                                          newTokens.add(dataModel.token!);
                                        }
                                        return transaction.update(
                                          docRef,
                                          {
                                            'events': newEvents,
                                            'inbox': newInbox,
                                            'FCMtokens': newTokens,
                                          },
                                        );
                                      },
                                    );
                                    Navigator.of(context).pop();
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Padding(padding: EdgeInsets.all(5)),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          showPlatformDialog(
                            context: context,
                            builder: (_) => PlatformAlert(
                              title: PlatformText('Delete Event'),
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
                                  isDestructive: true,
                                  child: PlatformText('Confirm'),
                                  onPressed: () async {
                                    await firebaseFirestore.runTransaction(
                                      (transaction) async {
                                        var snapshot =
                                            await transaction.get(docRef);
                                        if (!snapshot.exists) {
                                          throw Exception(
                                              "User does not exist!");
                                        }
                                        Map<String, dynamic> newInbox =
                                            snapshot.data()?["inbox"]
                                                as Map<String, dynamic>;
                                        newInbox.removeWhere(
                                            (key, value) => key == e.id);
                                        List newTokens =
                                            snapshot.data()?['FCMtokens'];
                                        if (!newTokens
                                                .contains(dataModel.token) &&
                                            dataModel.token != null) {
                                          newTokens.add(dataModel.token!);
                                        }
                                        return transaction.update(
                                          docRef,
                                          {
                                            'inbox': newInbox,
                                            'FCMtokens': newTokens,
                                          },
                                        );
                                      },
                                    );
                                    Navigator.of(context).pop();
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
}
