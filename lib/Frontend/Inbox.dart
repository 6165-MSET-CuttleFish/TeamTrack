import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/score.dart';

class Inbox extends StatefulWidget {
  const Inbox({Key? key}) : super(key: key);
  @override
  _InboxState createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
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
                      (e) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: Icon(
                                  getTypeFromString(e['type']) ==
                                          EventType.remote
                                      ? CupertinoIcons
                                          .rectangle_stack_person_crop_fill
                                      : CupertinoIcons.person_3_fill,
                                  color: Theme.of(context).accentColor,
                                ),
                              ),
                              Text(
                                e['name'] ?? "Unnamed Event",
                              ),
                            ],
                          ),
                          title: Column(
                            children: [
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
                                        throw Exception("User does not exist!");
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
                                      return transaction.update(
                                        docRef,
                                        {
                                          'events': newEvents,
                                          'inbox': newInbox,
                                        },
                                      );
                                    },
                                  );
                                  setState(() {});
                                },
                              ),
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
                                        throw Exception("User does not exist!");
                                      }
                                      Map<String, dynamic> newInbox =
                                          snapshot.data()?["inbox"]
                                              as Map<String, dynamic>;
                                      newInbox.removeWhere(
                                          (key, value) => key == e['id']);
                                      return transaction.update(
                                        docRef,
                                        {
                                          'inbox': newInbox,
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
