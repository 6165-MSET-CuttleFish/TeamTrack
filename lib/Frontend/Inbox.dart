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
  late DocumentReference docRef;
  @override
  Widget build(BuildContext context) {
    docRef =
        firebaseFirestore.collection('users').doc(context.read<User?>()?.uid);
    return FutureBuilder<DocumentSnapshot>(
      future: docRef.get(),
      builder: (context, query) {
        if (query.data != null)
          return ListView(
            children: (query.data?['inbox'] as List<Map>?)
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
                                e['senderName'] ?? "Guest",
                              ),
                            ],
                          ),
                          title: Column(
                            children: [
                              Text(
                                e['name'],
                              ),
                              Text(e['senderEmail'])
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
                                onPressed: () {
                                  var doc = e;
                                  doc['receiveDate'] = Timestamp.now();
                                  firebaseFirestore
                                      .runTransaction(
                                        (transaction) async {
                                          // Get the document
                                          DocumentSnapshot snapshot =
                                              await transaction.get(docRef);

                                          if (!snapshot.exists) {
                                            throw Exception(
                                                "User does not exist!");
                                          }

                                          List<Map> newEventsList =
                                              (snapshot.data() as Map)["Events"]
                                                      [Statics.gameName]
                                                  as List<Map>;
                                          newEventsList.add(doc);
                                          List<Map> newInbox = (snapshot.data()
                                                  as Map)["Inbox"]
                                              [Statics.gameName] as List<Map>;
                                          newInbox.removeWhere((element) =>
                                              element['id'] == e['id']);
                                          // Perform an update on the document
                                          transaction.update(
                                            docRef,
                                            {
                                              'Events': newEventsList,
                                              'Inbox': newInbox,
                                            },
                                          );
                                          return doc;
                                        },
                                      )
                                      .then((value) => print(
                                          "Follower count updated to $value"))
                                      .catchError((error) => print(
                                          "Failed to update user followers: $error"));
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  firebaseFirestore.runTransaction(
                                    (transaction) async {
                                      // Get the document
                                      DocumentSnapshot snapshot =
                                          await transaction.get(docRef);

                                      if (!snapshot.exists) {
                                        throw Exception("User does not exist!");
                                      }
                                      List<Map> newInbox =
                                          (snapshot.data() as Map)["Inbox"]
                                              [Statics.gameName] as List<Map>;
                                      newInbox.removeWhere((element) =>
                                          element['id'] == e['id']);
                                      // Perform an update on the document
                                      transaction.update(
                                        docRef,
                                        {
                                          'Inbox': newInbox,
                                        },
                                      );
                                      return e;
                                    },
                                  );
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
        else
          return PlatformProgressIndicator();
      },
    );
  }
}
