import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/PFP.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
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
  final slider = SlidableDrawerActionPane();
  @override
  Widget build(BuildContext context) => ListView(
        children: widget.users
            .map((user) => Slidable(
                  actionPane: slider,
                  secondaryActions: [
                    IconSlideAction(
                      onTap: widget.event.role == Role.admin
                          ? () {
                              showPlatformDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    PlatformAlert(
                                  title: PlatformText('Remove User'),
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
                                      onPressed: () {
                                        setState(
                                          () => widget.ref
                                              ?.child('${user.uid}')
                                              .remove(),
                                        );
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }
                          : null,
                      icon: Icons.delete,
                      color: Colors.red,
                    )
                  ],
                  child: ListTile(
                    leading: PFP(user: user),
                    title: PlatformText(
                      user.displayName ?? "Unknown",
                    ),
                    subtitle: PlatformText(
                      user.email ?? "Unknown",
                      style: Theme.of(context).textTheme.caption,
                    ),
                    trailing: DropdownButton<Role>(
                      value: user.role,
                      items: Role.values
                          .map(
                            (e) => DropdownMenuItem<Role>(
                              child: PlatformText(
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
