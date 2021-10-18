import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/functions/Functions.dart';
class Inbox extends StatefulWidget {
  const Inbox({Key? key}) : super(key: key);
  @override
  _InboxState createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  final slider = SlidableStrechActionPane();
  @override
  Widget build(BuildContext context) {
    var docRef =
        firebaseFirestore.collection('users').doc(context.read<User?>()?.uid);
    return FutureBuilder<DocumentSnapshot>(
      future: docRef.get(),
      builder: (context, query) {
        if (query.data != null) {
          var queryResult =
              (query.data?['inbox'] as Map<String, dynamic>?)?.values.toList();
          queryResult?.sort(
              (a, b) => (a['sendTime'] as Timestamp).compareTo(b['sendTime']));
          return ListView(
            children: queryResult
                    ?.map(
                      (e) => Slidable(
                        actionPane: slider,
                        secondaryActions: [
                          IconSlideAction(
                            icon: Icons.warning,
                            color: Colors.yellow,
                            onTap: () {
                              showPlatformDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    PlatformAlert(
                                  title: Text('Block user'),
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
                                        await firebaseFirestore.runTransaction(
                                          (transaction) async {
                                            var snapshot =
                                                await transaction.get(docRef);
                                            if (!snapshot.exists) {
                                              throw Exception(
                                                  "User does not exist!");
                                            }
                                            Map newBlocks = snapshot
                                                .data()?['blockedUsers'];
                                            newBlocks[e['senderID']] =
                                                e['senderEmail'];
                                            Map<String, dynamic> newInbox =
                                                snapshot.data()?["inbox"]
                                                    as Map<String, dynamic>;
                                            newInbox.removeWhere((key, value) =>
                                                value['senderID'] ==
                                                e['senderID']);
                                            return transaction.update(
                                              docRef,
                                              {
                                                'blockedUsers': newBlocks,
                                                'inbox': newInbox
                                              },
                                            );
                                          },
                                        );
                                        dataModel.saveEvents();
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
                                    getTypeFromString(e['type']) ==
                                            EventType.remote
                                        ? CupertinoIcons
                                            .rectangle_stack_person_crop_fill
                                        : CupertinoIcons.person_3_fill,
                                    color: Theme.of(context).accentColor,
                                  ),
                                ),
                                Text((e['gameName'] as String)
                                    .spaceBeforeCapital())
                              ],
                            ),
                            title: Column(
                              children: [
                                Text(
                                  e['name'] ?? "Unnamed Event",
                                ),
                                Text(
                                  e['senderName'] ?? "Guest",
                                ),
                                Text(
                                  e['senderEmail'] ?? "Suspicious Email",
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
                                            (key, value) => key == e['id']);
                                        Map<String, dynamic> newEvents =
                                            snapshot.data()?["events"]
                                                as Map<String, dynamic>;
                                        newEvents[e['id']] = e;
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
                                    setState(() {});
                                  },
                                ),
                                Padding(padding: EdgeInsets.all(5)),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
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
                                            (key, value) => key == e['id']);
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
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList() ??
                [Text('')],
          );
        } else
          return PlatformProgressIndicator();
      },
    );
  }
}
