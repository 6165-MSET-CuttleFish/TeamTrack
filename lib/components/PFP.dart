import 'package:flutter/material.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/functions/Extensions.dart';

class PFP extends StatelessWidget {
  const PFP({Key? key, required this.user, this.showRole = true})
      : super(key: key);
  final TeamTrackUser user;
  final bool showRole;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.bottomRight,
        children: [
          user.photoURL != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(300),
                  child: Image.network(
                    user.photoURL!,
                    height: 28,
                  ),
                )
              : Icon(
                  Icons.person,
                ),
          if (showRole) user.role.getIcon(),
        ],
      );
}
