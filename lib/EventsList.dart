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
          leading: Icon(Icons.all_inbox_rounded, color: Theme.of(context).accentColor,),
          trailing: Icon(Icons.account_box_sharp, color: Theme.of(context).accentColor,),
          title: Text(e.name),
            onTap: () {
              if(Platform.isIOS) {
                Navigator.push(context, CupertinoPageRoute(builder: (context) => EventView(event: e,)));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => EventView(event: e,)));
              }
            },
    )
    )).toList();
  }

  String _newName;
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
                      onPressed: _onPressed,
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
          onPressed: _onPressed,
        ),
      );
    }
  }
  void _onPressed(){
    showDialog(
        context: context,
        builder: (BuildContext context) => PlatformAlert(
          title: Text('New Event'),
          content: PlatformTextField(
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            onChanged: (String input){
              _newName = input;
            },
          ),
          actions: [
            PlatformDialogAction(
              isDefaultAction: true,
              child: Text('Cancel'),
              onPressed: () {
                _newName = '';
                Navigator.of(context).pop();
              },
            ),
            PlatformDialogAction(
              isDefaultAction: false,
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  if(_newName.isNotEmpty)
                    dataModel.localEvents.add(Event(name: _newName));
                  _newName = '';
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        )
    );
  }
}