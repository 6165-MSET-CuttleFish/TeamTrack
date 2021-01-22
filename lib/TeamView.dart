import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:TeamTrack/MatchView.dart';
import 'package:tuple/tuple.dart';
import 'backend.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:TeamTrack/PlatformGraphics.dart';

class TeamView extends StatefulWidget {
    TeamView({Key key, this.team}) : super(key: key);

    final Team team;

    @override
    _TeamView createState() => _TeamView();
}
class _TeamView extends State<TeamView>{
  int _x = 0;
  @override
  Widget body(){
   return
     ListView(
     children: [
       Text('Timeline', style: Theme.of(context).textTheme.headline4,),
       Padding(
         padding: EdgeInsets.all(10),
       ),
       Row(
         mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          LineChart(
              LineChartData(
                  minX: 0,
                  maxX: 8,
                  minY: 0,
                  maxY: 7,
                  backgroundColor: Theme.of(context).canvasColor,
                  lineBarsData: [LineChartBarData(
                      spots: [
                        FlSpot(0, 3),
                        FlSpot(2, 2),
                      ],
                      colors: [Colors.green, Colors.blue],
                      isCurved: true,
                      preventCurveOverShooting: true,
                      barWidth: 5,
                      shadow: Shadow(color: Colors.green,
                          blurRadius: 5)
                  ), LineChartBarData(
                      spots: [
                        FlSpot(0, 5),
                        FlSpot(2, 3),
                        FlSpot(3, 7),
                        FlSpot(4, 1),
                      ],
                      colors: [Colors.deepPurple, Colors.blue],
                      isCurved: true,
                      preventCurveOverShooting: true,
                      barWidth: 5,
                      shadow: Shadow(color: Colors.green,
                          blurRadius: 5)
                  )]
              )
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
          )
        ],
       ),
       
            MaterialButton(
            child: Text('Okay'),
            onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MatchView(title: 'Hello',)),
              );
            }),
       ListTile(
           title: Text('Amazing'),
       ),ListTile(
         title: Text('Amazing'),
       ),ListTile(
         title: Text('Amazing'),
       ),ListTile(
         title: Text('Amazing'),
       ),ListTile(
         title: Text('Amazing'),
       ),ListTile(
         title: Text('Amazing'),
       ),ListTile(
         title: Text('Amazing'),
       ),
          ],
    );
  }
  Widget build(BuildContext context) {
    if(Platform.isAndroid) {
      return
      Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.team.name),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.green,
          currentIndex: _x,
          onTap: (int index) {
            setState(() {
              _x = index;
            });
          },
          items: [BottomNavigationBarItem(
            backgroundColor: Colors.green,
            icon: Icon(Icons.ac_unit),
            label: 'Teams',
          ), BottomNavigationBarItem(
            backgroundColor: Colors.deepPurple,
            icon: Icon(Icons.ac_unit),
            label: 'Teams',
          )
          ],
        ),
        body: _x == 0 ? Center(
          child: LineChart(
              LineChartData(
                  minX: 0,
                  maxX: 100,
                  minY: 0,
                  maxY: 7,
                  backgroundColor: Theme.of(context).canvasColor,
                  lineBarsData: [LineChartBarData(
                      spots: [
                        FlSpot(0, 3),
                        FlSpot(50, 2),
                      ],
                      colors: [Colors.green, Colors.blue],
                      isCurved: true,
                      preventCurveOverShooting: true,
                      barWidth: 5,
                      shadow: Shadow(color: Colors.green,
                          blurRadius: 5)
                  ), LineChartBarData(
                      spots: [
                        FlSpot(0, 5),
                        FlSpot(20, 5),
                        FlSpot(30, 7),
                        FlSpot(80, 2),
                      ],
                      colors: [Colors.deepPurple, Colors.blue],
                      isCurved: true,
                      preventCurveOverShooting: true,
                      barWidth: 5,
                      shadow: Shadow(color: Colors.green,
                          blurRadius: 5)
                  )]
              )
          ),
        ) : body(),

      );
    }
    else{
      return CupertinoTabScaffold(
        backgroundColor: Colors.blue,
        tabBuilder: (BuildContext context, int index){
          return CupertinoTabView(
            builder: (BuildContext context) {
              return CupertinoPageScaffold(child: body());
            },
          );
        },
        tabBar: CupertinoTabBar(
          backgroundColor: Colors.green,
          activeColor: Colors.red,
          currentIndex: _x,
          items: [BottomNavigationBarItem(
            backgroundColor: Colors.deepPurple,
            icon: Icon(Icons.ac_unit),
            label: 'Teams',
          ), BottomNavigationBarItem(
            backgroundColor: Colors.deepPurple,
            icon: Icon(Icons.ac_unit),
            label: 'Teams',
          )
          ],
          onTap: (int x){ _x = x; },
        ),
      );
    }

  }
}