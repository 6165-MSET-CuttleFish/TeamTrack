import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';

class Permissions extends StatefulWidget {
  const Permissions({Key? key, required this.event}) : super(key: key);
  final Event event;
  @override
  _PermissionsState createState() => _PermissionsState();
}

class _PermissionsState extends State<Permissions> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
          children: widget.event.permissions.keys
              .map(
                (user) => ListTile(
                  leading: getIcon(
                    widget.event.permissions[user]?.role ?? Role.viewer,
                  ),
                  title: Text(
                    widget.event.permissions[user]?.displayName ?? "Unknown",
                  ),
                  subtitle: Text(
                    widget.event.permissions[user]?.email ?? "Unknown",
                  ),
                ),
              )
              .toList()),
    );
  }

  Icon getIcon(Role role) {
    switch (role) {
      case Role.viewer:
        return Icon(Icons.visibility);
      case Role.editor:
        return Icon(Icons.edit);
      case Role.admin:
        return Icon(Icons.verified_user);
    }
  }
}
