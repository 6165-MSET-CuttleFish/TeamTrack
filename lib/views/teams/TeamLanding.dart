import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/APIMethods.dart';
import 'package:skeletons/skeletons.dart';
class TeamLanding extends StatefulWidget {
  TeamLanding({Key? key, this.onTap}) : super(key: key);
  final void Function(Event)? onTap;
  @override
  _TeamLanding createState() => _TeamLanding();
}
class _TeamLanding extends State<TeamLanding> {

  Widget build(BuildContext context) {
    return Scaffold(

    );
  }
}