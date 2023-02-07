// Profile Picture
import 'package:flutter/material.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/functions/Extensions.dart';

/// Displays a [user]'s profile picture
class PFP extends StatelessWidget {
  const PFP({
    super.key,
    required this.user,
    this.showRole = true,
    this.size = 28,
  });
  final TeamTrackUser user;
  final bool showRole;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        height: size,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            user.photoURL != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(300),
                    child: Image.network(
                      user.photoURL!,
                      height: size,
                    ),
                  )
                : Icon(Icons.person),
            if (showRole) user.role.getIcon(size: (size / 28) * 14),
          ],
        ),
      );
}
