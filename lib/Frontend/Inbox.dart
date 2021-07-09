import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/score.dart';

final DocumentReference docRef =
    firebaseFirestore.collection('inboxes').doc(Statics.gameName);

class Inbox extends StatefulWidget {
  const Inbox({Key? key}) : super(key: key);
  @override
  _InboxState createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: docRef
            .collection(context.read<User?>()?.email ?? '')
            .orderBy("sendDate", descending: true)
            .limit(10)
            .get(),
        builder: (context, query) {
          if (query.data != null)
            return ListView(
              children: query.data?.docs
                      .map(
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
                                  onPressed: () async {
                                    var doc = e.data();
                                    doc['receiveDate'] = Timestamp.now();
                                    final documentReference = firebaseFirestore
                                        .collection('users')
                                        .doc(context.read<User?>()?.uid);
                                    firebaseFirestore
                                        .runTransaction((transaction) async {
                                          // Get the document
                                          DocumentSnapshot snapshot =
                                              await transaction
                                                  .get(documentReference);

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
                                          newInbox.remove(e.data());
                                          // Perform an update on the document
                                          transaction
                                              .update(documentReference, {
                                            'Events': newEventsList,
                                            'Inbox': newInbox,
                                          });
                                          return doc;
                                        })
                                        .then((value) => print(
                                            "Follower count updated to $value"))
                                        .catchError((error) => print(
                                            "Failed to update user followers: $error"));
                                    firebaseFirestore
                                        .collection('users')
                                        .doc(context.read<User?>()?.uid)
                                        .collection(Statics.gameName);
                                    var event = Event(
                                        gameName:
                                            e['gameName'] ?? Statics.gameName,
                                        name: e['name'],
                                        type: getTypeFromString(e['type']));
                                    event.id = e['id'];
                                    event.shared = true;
                                    dataModel.events.add(event);
                                    dataModel.saveEvents();
                                    docRef
                                        .collection(
                                            context.read<User?>()?.email ?? '')
                                        .doc(e.id)
                                        .delete();
                                    setState(() {});
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    docRef
                                        .collection(
                                            context.read<User?>()?.email ?? '')
                                        .doc(e.id)
                                        .delete();
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
          else
            return PlatformProgressIndicator();
        },
      );
}
