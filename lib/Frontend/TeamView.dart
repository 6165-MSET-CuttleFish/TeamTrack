import 'dart:io';
import 'package:TeamTrack/Frontend/Assets/BarGraph.dart';
import 'package:TeamTrack/Frontend/Assets/CardView.dart';
import 'package:TeamTrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:TeamTrack/Frontend/MatchList.dart';
import 'package:TeamTrack/Frontend/MatchView.dart';
import 'package:TeamTrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TeamView extends StatefulWidget {
  TeamView({Key key, this.team, this.event}) : super(key: key);
  final Team team;
  final Event event;
  @override
  _TeamView createState() => _TeamView();
}

class _TeamView extends State<TeamView> {
  Dice _dice = Dice.none;
  final Curve finalCurve = Curves.fastLinearToSlowEaseIn;
  final Duration finalDuration = Duration(milliseconds: 800);
  Widget _lineChart() {
    return widget.team.scores.length >= 2
        ? AspectRatio(
            aspectRatio: 1.70,
            child: Container(
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(18),
                  ),
                  color: Color(0xff232d37)),
              child: Padding(
                  padding: const EdgeInsets.only(
                      right: 50.0, left: 12.0, top: 24, bottom: 12),
                  child: LineChart(LineChartData(
                    minX: 0,
                    maxX: widget.team.scores.length.toDouble(),
                    minY: 0,
                    maxY: widget.event.matches
                        .maxAllianceScore(widget.team)
                        .toDouble(),
                    lineBarsData: [
                      if (widget.event.type != EventType.remote)
                        LineChartBarData(
                            spots: widget.event.matches.spots(widget.team),
                            colors: [
                              Colors.orange,
                            ],
                            isCurved: true,
                            preventCurveOverShooting: true,
                            barWidth: 5,
                            shadow: Shadow(color: Colors.green, blurRadius: 5)),
                      LineChartBarData(
                          spots: widget.team.scores.spots(),
                          colors: [
                            Colors.deepPurple,
                          ],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                          shadow: Shadow(color: Colors.green, blurRadius: 5)),
                      LineChartBarData(
                          spots: widget.team.scores.autoSpots(),
                          colors: [
                            Colors.green,
                          ],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                          shadow: Shadow(color: Colors.green, blurRadius: 5)),
                      LineChartBarData(
                          spots: widget.team.scores.endSpots(),
                          colors: [
                            Colors.red,
                          ],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                          shadow: Shadow(color: Colors.green, blurRadius: 5)),
                      LineChartBarData(
                          spots: widget.team.scores.teleSpots(),
                          colors: [
                            Colors.blue,
                          ],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                          shadow: Shadow(color: Colors.green, blurRadius: 5)),
                    ],
                  ))),
            ),
          )
        : Text('');
  }

  List<Widget> body() {
    return <Widget>[
      if (widget.team.scores.length >= 2)
        Padding(
          padding: EdgeInsets.all(40),
        ),
      if (widget.team.scores.length >= 2)
        Wrap(
          children: [
            if (widget.event.type != EventType.remote)
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(18),
                    ),
                    color: Colors.orange),
                child: Padding(
                    padding: EdgeInsets.all(8), child: Text('Alliance Total')),
              ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(18),
                  ),
                  color: Colors.deepPurple),
              child:
                  Padding(padding: EdgeInsets.all(8), child: Text('Timeline')),
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(18),
                  ),
                  color: Colors.green),
              child: Padding(
                  padding: EdgeInsets.all(8), child: Text('Autonomous')),
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(18),
                  ),
                  color: Colors.blue),
              child:
                  Padding(padding: EdgeInsets.all(8), child: Text('Tele-Op')),
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(18),
                  ),
                  color: Colors.red),
              child:
                  Padding(padding: EdgeInsets.all(8), child: Text('Endgame')),
            ),
          ],
        ),
      _lineChart(),
      Container(
          width: MediaQuery.of(context).size.width,
          child: PlatformButton(
            onPressed: () {
              if (Platform.isIOS) {
                setState(() {});
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => MatchList(
                              event: widget.event,
                              team: widget.team,
                            )));
              } else {
                setState(() {});
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MatchList(
                              event: widget.event,
                              team: widget.team,
                            )));
              }
            },
            color: CupertinoColors.systemGreen,
            child: Text('Matches'),
          )),
      Padding(
        padding: EdgeInsets.all(10),
      ),
      Text(
        'General',
        style: Theme.of(context).textTheme.bodyText1,
      ),
      Padding(
        padding: EdgeInsets.all(5),
      ),
      CardView(
          isActive: widget.team.scores.length >= 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BarGraph(
                val: widget.team.scores.meanScore(),
                max: widget.event.teams.maxScore(),
                title: 'Average',
              ),
              BarGraph(
                  val: widget.team.scores.maxScore(),
                  max: widget.event.teams.maxScore(),
                  title: 'Best Score'),
              BarGraph(
                val: widget.team.scores.madScore(),
                max: widget.event.teams.lowestMadScore(),
                inverted: true,
                title: 'Consistency',
              ),
            ],
          ),
          collapsed: widget.team.scores.length >= 1
              ? LineChart(LineChartData(
                  minX: 0,
                  maxX: widget.team.scores.length.toDouble(),
                  minY: widget.team.scores.minScore(),
                  maxY: widget.team.scores.maxScore(),
                  lineBarsData: [
                      LineChartBarData(
                          spots: widget.team.scores.spots(),
                          colors: [Colors.green, Colors.blue],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                          shadow: Shadow(color: Colors.green, blurRadius: 5)),
                    ]))
              : Text('')),
      Padding(
        padding: EdgeInsets.all(10),
      ),
      Text(
        'Autonomous',
        style: Theme.of(context).textTheme.bodyText1,
      ),
      Padding(
        padding: EdgeInsets.all(5),
      ),
      Text(
        'Stack Height',
        style: Theme.of(context).textTheme.caption,
      ),
      Padding(
        padding: EdgeInsets.all(5),
      ),
      CupertinoSlidingSegmentedControl(
        groupValue: _dice,
        children: <Dice, Widget>{
          Dice.one: Text('0'),
          Dice.two: Text('1'),
          Dice.three: Text('4'),
          Dice.none: Text('All Cases')
        },
        onValueChanged: (Dice newDice) {
          setState(() {
            _dice = newDice;
          });
        },
      ),
      Padding(
        padding: EdgeInsets.all(5),
      ),
      CardView(
        isActive: _dice == Dice.none
            ? widget.team.scores.length >= 2
            : widget.team.scores.where((e) => e.dice == _dice).length >= 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BarGraph(
              val: widget.team.scores.autoMeanScore(_dice),
              max: widget.event.teams.maxAutoScore(_dice),
              title: 'Average',
            ),
            BarGraph(
                val: widget.team.scores.autoMaxScore(_dice),
                max: widget.event.teams.maxAutoScore(_dice),
                title: 'Best Score'),
            BarGraph(
              val: widget.team.scores.autoMADScore(_dice),
              max: widget.event.teams.lowestAutoMadScore(_dice),
              inverted: true,
              title: 'Consistency',
            ),
          ],
        ),
        collapsed: widget.team.scores
                    .where((e) => _dice != Dice.none ? e.dice == _dice : true)
                    .length >=
                1
            ? LineChart(LineChartData(
                minX: 0,
                maxX: widget.team.scores
                    .where((e) => _dice != Dice.none ? e.dice == _dice : true)
                    .length
                    .toDouble(),
                minY: widget.team.scores.autoMinScore(_dice),
                maxY: widget.team.scores.autoMaxScore(_dice),
                lineBarsData: [
                    LineChartBarData(
                        spots: widget.team.scores
                            .where((e) =>
                                _dice != Dice.none ? e.dice == _dice : true)
                            .toList()
                            .autoSpots(),
                        colors: [Colors.green, Colors.blue],
                        isCurved: true,
                        preventCurveOverShooting: true,
                        barWidth: 5,
                        shadow: Shadow(color: Colors.green, blurRadius: 5)),
                  ]))
            : Text(''),
      ),
      Padding(
        padding: EdgeInsets.all(10),
      ),
      Text(
        'Tele-Op',
        style: Theme.of(context).textTheme.bodyText1,
      ),
      Padding(
        padding: EdgeInsets.all(5),
      ),
      CardView(
          isActive: widget.team.scores.length >= 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BarGraph(
                val: widget.team.scores.teleMeanScore(),
                max: widget.event.teams.maxTeleScore(),
                title: 'Average',
              ),
              BarGraph(
                  val: widget.team.scores.teleMaxScore(),
                  max: widget.event.teams.maxTeleScore(),
                  title: 'Best Score'),
              BarGraph(
                val: widget.team.scores.teleMADScore(),
                max: widget.event.teams.lowestTeleMadScore(),
                inverted: true,
                title: 'Consistency',
              ),
            ],
          ),
          collapsed: widget.team.scores.length >= 1
              ? LineChart(LineChartData(
                  minX: 0,
                  maxX: widget.team.scores.length.toDouble(),
                  minY: widget.team.scores.teleMinScore(),
                  maxY: widget.team.scores.teleMaxScore().toDouble(),
                  lineBarsData: [
                      LineChartBarData(
                          spots: widget.team.scores.teleSpots(),
                          colors: [Colors.green, Colors.blue],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                          shadow: Shadow(color: Colors.green, blurRadius: 5)),
                    ]))
              : Text('')),
      Padding(
        padding: EdgeInsets.all(10),
      ),
      Text(
        'Endgame',
        style: Theme.of(context).textTheme.bodyText1,
      ),
      Padding(
        padding: EdgeInsets.all(5),
      ),
      CardView(
          isActive: widget.team.scores.length >= 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BarGraph(
                val: widget.team.scores.endMeanScore(),
                max: widget.event.teams.maxEndScore(),
                title: 'Average',
              ),
              BarGraph(
                  val: widget.team.scores.endMaxScore(),
                  max: widget.event.teams.maxEndScore(),
                  title: 'Best Score'),
              BarGraph(
                val: widget.team.scores.endMADScore(),
                max: widget.event.teams.lowestEndMadScore(),
                inverted: true,
                title: 'Consistency',
              ),
            ],
          ),
          collapsed: widget.team.scores.length >= 1
              ? LineChart(LineChartData(
                  minX: 0,
                  maxX: widget.team.scores.length.toDouble(),
                  minY: widget.team.scores.endMinScore(),
                  maxY: widget.team.scores.endMaxScore(),
                  lineBarsData: [
                      LineChartBarData(
                          spots: widget.team.scores.endSpots(),
                          colors: [Colors.green, Colors.blue],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                          shadow: Shadow(color: Colors.green, blurRadius: 5)),
                    ]))
              : Text('')),
      Padding(
        padding: EdgeInsets.all(150),
      ),
    ];
  }

  List<Match> _matches() {
    return widget.event.matches
        .where((e) => e.alliance(widget.team) != null)
        .toList();
  }

  final slider = SlidableStrechActionPane();
  Widget _matchList() {
    var arr = <Slidable>[];

    for (int i = 0; i < _matches().length; i++) {
      arr.add(Slidable(
          actionPane: slider,
          secondaryActions: [
            IconSlideAction(
              icon: Icons.delete,
              color: Colors.red,
              onTap: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) => PlatformAlert(
                          title: Text('Delete Match'),
                          content: Text('Are you sure?'),
                          actions: [
                            PlatformDialogAction(
                              isDefaultAction: true,
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            PlatformDialogAction(
                              isDefaultAction: false,
                              isDestructive: true,
                              child: Text('Confirm'),
                              onPressed: () {
                                setState(() {
                                  _matches()[i].red.item1.scores.removeWhere(
                                      (f) => f.id == _matches()[i].id);
                                  _matches().remove(_matches()[i]);
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ));
              },
            )
          ],
          child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: Text((i + 1).toString()),
                title: Text(widget.team.name),
                trailing: Text(_matches()[i].score()),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              MatchView(match: _matches()[i])));
                },
              ))));
    }
    return ListView(
      children: arr,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.team.name),
          backgroundColor: Theme.of(context).accentColor,
        ),
        body: ListView(children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: body(),
          )
        ]),
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
