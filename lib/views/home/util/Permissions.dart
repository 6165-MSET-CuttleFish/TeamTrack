import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PFP.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/functions/Extensions.dart';

class Permissions extends StatefulWidget {
  const Permissions({Key? key, required this.users, required this.ref})
      : super(key: key);
  final List<TeamTrackUser> users;
  final DatabaseReference? ref;
  @override
  _PermissionsState createState() => _PermissionsState();
}

class _PermissionsState extends State<Permissions> {
  @override
  Widget build(BuildContext context) => Column(
        children: widget.users
            .map(
              (user) => ListTile(
                leading: PFP(user: user),
                title: PlatformText(
                  user.displayName ?? "Unknown",
                ),
                subtitle: PlatformText(
                  user.email ?? "Unknown",
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
                  onChanged: (newValue) => setState(
                    () => widget.ref
                        ?.child('${user.id}/role')
                        .set(newValue?.toRep()),
                  ),
                ),
              ),
            )
            .toList(),
      );
}
