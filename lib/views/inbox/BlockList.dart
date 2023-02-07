import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamtrack/components/users/PFP.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/components/misc/EmptyList.dart';

class BlockList extends StatefulWidget {
  const BlockList({super.key});
  @override
  State<BlockList> createState() => _BlockList();
}

class _BlockList extends State<BlockList> {
  late DocumentReference<Map<String, dynamic>> docRef;

  void initState() {
    super.initState();
    docRef =
        firebaseFirestore.collection('users').doc(context.read<User?>()?.uid);
  }

  @override
  Widget build(BuildContext context) {
    if (dataModel.blockedUsers.length == 0) {
      return EmptyList();
    }
    return ListView.builder(
      itemCount: dataModel.blockedUsers.length,
      itemBuilder: (context, index) {
        final e = dataModel.blockedUsers[index];
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey,
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: PFP(
                user: e,
                showRole: false,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.displayName ?? 'Unknown',
                ),
                Text(
                  e.email ?? '',
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.person_remove_alt_1_rounded,
                color: Colors.red,
              ),
              onPressed: () {
                showPlatformDialog(
                  context: context,
                  builder: (BuildContext context) => PlatformAlert(
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
                              var snapshot = await transaction.get(docRef);
                              if (!snapshot.exists) {
                                throw Exception("User does not exist!");
                              }
                              Map newBlocks = snapshot.data()?['blockedUsers'];
                              newBlocks
                                  .removeWhere((key, value) => key == e.uid);
                              return transaction.update(
                                docRef,
                                {
                                  'blockedUsers': newBlocks,
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
          ),
        );
      },
    );
  }
}
