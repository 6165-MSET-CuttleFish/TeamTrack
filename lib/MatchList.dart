import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:TeamTrack/backend.dart';
import 'package:TeamTrack/score.dart';
import 'package:tuple/tuple.dart';
import 'dart:io' show Platform;

class MatchList extends StatefulWidget {
  MatchList({Key key, this.matches}) : super(key: key);
  List<Match> matches;

  @override
  _MatchList createState() => _MatchList(matches);
}
class _MatchList extends State<MatchList> {
  List<Match> _matches;

  _MatchList(List<Match> matches) {
    this._matches = matches;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(child: NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled){
        return <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: Text('Events'),
          )
        ];
      },
      body: Column(
        children: [
          ListTile(
            title: Text('Hello World!'),
          )
        ],
      ),
    ));
  }
}