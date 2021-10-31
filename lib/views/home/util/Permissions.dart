import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PFP.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/Extensions.dart';

class Permissions extends StatefulWidget {
  const Permissions({Key? key, required this.event}) : super(key: key);
  final Event event;
  @override
  _PermissionsState createState() => _PermissionsState();
}

class _PermissionsState extends State<Permissions> {
  @override
  Widget build(BuildContext context) => Column(
        children: widget.event.users
            .map(
              (user) => ListTile(
                leading: PFP(user: user),
                title: Text(
                  user.displayName ?? "Unknown",
                ),
                subtitle: Text(
                  user.email ?? "Unknown",
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
                  onChanged: (newValue) => setState(
                    () => widget.event
                        .getRef()
                        ?.child('Permissions/${user.id}/role')
                        .set(newValue?.toRep()),
                  ),
                ),
              ),
            )
            .toList(),
      );
}
