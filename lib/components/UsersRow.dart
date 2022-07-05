import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PFP.dart';
import 'package:teamtrack/models/AppModel.dart';

class UsersRow extends StatelessWidget {
  const UsersRow({
    Key? key,
    required this.users,
    this.showRole = false,
    this.size = 28,
  }) : super(key: key);
  final List<TeamTrackUser> users;
  final bool showRole;
  final double size;
  @override
  Widget build(BuildContext context) => RowSuper(
        invert: true,
        children: users
            .map(
              (user) => PFP(
                user: user,
                showRole: showRole,
                size: size,
              ),
            )
            .toList(),
        innerDistance: -10.0,
      );
}
