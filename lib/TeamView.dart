import 'dart:io';

import 'package:TeamTrack/Graphic%20Assets/BarGraph.dart';
import 'package:TeamTrack/Graphic%20Assets/PlatformGraphics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:TeamTrack/MatchView.dart';
import 'backend.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class TeamView extends StatefulWidget {
  TeamView({Key key, this.team, this.event}) : super(key: key);

  final Team team;
  final Event event;

  @override
  _TeamView createState() => _TeamView();
}

class _TeamView extends State<TeamView> {
  bool _genBool = false;
  bool _autoBool = false;
  bool _teleBool = false;
  bool _endBool = false;
  final Curve finalCurve = Curves.fastLinearToSlowEaseIn;
  final Duration finalDuration = Duration(milliseconds: 800);
  List<Widget> genCard() {
    var list = <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BarGraph(
            val: 2,
            max: 9,
            title: 'Average',
          ),
          BarGraph(val: 2, max: 9, title: 'Best Score'),
          BarGraph(
            val: 6,
            max: 7,
            inverted: false,
            title: 'Consistency',
          ),
        ],
      ),
    ];
    if (_genBool) {
      list.add(LineChart(
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
      ])));
    }
    return list;
  }

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
      Center(
        child: Card(
          color: CupertinoColors.darkBackgroundGray,
          elevation: 3,
          shadowColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15))),
          child: InkWell(
            splashColor:
                _genBool ? Colors.transparent : Theme.of(context).splashColor,
            onTap: () {
              setState(() {
                _genBool = toggle(_genBool);
              });
            },
            child: AnimatedContainer(
                curve: finalCurve,
                duration: finalDuration,
                width: _genBool
                    ? MediaQuery.of(context).size.width
                    : MediaQuery.of(context).size.width - 30,
                height: _genBool ? 500 : 270,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: genCard())),
          ),
        ),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.team.name),
          backgroundColor: Theme.of(context).accentColor,
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
