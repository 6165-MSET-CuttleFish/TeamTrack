import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:TeamTrack/MatchView.dart';
import 'package:tuple/tuple.dart';
import 'backend.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:TeamTrack/PlatformGraphics.dart';
import 'package:TeamTrack/EventView.dart';

class EventsList extends StatefulWidget {
  EventsList({Key key, this.dataModel}) : super(key: key);
  DataModel dataModel;
  @override
  _EventsList createState() => _EventsList(dataModel: dataModel);
}

class _EventsList extends State<EventsList>{
  _EventsList({this.dataModel});
  DataModel dataModel;
  List<Widget> localEvents () {
    return dataModel.localEvents.map((e) => ListTileTheme(
      iconColor: Theme.of(context).primaryColor,
        child: ListTile(
          leading: Icon(Icons.all_inbox_rounded),
          trailing: Icon(Icons.account_box_sharp),
          subtitle: Text('Some time in the future'),
          title: Text(e.name),
            onTap: () {
              if(Platform.isIOS) {
                Navigator.push(context, CupertinoPageRoute(builder: (context) => EventView(event: e,)));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => EventView(event: e,)));
              }
            },
    ))).toList();
  }


  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
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