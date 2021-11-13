import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PFP.dart';
import 'package:teamtrack/models/AppModel.dart';

class UsersRow extends StatefulWidget {
  const UsersRow({Key? key, required this.users, this.showRole = false}) : super(key: key);
  final List<TeamTrackUser> users;
  final bool showRole;
  @override
  _UsersRowState createState() => _UsersRowState();
}

class _UsersRowState extends State<UsersRow> {
  @override
  Widget build(BuildContext context) => RowSuper(
        invert: true,
        children: widget.users
            .map(
              (user) => PFP(
                user: user,
                showRole: widget.showRole,
              ),
            )
            .toList(),
        innerDistance: -10.0,
      );
}
