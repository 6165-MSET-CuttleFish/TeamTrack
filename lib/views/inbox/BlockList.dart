import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/PFP.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/components/EmptyList.dart';

class BlockList extends StatefulWidget {
  const BlockList({Key? key}) : super(key: key);
  @override
  _BlockList createState() => _BlockList();
}

class _BlockList extends State<BlockList> {
  final slider = SlidableStrechActionPane();
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
                PlatformText(
                  e.displayName ?? 'Unknown',
                ),
                PlatformText(
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
                    title: PlatformText('Unblock user'),
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
