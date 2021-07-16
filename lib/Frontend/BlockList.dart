import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/score.dart';

class BlockList extends StatefulWidget {
  const BlockList({Key? key}) : super(key: key);
  @override
  _BlockList createState() => _BlockList();
}

class _BlockList extends State<BlockList> {
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
              (query.data?['blockedUsers'] as Map<String, dynamic>?)
                  ?.values
                  .toList();
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
                          leading: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Icon(Icons.person),
                          ),
                          title: Text(
                            e,
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.person_remove_alt_1_rounded,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              showPlatformDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    PlatformAlert(
                                  title: Text('Unblock user'),
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
                                            newBlocks.removeWhere(
                                                (key, value) => value == e);
                                            return transaction.update(
                                              docRef,
                                              {
                                                'blockedUsers': newBlocks,
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
