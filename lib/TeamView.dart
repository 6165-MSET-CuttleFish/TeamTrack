import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:TeamTrack/MatchView.dart';
import 'backend.dart';
import 'package:fl_chart/fl_chart.dart';
class TeamView extends StatefulWidget {
    TeamView({Key key, this.team}) : super(key: key);

    final Team team;

    @override
    _TeamView createState() => _TeamView();
}
class _TeamView extends State<TeamView>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.team.name),
      ),
      body: Center(
          child: LineChart(
              LineChartData(
                  minX: 0,
                  maxX: 2,
                  minY: 0,
                  maxY: 6,
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
                  )]
              )
          )
      ),
    );

  }
}