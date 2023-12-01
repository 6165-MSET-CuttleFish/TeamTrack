import 'package:flutter/services.dart';
import 'package:teamtrack/components/misc/Collapsible.dart';
import 'package:teamtrack/components/misc/EmptyList.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/components/scores/ScoreCard.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/change/ChangeList.dart';
import 'package:teamtrack/views/home/match/MatchList.dart';
import 'package:teamtrack/views/home/match/MatchView.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teamtrack/components/statistics/CheckList.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:teamtrack/components/AutonomousDrawingTool.dart';

class AutonDrawer extends StatefulWidget {
  AutonDrawer({
    super.key,
    required this.team,
    required this.event,
    this.isSoleWindow = true,
  });
  final Team team;
  final Event event;
  final bool isSoleWindow;
  @override
  State<AutonDrawer> createState() => _AutonDrawerState(team,event);
}

var scopeMarks = <String>["Path Side","Both_Side", "Red_Side", "Blue_Side"];
String dropdownScope=scopeMarks.first;
String infoBubble=
    '\nOur autonomous drawing feature is an integrated mark-up tool that allows you to '
    'track the autonomous paths of other teams, privately, with teammates you '
    'are collaborating with.\n';

class _AutonDrawerState extends State<AutonDrawer> {
  _AutonDrawerState(this._team, this._event);
  Dice _dice = Dice.none;
  Team _team;
  Event _event;

  late AutonPainter painter;

  @override
  void initState() {
    painter=new AutonPainter(team: _team,event: _event,);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: NewPlatform.isAndroid
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Text(_team.name,
                  style: widget.team.number == '6165'
                      ? TextStyle(fontSize: 20, fontFamily: 'Revival')
                      : null),
              Text(
                _team.number,
                style: widget.team.number == '6165'
                    ? TextStyle(fontSize: 12, fontFamily: 'Revival Gothic')
                    : Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children:[

            DropdownButton<Dice>(
              value: _dice,
              icon:   Icon(Icons.height_rounded,
                  color: Colors.white),
              iconSize: 24,
              elevation: 16,
              underline: Container(
                height: 0.5,
                color: Colors.deepPurple,
              ),
              onChanged: (newValue) {
                HapticFeedback.lightImpact();
                setState(() {
                  _dice = newValue!;
                });
              },
              items: DiceExtension
                  .getAll()
                  .map(
                    (value) => DropdownMenuItem<Dice>(
                  value: value,
                  child: Text(value?.toVal(Statics.gameName) ?? "All Cases",
                    style: Theme.of(context).textTheme.titleMedium?.apply(color: Colors.white),
                    textScaleFactor: .9,),
                ),
              )
                  .toList(),
            ),
            ],),
            IconButton(
              tooltip: "Configure",
              icon: Icon(Icons.settings),
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (context) => CheckList(
                  state: this,
                  statConfig: widget.event.statConfig,
                  event: widget.event,
                  showSorting: false,
                ),
              ),
            ),
            if (widget.event.type == EventType.remote)
              IconButton(
                icon: Icon(Icons.list_alt),
                tooltip: 'Robot Iterations',
                onPressed: () => Navigator.of(context).push(
                  platformPageRoute(
                    builder: (context) => ChangeList(
                      team: _team,
                      event: widget.event,
                    ),
                  ),
                ),
              ),
          ],
        )
  ,
        body: StreamBuilder<DatabaseEvent>(
          stream: widget.isSoleWindow ? widget.event.getRef()?.onValue : null,
          builder: (context, eventHandler) {
            _team = widget.team;
            return ListView(
              children: [
                Padding(padding: EdgeInsets.all(10.0),
                  child: Column(
                    children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: Text('Autonomous Drawing Tool', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                  ),
                ),Container(
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.info),
                        Spacer(flex:1),
                        SizedBox(
                          width: 350,
                          child: Center(
                            child: Text(infoBubble),
                          ),
                        )]
                      )
            ),

            Container(
                  height: 300,
                  child: painter,
                ),
                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: Text('Previous Paths', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                Container(
                    width: 300,
                    child: Column(
                    children:[
                    Container(
                    //Put in the gallery stuff
                    child: FutureBuilder(
                    future: FirebaseStorage.instance.ref().child('${_event.id} - ${_team.number} - ${dropdownScope}.png').getDownloadURL(),
                builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    return Container(
                      height: 300,
                      child: Image.network(snapshot.data!, fit: BoxFit.cover,),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      !snapshot.hasData) {
                    return Container(
                      height: 0,
                    );
                  }
                  return Container(
                    height: 0,
                  );
                },
                  )
                  )
                  ]
                  )),
                Container(
              child: Row(
                  children: <Widget>[
              const Spacer(flex: 1),
             DropdownButton(
                value: dropdownScope,
                items: scopeMarks.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value) {
                    // This is called when the user selects an item.
                    setState(() {
                      dropdownScope = value!;
                    });
                }),
                const Spacer(flex: 1),
                ]))]
                  ),)
                ],
            );
          },
        ),
      );

}
