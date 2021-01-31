import 'dart:io';

import 'package:TeamTrack/Graphic%20Assets/BarGraph.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:TeamTrack/MatchView.dart';
import 'backend.dart';
import 'package:fl_chart/fl_chart.dart';

class TeamView extends StatefulWidget {
  TeamView({Key key, this.team, this.event}) : super(key: key);

  final Team team;
  final Event event;

  @override
  _TeamView createState() => _TeamView();
}

class _TeamView extends State<TeamView> {
  List<Widget> body() {
    return <Widget>[
      Text(
        'Timeline',
        style: Theme.of(context).textTheme.headline4,
      ),
      Padding(
        padding: EdgeInsets.all(10),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          LineChart(
              LineChartData(minX: 0, maxX: 8, minY: 0, maxY: 7, lineBarsData: [
            LineChartBarData(
                spots: [
                  FlSpot(0, 3),
                  FlSpot(2, 2),
                ],
                colors: [
                  Colors.green,
                  Colors.blue
                ],
                isCurved: true,
                preventCurveOverShooting: true,
                barWidth: 5,
                shadow: Shadow(color: Colors.green, blurRadius: 5)),
            LineChartBarData(
                spots: [
                  FlSpot(0, 5),
                  FlSpot(2, 3),
                  FlSpot(3, 7),
                  FlSpot(4, 1),
                ],
                colors: [
                  Colors.deepPurple,
                  Colors.blue
                ],
                isCurved: true,
                preventCurveOverShooting: true,
                barWidth: 5,
                shadow: Shadow(color: Colors.green, blurRadius: 5))
          ])),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0),
          )
        ],
      ),
      MaterialButton(
          child: Text('Okay'),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        MatchView(match: Match.defaultMatch(EventType.local))));
          }),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 0),
      ),
      MaterialButton(
        onPressed: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            BarChart(BarChartData(
              minY: 0,
              maxY: 7,
              barGroups: [
                BarChartGroupData(x: 2, barRods: [
                  BarChartRodData(y: 6, width: 36),
                ]),
                BarChartGroupData(x: 6, barRods: [
                  BarChartRodData(y: 2, width: 36),
                ]),
                BarChartGroupData(x: 7, barRods: [
                  BarChartRodData(
                      y: 4, width: 36, colors: [Colors.red, Colors.blue]),
                ]),
              ],
              //groupsSpace,
              alignment: BarChartAlignment.spaceEvenly,
              //titlesData: FlTitlesData(show: true),
              //barTouchData: ,
              //axisTitleData,

              //gridData,
              //borderData,
              //rangeAnnotations,
            )),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
            )
          ],
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          BarChart(BarChartData(
            minY: 0,
            maxY: 7,
            barGroups: [
              BarChartGroupData(x: 2, barRods: [
                BarChartRodData(y: 6, width: 36),
              ]),
              BarChartGroupData(x: 6, barRods: [
                BarChartRodData(y: 2, width: 36),
              ]),
              BarChartGroupData(x: 7, barRods: [
                BarChartRodData(
                    y: 4, width: 36, colors: [Colors.red, Colors.blue]),
              ]),
            ],
            //groupsSpace,
            alignment: BarChartAlignment.spaceEvenly,
            //titlesData: FlTitlesData(show: true),
            //barTouchData: ,
            //axisTitleData,

            //gridData,
            //borderData,
            //rangeAnnotations,
          )),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0),
          )
        ],
      ),
      Container(
          color: Colors.grey,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BarGraph(val: 2, max: 9),
            ],
          ))
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.team.name),
        ),
        body: ListView(
          children: body(),
        ),
      );
    } else {
      return CupertinoPageScaffold(
          child: SafeArea(
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Text(widget.team.name),
              ),
              SliverList(delegate: SliverChildListDelegate(body()))
            ],
          ),
        ),
      ));
    }
  }
}
