import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                      leading: Text(
                        e['authorName'],
                      ),
                      title: Column(
                        children: [
                          Text(
                            e['name'],
                          ),
                          Text(e['authorEmail'])
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
                            onPressed: () {
                              docRef
                                  .collection(
                                      context.read<User?>()?.email ?? '')
                                  .doc(e.id)
                                  .delete();
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.thumb_down_alt,
                              color: Colors.red,
                            ),
                            onPressed: () {},
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
    return CircularProgressIndicator();
  }

  void getList() async {
    query = await docRef.collection(context.read<User?>()?.email ?? '').get();
    isLoaded = true;
  }
}
