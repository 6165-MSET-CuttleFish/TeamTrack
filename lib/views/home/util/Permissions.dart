import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/users/PFP.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/GameModel.dart';

class Permissions extends StatefulWidget {
  const Permissions(
      {Key? key,
      required this.users,
      required this.ref,
      this.currentUser,
      required this.event})
      : super(key: key);
  final List<TeamTrackUser> users;
  final TeamTrackUser? currentUser;
  final Database.DatabaseReference? ref;
  final Event event;
  @override
  _PermissionsState createState() => _PermissionsState();
}

class _PermissionsState extends State<Permissions> {
  @override
  Widget build(BuildContext context) => ListView(
        children: widget.users
            .map((user) => Slidable(
                  endActionPane: ActionPane(
                    // A motion is a widget used to control how the pane animates.
                    motion: const StretchMotion(),
                    children: [
                      SlidableAction(
                        onPressed: widget.event.role == Role.admin
                            ? (_) {
                                showPlatformDialog(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      PlatformAlert(
                                    title: Text('Remove User'),
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
                                        onPressed: () {
                                          widget.ref
                                              ?.child('${user.uid}')
                                              .remove();
                                          setState(() => {});
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null,
                        icon: Icons.delete,
                        backgroundColor: Colors.red,
                      )
                    ],
                  ),
                  child: ListTile(
                    leading: PFP(user: user),
                    title: Text(
                      user.displayName ?? "Unknown",
                    ),
                    subtitle: Text(
                      user.email ?? "Unknown",
                      style: Theme.of(context).textTheme.caption,
                    ),
                    trailing: DropdownButton<Role>(
                      value: user.role,
                      items: Role.values
                          .map(
                            (e) => DropdownMenuItem<Role>(
                              child: Text(
                                e.name(),
                              ),
                              value: e,
                            ),
                          )
                          .toList(),
                      onChanged: (widget.event.role == Role.admin &&
                              widget.currentUser?.uid != user.uid)
                          ? (newValue) {
                              HapticFeedback.lightImpact();
                              widget.ref
                                  ?.child('${user.uid}/role')
                                  .set(newValue?.toRep());
                              setState(() {});
                            }
                          : null,
                    ),
                  ),
                ))
            .toList(),
      );
}
