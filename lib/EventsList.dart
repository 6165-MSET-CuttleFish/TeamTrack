import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:TeamTrack/MatchView.dart';
import 'package:tuple/tuple.dart';
import 'backend.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:TeamTrack/PlatformGraphics.dart';

class EventsList extends StatefulWidget {
  EventsList({Key key, this.dataModel}) : super(key: key);
  DataModel dataModel;
  @override
  _EventsList createState() => _EventsList(dataModel: dataModel);
}

class _EventsList extends State<EventsList>{
  _EventsList({this.dataModel});
  DataModel dataModel;
  List<ListTile> localEvents () {
    return dataModel.localEvents.map((e) => ListTile(
      leading: Icon(Icons.computer_rounded),
      trailing: Icon(Icons.account_box_sharp),
      subtitle: Text('Some time in the future'),
      title: Text(e.name),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => MatchView(match: Match.defaultMatch(EventType.local),)));
        },
    )).toList();
  }


  @override
  Widget build(BuildContext context) {
    if (true) {
      return CupertinoPageScaffold(
          child: SafeArea(
              child: Scaffold(
              body: CustomScrollView(
                slivers: [
                  CupertinoSliverNavigationBar(
                    largeTitle: Text('Events'),
                    previousPageTitle: 'Events',
                    trailing: CupertinoButton(
                      child: Text('Add'),
                      onPressed: () {
                        setState(() {
                          dataModel.localEvents.add(Event(name: 'ok'));
                        });
                      },
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                        localEvents()
                    ),
                  ),
                ],
              )
          )
          )
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Events'),
        ),
        body: SafeArea(
          child: ListView(
            children: localEvents(),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            setState(() {
              dataModel.localEvents.add(Event(name: 'ok'));
            });
          },
        ),
      );
    }
  }
}