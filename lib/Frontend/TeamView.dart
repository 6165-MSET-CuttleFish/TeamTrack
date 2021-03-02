import 'dart:io';
import 'dart:math';
import 'package:TeamTrack/Frontend/Assets/BarGraph.dart';
import 'package:TeamTrack/Frontend/Assets/CardView.dart';
import 'package:TeamTrack/Frontend/Assets/Collapsible.dart';
import 'package:TeamTrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:TeamTrack/Frontend/MatchList.dart';
import 'package:TeamTrack/Frontend/MatchView.dart';
import 'package:TeamTrack/backend.dart';
import 'package:TeamTrack/score.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';

class TeamView extends StatefulWidget {
  TeamView({Key key, this.team, this.event}) : super(key: key);
  final Team team;
  final Event event;
  @override
  _TeamView createState() => _TeamView();
}

class _TeamView extends State<TeamView> {
  _TeamView() {
    textColor = Colors.white;
  }
  Color textColor;
  Dice _dice = Dice.none;
  final Curve finalCurve = Curves.fastLinearToSlowEaseIn;
  final Duration finalDuration = Duration(milliseconds: 800);
  final _selections = [true, true, false, false, false];
  Widget _lineChart() {
    return widget.team.scores.diceScores(_dice).length >= 2
        ? AspectRatio(
            aspectRatio: 1.20,
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
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: value % 10 == 0
                              ? Color(0xff37434d)
                              : Colors.transparent,
                          strokeWidth: value % 10 == 0 ? 1 : 0,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: const Color(0xff37434d),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTextStyles: (value) => const TextStyle(
                            color: Color(0xff68737d),
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                        getTitles: (value) {
                          return (value + 1).toInt().toString();
                        },
                        margin: 8,
                      ),
                      leftTitles: SideTitles(
                        showTitles: true,
                        getTextStyles: (value) => const TextStyle(
                          color: Color(0xff67727d),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        getTitles: (value) {
                          if (value % 50 == 0) {
                            return value.toInt().toString();
                          }
                          return '';
                        },
                        reservedSize: 28,
                        margin: 12,
                      ),
                    ),
                    borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                            color: const Color(0xff37434d), width: 1)),
                    minX: 0,
                    maxX:
                        widget.team.scores.diceScores(_dice).length.toDouble() -
                            1,
                    minY: 0,
                    maxY: [
                      widget.event.matches
                          .maxAllianceScore(widget.team)
                          .toDouble(),
                      widget.team.targetScore != null
                          ? widget.team.targetScore.total().toDouble()
                          : 0.0
                    ].reduce(max),
                    lineBarsData: [
                      LineChartBarData(
                          belowBarData: widget.team.targetScore != null
                              ? BarAreaData(
                                  show: true,
                                  colors: [
                                    Colors.lightGreenAccent.withOpacity(0.2)
                                  ],
                                  cutOffY: widget.team.targetScore
                                      ?.total()
                                      ?.toDouble(),
                                  applyCutOffY: true,
                                )
                              : null,
                          aboveBarData: widget.team.targetScore != null
                              ? BarAreaData(
                                  show: true,
                                  colors: [Colors.redAccent.withOpacity(0.2)],
                                  cutOffY: widget.team.targetScore
                                      ?.total()
                                      ?.toDouble(),
                                  applyCutOffY: true,
                                )
                              : null,
                          show: _selections[0] &&
                              widget.event.type != EventType.remote,
                          spots: widget.event.matches
                              .where(
                                  (e) => e.dice == _dice || _dice == Dice.none)
                              .toList()
                              .spots(widget.team, _dice),
                          colors: [Color.fromRGBO(255, 166, 0, 1)],
                          isCurved: true,
                          isStrokeCapRound: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                          shadow: Shadow(color: Colors.green, blurRadius: 5)),
                      LineChartBarData(
                          belowBarData: widget.team.targetScore != null
                              ? BarAreaData(
                                  show: true,
                                  colors: [
                                    Colors.lightGreenAccent.withOpacity(0.2)
                                  ],
                                  cutOffY: widget.team.targetScore
                                      ?.total()
                                      ?.toDouble(),
                                  applyCutOffY: true,
                                )
                              : null,
                          aboveBarData: widget.team.targetScore != null
                              ? BarAreaData(
                                  show: true,
                                  colors: [Colors.redAccent.withOpacity(0.2)],
                                  cutOffY: widget.team.targetScore
                                      ?.total()
                                      ?.toDouble(),
                                  applyCutOffY: true,
                                )
                              : null,
                          show: _selections[1],
                          spots: _dice != Dice.none
                              ? widget.team.scores
                                  .where((e) => e.dice == _dice)
                                  .toList()
                                  .spots()
                              : widget.team.scores.spots(),
                          colors: [
                            Color.fromRGBO(230, 30, 213, 1),
                          ],
                          isCurved: true,
                          isStrokeCapRound: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                          shadow: Shadow(color: Colors.green, blurRadius: 5)),
                      LineChartBarData(
                          show: _selections[2],
                          spots: _dice != Dice.none
                              ? widget.team.scores
                                  .where((e) => e.dice == _dice)
                                  .toList()
                                  .autoSpots()
                              : widget.team.scores.autoSpots(),
                          colors: [
                            Colors.green,
                          ],
                          isCurved: true,
                          isStrokeCapRound: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                          shadow: Shadow(color: Colors.green, blurRadius: 5)),
                      LineChartBarData(
                          show: _selections[3],
                          spots: _dice != Dice.none
                              ? widget.team.scores
                                  .where((e) => e.dice == _dice)
                                  .toList()
                                  .teleSpots()
                              : widget.team.scores.teleSpots(),
                          colors: [
                            Colors.blue,
                          ],
                          isCurved: true,
                          isStrokeCapRound: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                          shadow: Shadow(color: Colors.green, blurRadius: 5)),
                      LineChartBarData(
                          show: _selections[4],
                          spots: _dice != Dice.none
                              ? widget.team.scores
                                  .where((e) => e.dice == _dice)
                                  .toList()
                                  .endSpots()
                              : widget.team.scores.endSpots(),
                          colors: [
                            Colors.red,
                          ],
                          isCurved: true,
                          isStrokeCapRound: true,
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
      Collapsible(
        isCollapsed: widget.team.scores.diceScores(_dice).length < 2,
        child: Column(children: [
          Padding(
            padding: widget.event.type != EventType.remote
                ? EdgeInsets.all(40)
                : EdgeInsets.all(20),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: 0,
            children: [
              if (widget.event.type != EventType.remote)
                FlatButton(
                  color: _selections[0] ? Color.fromRGBO(255, 166, 0, 1) : null,
                  splashColor: Color.fromRGBO(255, 166, 0, 1),
                  onPressed: () {
                    setState(() {
                      _selections[0] = !_selections[0];
                    });
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      side: BorderSide(color: Color.fromRGBO(255, 166, 0, 1))),
                  child: Text('Alliance Total'),
                ),
              FlatButton(
                color: _selections[1] ? Color.fromRGBO(230, 30, 213, 1) : null,
                splashColor: Color.fromRGBO(230, 30, 213, 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Color.fromRGBO(230, 30, 213, 1))),
                child: Text('General'),
                onPressed: () {
                  setState(() {
                    _selections[1] = !_selections[1];
                  });
                },
              ),
              FlatButton(
                color: _selections[2] ? Colors.green : null,
                splashColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.green)),
                child: Text('Autonomous'),
                onPressed: () {
                  setState(() {
                    _selections[2] = !_selections[2];
                  });
                },
              ),
              FlatButton(
                color: _selections[3] ? Colors.blue : null,
                splashColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.blue)),
                child: Text('Tele-Op'),
                onPressed: () {
                  setState(() {
                    _selections[3] = !_selections[3];
                  });
                },
              ),
              FlatButton(
                color: _selections[4] ? Colors.red : null,
                splashColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.red)),
                child: Text('Endgame'),
                onPressed: () {
                  setState(() {
                    _selections[4] = !_selections[4];
                  });
                },
              ),
            ],
          ),
          _lineChart(),
        ]),
      ),
      Container(
          width: MediaQuery.of(context).size.width,
          child: PlatformButton(
            onPressed: () async {
              if (Platform.isIOS) {
                await Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => MatchList(
                              event: widget.event,
                              team: widget.team,
                            )));
                setState(() {});
              } else {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MatchList(
                              event: widget.event,
                              team: widget.team,
                            )));
                setState(() {});
              }
            },
            color: CupertinoColors.systemGreen,
            child: Text('Matches'),
          )),
      Container(
          width: MediaQuery.of(context).size.width / 2,
          child: PlatformButton(
            onPressed: () async {
              if (widget.team.targetScore == null) {
                widget.team.targetScore = Score(Uuid().v4(), Dice.none);
              }
              if (Platform.isIOS) {
                await Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => MatchView(
                              team: widget.team,
                            )));
                setState(() {});
              } else {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MatchView(
                              match: Match.defaultMatch(EventType.remote),
                              team: widget.team,
                            )));
                setState(() {});
              }
            },
            color: Colors.indigoAccent,
            child: Text('Target Score'),
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
          isActive: widget.team.scores.diceScores(_dice).length >= 1,
          child: Padding(
              padding: EdgeInsets.only(left: 5, right: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BarGraph(
                    val: widget.team.scores.meanScore(_dice),
                    max: widget.event.teams.maxScore(_dice),
                    title: 'Average',
                  ),
                  BarGraph(
                      val: widget.team.scores.maxScore(_dice),
                      max: widget.event.teams.maxScore(_dice),
                      title: 'Best Score'),
                  BarGraph(
                    val: widget.team.scores.madScore(_dice),
                    max: widget.event.teams.lowestMadScore(_dice),
                    inverted: true,
                    title: 'Deviation',
                  ),
                ],
              )),
          collapsed: widget.team.scores.diceScores(_dice).length >= 1
              ? AspectRatio(
                  aspectRatio: 2,
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
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: value % 10 == 0
                                        ? Color(0xff37434d)
                                        : Colors.transparent,
                                    strokeWidth: value % 10 == 0 ? 1 : 0,
                                  );
                                },
                                getDrawingVerticalLine: (value) {
                                  return FlLine(
                                    color: const Color(0xff37434d),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  getTextStyles: (value) => const TextStyle(
                                      color: Color(0xff68737d), fontSize: 16),
                                  getTitles: (value) {
                                    return (value + 1).toInt().toString();
                                  },
                                  margin: 8,
                                ),
                                leftTitles: SideTitles(
                                  showTitles: true,
                                  getTextStyles: (value) => const TextStyle(
                                    color: Color(0xff67727d),
                                    fontSize: 15,
                                  ),
                                  getTitles: (value) {
                                    if (value % 30 == 0) {
                                      return value.toInt().toString();
                                    }
                                    return '';
                                  },
                                  reservedSize: 28,
                                  margin: 12,
                                ),
                              ),
                              borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                      color: const Color(0xff37434d),
                                      width: 1)),
                              minX: 0,
                              maxX: widget.team.scores.length.toDouble() - 1,
                              minY: [
                                widget.team.scores.minScore(_dice),
                                widget.team.targetScore.total().toDouble()
                              ].reduce(min),
                              maxY: [
                                widget.team.scores.maxScore(_dice),
                                widget.team.targetScore != null
                                    ? widget.team.targetScore.total().toDouble()
                                    : 0.0
                              ].reduce(max),
                              lineBarsData: [
                                LineChartBarData(
                                    belowBarData:
                                        widget.team.targetScore != null
                                            ? BarAreaData(
                                                show: true,
                                                colors: [
                                                  Colors.lightGreenAccent
                                                      .withOpacity(0.5)
                                                ],
                                                cutOffY: widget.team.targetScore
                                                    ?.total()
                                                    ?.toDouble(),
                                                applyCutOffY: true,
                                              )
                                            : null,
                                    aboveBarData: widget.team.targetScore !=
                                            null
                                        ? BarAreaData(
                                            show: true,
                                            colors: [
                                              Colors.redAccent.withOpacity(0.5)
                                            ],
                                            cutOffY: widget.team.targetScore
                                                ?.total()
                                                ?.toDouble(),
                                            applyCutOffY: true,
                                          )
                                        : null,
                                    spots: widget.team.scores
                                        .diceScores(_dice)
                                        .spots(),
                                    colors: [Colors.orange],
                                    isCurved: true,
                                    preventCurveOverShooting: true,
                                    barWidth: 5,
                                    shadow: Shadow(
                                        color: Colors.green, blurRadius: 5)),
                              ])))))
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
      CardView(
        isActive: widget.team.scores.diceScores(_dice).length >= 1,
        child: Padding(
            padding: EdgeInsets.only(left: 5, right: 5),
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
                  title: 'Deviation',
                ),
              ],
            )),
        collapsed: widget.team.scores.diceScores(_dice).length >= 1
            ? AspectRatio(
                aspectRatio: 2,
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
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: value % 10 == 0
                                      ? Color(0xff37434d)
                                      : Colors.transparent,
                                  strokeWidth: value % 10 == 0 ? 1 : 0,
                                );
                              },
                              getDrawingVerticalLine: (value) {
                                return FlLine(
                                  color: const Color(0xff37434d),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                getTextStyles: (value) => const TextStyle(
                                    color: Color(0xff68737d), fontSize: 16),
                                getTitles: (value) {
                                  return (value + 1).toInt().toString();
                                },
                                margin: 8,
                              ),
                              leftTitles: SideTitles(
                                showTitles: true,
                                getTextStyles: (value) => const TextStyle(
                                  color: Color(0xff67727d),
                                  fontSize: 15,
                                ),
                                getTitles: (value) {
                                  if (value % 30 == 0) {
                                    return value.toInt().toString();
                                  }
                                  return '';
                                },
                                reservedSize: 28,
                                margin: 12,
                              ),
                            ),
                            borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                    color: const Color(0xff37434d), width: 1)),
                            minX: 0,
                            maxX: widget.team.scores
                                    .where((e) => _dice != Dice.none
                                        ? e.dice == _dice
                                        : true)
                                    .length
                                    .toDouble() -
                                1,
                            minY: [
                              widget.team.scores.autoMinScore(_dice),
                              widget.team.targetScore.autoScore
                                  .total()
                                  .toDouble()
                            ].reduce(min),
                            maxY: [
                              widget.team.scores.autoMaxScore(_dice),
                              widget.team.targetScore != null
                                  ? widget.team.targetScore.autoScore
                                      .total()
                                      .toDouble()
                                  : 0.0
                            ].reduce(max),
                            lineBarsData: [
                              LineChartBarData(
                                  belowBarData: widget.team.targetScore != null
                                      ? BarAreaData(
                                          show: true,
                                          colors: [
                                            Colors.lightGreenAccent
                                                .withOpacity(0.5)
                                          ],
                                          cutOffY: widget
                                              .team.targetScore?.autoScore
                                              ?.total()
                                              ?.toDouble(),
                                          applyCutOffY: true,
                                        )
                                      : null,
                                  aboveBarData: widget.team.targetScore != null
                                      ? BarAreaData(
                                          show: true,
                                          colors: [
                                            Colors.redAccent.withOpacity(0.5)
                                          ],
                                          cutOffY: widget
                                              .team.targetScore?.autoScore
                                              ?.total()
                                              ?.toDouble(),
                                          applyCutOffY: true,
                                        )
                                      : null,
                                  spots: widget.team.scores
                                      .diceScores(_dice)
                                      .autoSpots(),
                                  colors: [Colors.orange],
                                  isCurved: true,
                                  preventCurveOverShooting: true,
                                  barWidth: 5,
                                  shadow: Shadow(
                                      color: Colors.green, blurRadius: 5)),
                            ])))))
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
          isActive: widget.team.scores.diceScores(_dice).length >= 1,
          child: Padding(
              padding: EdgeInsets.only(left: 5, right: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BarGraph(
                    val: widget.team.scores.teleMeanScore(_dice),
                    max: widget.event.teams.maxTeleScore(_dice),
                    title: 'Average',
                  ),
                  BarGraph(
                      val: widget.team.scores.teleMaxScore(_dice),
                      max: widget.event.teams.maxTeleScore(_dice),
                      title: 'Best Score'),
                  BarGraph(
                    val: widget.team.scores.teleMADScore(_dice),
                    max: widget.event.teams.lowestTeleMadScore(_dice),
                    inverted: true,
                    title: 'Deviation',
                  ),
                ],
              )),
          collapsed: widget.team.scores.diceScores(_dice).length >= 1
              ? AspectRatio(
                  aspectRatio: 2,
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
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: value % 10 == 0
                                        ? Color(0xff37434d)
                                        : Colors.transparent,
                                    strokeWidth: value % 10 == 0 ? 1 : 0,
                                  );
                                },
                                getDrawingVerticalLine: (value) {
                                  return FlLine(
                                    color: const Color(0xff37434d),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  getTextStyles: (value) => const TextStyle(
                                      color: Color(0xff68737d), fontSize: 16),
                                  getTitles: (value) {
                                    return (value + 1).toInt().toString();
                                  },
                                  margin: 8,
                                ),
                                leftTitles: SideTitles(
                                  showTitles: true,
                                  getTextStyles: (value) => const TextStyle(
                                    color: Color(0xff67727d),
                                    fontSize: 15,
                                  ),
                                  getTitles: (value) {
                                    if (value % 30 == 0) {
                                      return value.toInt().toString();
                                    }
                                    return '';
                                  },
                                  reservedSize: 28,
                                  margin: 12,
                                ),
                              ),
                              borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                      color: const Color(0xff37434d),
                                      width: 1)),
                              minX: 0,
                              maxX: widget.team.scores
                                      .diceScores(_dice)
                                      .length
                                      .toDouble() -
                                  1,
                              minY: [
                                widget.team.scores.teleMinScore(_dice),
                                widget.team.targetScore.teleScore
                                    .total()
                                    .toDouble()
                              ].reduce(min),
                              maxY: [
                                widget.team.scores
                                    .teleMaxScore(_dice)
                                    .toDouble(),
                                widget.team.targetScore != null
                                    ? widget.team.targetScore.teleScore
                                        .total()
                                        .toDouble()
                                    : 0.0
                              ].reduce(max),
                              lineBarsData: [
                                LineChartBarData(
                                    belowBarData:
                                        widget.team.targetScore != null
                                            ? BarAreaData(
                                                show: true,
                                                colors: [
                                                  Colors.lightGreenAccent
                                                      .withOpacity(0.5)
                                                ],
                                                cutOffY: widget
                                                    .team.targetScore?.teleScore
                                                    ?.total()
                                                    ?.toDouble(),
                                                applyCutOffY: true,
                                              )
                                            : null,
                                    aboveBarData: widget.team.targetScore !=
                                            null
                                        ? BarAreaData(
                                            show: true,
                                            colors: [
                                              Colors.redAccent.withOpacity(0.5)
                                            ],
                                            cutOffY: widget
                                                .team.targetScore?.teleScore
                                                ?.total()
                                                ?.toDouble(),
                                            applyCutOffY: true,
                                          )
                                        : null,
                                    spots: widget.team.scores
                                        .diceScores(_dice)
                                        .teleSpots(),
                                    colors: [Colors.orange],
                                    isCurved: true,
                                    preventCurveOverShooting: true,
                                    barWidth: 5,
                                    shadow: Shadow(
                                        color: Colors.green, blurRadius: 5)),
                              ])))))
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
          isActive: widget.team.scores.diceScores(_dice).length >= 1,
          child: Padding(
              padding: EdgeInsets.only(left: 5, right: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BarGraph(
                    val: widget.team.scores.endMeanScore(_dice),
                    max: widget.event.teams.maxEndScore(_dice),
                    title: 'Average',
                  ),
                  BarGraph(
                      val: widget.team.scores.endMaxScore(_dice),
                      max: widget.event.teams.maxEndScore(_dice),
                      title: 'Best Score'),
                  BarGraph(
                    val: widget.team.scores.endMADScore(_dice),
                    max: widget.event.teams.lowestEndMadScore(_dice),
                    inverted: true,
                    title: 'Deviation',
                  ),
                ],
              )),
          collapsed: widget.team.scores.diceScores(_dice).length >= 1
              ? AspectRatio(
                  aspectRatio: 2,
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
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: value % 10 == 0
                                        ? Color(0xff37434d)
                                        : Colors.transparent,
                                    strokeWidth: value % 10 == 0 ? 1 : 0,
                                  );
                                },
                                getDrawingVerticalLine: (value) {
                                  return FlLine(
                                    color: const Color(0xff37434d),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  getTextStyles: (value) => const TextStyle(
                                      color: Color(0xff68737d), fontSize: 16),
                                  getTitles: (value) {
                                    return (value + 1).toInt().toString();
                                  },
                                  margin: 8,
                                ),
                                leftTitles: SideTitles(
                                  showTitles: true,
                                  getTextStyles: (value) => const TextStyle(
                                    color: Color(0xff67727d),
                                    fontSize: 15,
                                  ),
                                  getTitles: (value) {
                                    if (value % 30 == 0) {
                                      return value.toInt().toString();
                                    }
                                    return '';
                                  },
                                  reservedSize: 28,
                                  margin: 12,
                                ),
                              ),
                              borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                      color: const Color(0xff37434d),
                                      width: 1)),
                              minX: 0,
                              maxX: widget.team.scores
                                      .diceScores(_dice)
                                      .length
                                      .toDouble() -
                                  1,
                              minY: [
                                widget.team.scores.endMinScore(_dice),
                                widget.team.targetScore.endgameScore
                                    .total()
                                    .toDouble()
                              ].reduce(min),
                              maxY: [
                                widget.team.scores.endMaxScore(_dice),
                                widget.team.targetScore != null
                                    ? widget.team.targetScore.endgameScore
                                        .total()
                                        .toDouble()
                                    : 0.0
                              ].reduce(max),
                              lineBarsData: [
                                LineChartBarData(
                                    belowBarData:
                                        widget.team.targetScore != null
                                            ? BarAreaData(
                                                show: true,
                                                colors: [
                                                  Colors.lightGreenAccent
                                                      .withOpacity(0.5)
                                                ],
                                                cutOffY: widget.team.targetScore
                                                    ?.endgameScore
                                                    ?.total()
                                                    ?.toDouble(),
                                                applyCutOffY: true,
                                              )
                                            : null,
                                    aboveBarData: widget.team.targetScore !=
                                            null
                                        ? BarAreaData(
                                            show: true,
                                            colors: [
                                              Colors.redAccent.withOpacity(0.5)
                                            ],
                                            cutOffY: widget
                                                .team.targetScore?.endgameScore
                                                ?.total()
                                                ?.toDouble(),
                                            applyCutOffY: true,
                                          )
                                        : null,
                                    spots: widget.team.scores
                                        .diceScores(_dice)
                                        .endSpots(),
                                    colors: [Colors.orange],
                                    isCurved: true,
                                    preventCurveOverShooting: true,
                                    barWidth: 5,
                                    shadow: Shadow(
                                        color: Colors.green, blurRadius: 5)),
                              ])))))
              : Text('')),
      Padding(
        padding: EdgeInsets.all(130),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Platform.isIOS
          ? CupertinoSlidingSegmentedControl(
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
            )
          : ButtonBar(
              alignment: MainAxisAlignment.center,
              children: [
                OutlineButton(
                  disabledTextColor: Theme.of(context).accentColor,
                  highlightedBorderColor: Theme.of(context).splashColor,
                  disabledBorderColor: Theme.of(context).accentColor,
                  color:
                      _dice == Dice.one ? Theme.of(context).accentColor : null,
                  child: Text('0'),
                  onPressed: _dice != Dice.one
                      ? () {
                          setState(() {
                            _dice = Dice.one;
                          });
                        }
                      : null,
                ),
                OutlineButton(
                  disabledTextColor: Theme.of(context).accentColor,
                  highlightedBorderColor: Theme.of(context).splashColor,
                  disabledBorderColor: Theme.of(context).accentColor,
                  color:
                      _dice == Dice.two ? Theme.of(context).accentColor : null,
                  child: Text('1'),
                  onPressed: _dice != Dice.two
                      ? () {
                          setState(() {
                            _dice = Dice.two;
                          });
                        }
                      : null,
                ),
                OutlineButton(
                  disabledTextColor: Theme.of(context).accentColor,
                  highlightedBorderColor: Theme.of(context).splashColor,
                  disabledBorderColor: Theme.of(context).accentColor,
                  color: _dice == Dice.three
                      ? Theme.of(context).accentColor
                      : null,
                  child: Text('4'),
                  onPressed: _dice != Dice.three
                      ? () {
                          setState(() {
                            _dice = Dice.three;
                          });
                        }
                      : null,
                ),
                PlatformButton(
                  color:
                      _dice == Dice.none ? Theme.of(context).accentColor : null,
                  child: Text('All Cases'),
                  onPressed: () {
                    setState(() {
                      _dice = Dice.none;
                    });
                  },
                ),
              ],
            ),
      appBar: AppBar(
        title: Text(widget.team.name),
        backgroundColor: Theme.of(context).accentColor,
        // actions: [
        //   PopupMenuButton<String>(
        //     onSelected: _choice,
        //     itemBuilder: (context) {
        //       return [
        //         PopupMenuItem<String>(
        //           child: Text('Delete Team'),
        //           value: 'Delete',
        //         ),
        //       ];
        //     },
        //   ),
        // ],
      ),
      body: ListView(children: [
        Padding(
          padding: EdgeInsets.only(left: 5, right: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: body(),
          ),
        )
      ]),
    );
  }

  // void _choice(String c) {
  //   if (c == 'Delete') {
  //     showDialog(
  //         context: context,
  //         child: PlatformAlert(
  //           title: Text('Delete Team'),
  //           content: Text('Are you sure?'),
  //           actions: [
  //             PlatformDialogAction(
  //               isDefaultAction: true,
  //               child: Text('Cancel'),
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //             PlatformDialogAction(
  //               isDefaultAction: false,
  //               isDestructive: true,
  //               child: Text('Confirm'),
  //               onPressed: () {
  //                 setState(() {
  //                   widget.event.deleteTeam(widget.team);
  //                 });
  //                 dataModel.saveEvents();
  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //           ],
  //         ));
  //   } else {
  //     showDialog(
  //         context: context,
  //         child: PlatformAlert(
  //           title: Text('Delete Team'),
  //           content: Text('Are you sure?'),
  //           actions: [
  //             PlatformDialogAction(
  //               isDefaultAction: true,
  //               child: Text('Cancel'),
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //             PlatformDialogAction(
  //               isDefaultAction: false,
  //               isDestructive: true,
  //               child: Text('Confirm'),
  //               onPressed: () {
  //                 setState(() {
  //                   widget.event.deleteTeam(widget.team);
  //                 });
  //                 dataModel.saveEvents();
  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //           ],
  //         ));
  //   }
  // }
}
