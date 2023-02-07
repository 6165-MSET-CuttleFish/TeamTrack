import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/users/PFP.dart';
import 'package:teamtrack/models/AppModel.dart';

/// Displays [users] profile pictures in a row
class UsersRow extends StatelessWidget {
  const UsersRow({
    super.key,
    required this.users,
    this.showRole = false,
    this.size = 28,
  });
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
