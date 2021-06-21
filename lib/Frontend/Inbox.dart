import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/score.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Inbox extends StatefulWidget {
  const Inbox({Key? key}) : super(key: key);
  @override
  _InboxState createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  QuerySnapshot<Map<String, dynamic>>? query;
  bool isLoaded = false;
  final docRef = firebaseFirestore.collection('inboxes').doc(Statics.gameName);
  @override
  Widget build(BuildContext context) {
    if (!isLoaded) getList();
    if (isLoaded) {
      return ListView(
        children: query?.docs
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
                              getTypeFromString(e['type']) == EventType.remote
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
                              Icons.thumb_up_alt,
                              color: Colors.green,
                            ),
                            onPressed: () async {
                              firebaseFirestore
                                  .collection('users')
                                  .doc(context.read<User?>()?.email)
                                  .collection(Statics.gameName)
                                  .add(
                                {
                                  'id': e['id'],
                                  'name': e['name'],
                                  'type': e['type'],
                                },
                              );
                              var event = Event(
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
                              getList();
                              setState(() {});
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.thumb_down_alt,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              docRef
                                  .collection(
                                      context.read<User?>()?.email ?? '')
                                  .doc(e.id)
                                  .delete();
                              getList();
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
    }

    return PlatformProgressIndicator();
  }

  void getList() async {
    query = await docRef.collection(context.read<User?>()?.email ?? '').get();
    isLoaded = true;
  }
}
