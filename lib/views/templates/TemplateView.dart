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

  _getTeams() {
    APIKEYS.getTeams(widget.event_key).then((response) {
      setState(() {
        bod = (json.decode(response.body)
            .toList());
        //print(bod);
      });
    });
  }
  _getInfo() {
    APIKEYS.getInfo(widget.event_key).then((response) {
      setState(() {
        data = (json.decode(response.body)
            .toList());
        print(data);
      });
    });
  }
  initState() {
    super.initState();
    _getTeams();
    _getInfo();
  }

  Widget build(BuildContext context) =>
      Scaffold(
          appBar: AppBar(
            title: Text(widget.event_name)
            ,
            titleTextStyle: TextStyle(fontSize: 20),
            backgroundColor: Theme
                .of(context)
                .colorScheme
                .primary,
          ),
          body: Container(
            child:Column(
  children: <Widget>[
    Text('Dates: '+ data[0]['start_date'].substring(0,10)+' - '+data[0]['end_date'].substring(0,10)),
    Text('Location: '+data[0]['city']),
    Text('Type: '+data[0]['event_type_key']),
    Text('Division: '+data[0]['division_name'].toString()),
    Expanded(
             child: ListView.builder(
                itemCount: bod.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                        title: Text(bod[index]['team']['team_name_short'].toString()),
                        subtitle: Text(bod[index]['team_number'].toString()),
                    ),
                  );
                }
            ),
          ),
    OutlinedButton(
      onPressed: (){

    },
      child: Text('Create Event')
    ),

      ]
            ),
          ),

      );
}

