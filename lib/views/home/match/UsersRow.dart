import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PFP.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/functions/Extensions.dart';

class UsersRow extends StatefulWidget {
  const UsersRow({Key? key, required this.users}) : super(key: key);
  final List<TeamTrackUser> users;
  @override
  _UsersRowState createState() => _UsersRowState();
}

class _UsersRowState extends State<UsersRow> {
  @override
  Widget build(BuildContext context) => RowSuper(
        children: widget.users.map((user) => PFP(user: user)).toList(),
        innerDistance: -10.0,
      );
}
