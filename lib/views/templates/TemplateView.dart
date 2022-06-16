import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/views/LandingPage.dart' as LandingPage;
import 'package:teamtrack/views/home/match/MatchConfig.dart';
import 'package:teamtrack/views/home/match/MatchList.dart';
import 'package:teamtrack/components/CheckList.dart';
import 'package:teamtrack/views/home/team/TeamList.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:teamtrack/functions/Statistics.dart';

import '../../api/APIKEYS.dart';

class TemplateView extends StatefulWidget {
  TemplateView({
    Key? key,
    required this.event_key,
    required this.event_name,
    this.isPreview = false,
  }) : super(key: key);
  final String event_key;
  final String event_name;
  final bool isPreview;

  @override
  _TemplateView createState() => _TemplateView();
}

class _TemplateView extends State<TemplateView> {
  List bod = [];
  List data = [];

  EventType? _newType;
  String? _newName;
  _getTeams() {
    APIKEYS.getTeams(widget.event_key).then((response) {
      setState(() {
        bod = (json.decode(response.body).toList());
        //print(bod);
      });
    });
  }

  _getInfo() {
    APIKEYS.getInfo(widget.event_key).then((response) {
      setState(() {
        data = (json.decode(response.body).toList());
        print(data);
      });
    });
  }

  initState() {
     _getTeams();
     _getInfo();
    super.initState();
  }

  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.event_name),
          titleTextStyle: TextStyle(fontSize: 20),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: data.isEmpty ? Center(child: PlatformProgressIndicator()) :Container(
          child: Column(children:[
            Text('Dates: ' +
                data[0]['start_date'].substring(0, 10) +
                ' - ' +
                data[0]['end_date'].substring(0, 10)),
            Text('Location: ' + data[0]['city']),
            Text('Type: ' + data[0]['event_type_key']),
            data[0]['division_name']?.let((that) => Text('Division: ' +that.toString())),
            Expanded(
              child:  ListView.builder(
                  itemCount: bod.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        title: Text(
                            bod[index]['team']['team_name_short'].toString()),
                        subtitle: Text(bod[index]['team_number'].toString()),
                      ),
                    );
                  }),
            ),
            OutlinedButton(onPressed: () {
              _newType = EventType.local;
              _newName = widget.event_name;
              dataModel.events.add(Event(

                name: _newName ?? Statics.gameName,
                type: _newType ?? EventType.remote,
                gameName: Statics.gameName,
                event_key: widget.event_key,
              ));
              for(var x in bod){
                String _newName = x['team']['team_name_short'].toString();
                String _newNumber = x['team_number'].toString();
                dataModel.events[dataModel.events.length-1].addTeam(Team(_newNumber, _newName),);
              }
              dataModel.saveEvents();
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(milliseconds: 1000),
                    content: Text('Event Created'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ));
            }, child: Text('Create Event')),
          ].whereType<Widget>().toList()),
        ),
      );
}
