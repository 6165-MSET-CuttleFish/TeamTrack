import 'dart:io';
import 'dart:math';
import 'package:teamtrack/Frontend/Assets/Collapsible.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:teamtrack/Frontend/MatchList.dart';
import 'package:teamtrack/Frontend/MatchView.dart';
import 'package:teamtrack/backend.dart';
import 'package:teamtrack/score.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart' as Database;
import 'dart:convert';

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
  Team _team;
  @override
  Widget build(BuildContext context) {
    _team = widget.team;
    return Scaffold(
      bottomNavigationBar: Platform.isIOS
          ? SafeArea(
              child: CupertinoSlidingSegmentedControl(
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
            ))
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
        title: Text(_team.name),
        backgroundColor: Theme.of(context).accentColor,
      ),
      body: StreamBuilder<Database.Event>(
          stream: DatabaseServices(id: widget.event.id).getEventChanges,
          builder: (context, eventHandler) {
            if (eventHandler.hasData &&
                !eventHandler.hasError &&
                !dataModel.isProcessing) {
              widget.event.updateLocal(
                  json.decode(json.encode(eventHandler.data.snapshot.value)));
              _team = widget.event.teams.firstWhere(
                  (element) => element.number == _team.number, orElse: () {
                Navigator.of(context).pop();
                return Team.nullTeam();
              });
            }
            return ListView(children: [
              Padding(
                padding: EdgeInsets.only(left: 5, right: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: body(),
                ),
              )
            ]);
          }),
    );
  }

  Widget _lineChart() {
    return _team.scores.diceScores(_dice).length >= 2
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
                    maxX: _team.scores.diceScores(_dice).length.toDouble() - 1,
                    minY: 0,
                    maxY: [
                      widget.event.matches.maxAllianceScore(_team).toDouble(),
                      _team.targetScore != null
                          ? _team.targetScore.total().toDouble()
                          : 0.0
                    ].reduce(max),
                    lineBarsData: [
                      LineChartBarData(
                          belowBarData: _team.targetScore != null
                              ? BarAreaData(
                                  show: true,
                                  colors: [
                                    Colors.lightGreenAccent.withOpacity(0.2)
                                  ],
                                  cutOffY:
                                      _team.targetScore?.total()?.toDouble(),
                                  applyCutOffY: true,
                                )
                              : null,
                          aboveBarData: _team.targetScore != null
                              ? BarAreaData(
                                  show: true,
                                  colors: [Colors.redAccent.withOpacity(0.2)],
                                  cutOffY:
                                      _team.targetScore?.total()?.toDouble(),
                                  applyCutOffY: true,
                                )
                              : null,
                          show: _selections[0] &&
                              widget.event.type != EventType.remote,
                          spots: widget.event.matches
                              .where(
                                  (e) => e.dice == _dice || _dice == Dice.none)
                              .toList()
                              .spots(_team, _dice),
                          colors: [Color.fromRGBO(255, 166, 0, 1)],
                          isCurved: true,
                          isStrokeCapRound: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                          shadow: Shadow(color: Colors.green, blurRadius: 5)),
                      LineChartBarData(
                          belowBarData: _team.targetScore != null
                              ? BarAreaData(
                                  show: true,
                                  colors: [
                                    Colors.lightGreenAccent.withOpacity(0.2)
                                  ],
                                  cutOffY:
                                      _team.targetScore?.total()?.toDouble(),
                                  applyCutOffY: true,
                                )
                              : null,
                          aboveBarData: _team.targetScore != null
                              ? BarAreaData(
                                  show: true,
                                  colors: [Colors.redAccent.withOpacity(0.2)],
                                  cutOffY:
                                      _team.targetScore?.total()?.toDouble(),
                                  applyCutOffY: true,
                                )
                              : null,
                          show: _selections[1],
                          spots: _dice != Dice.none
                              ? _team.scores
                                  .where((e) => e.dice == _dice)
                                  .toList()
                                  .spots()
                              : _team.scores.spots(),
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
                              ? _team.scores
                                  .where((e) => e.dice == _dice)
                                  .toList()
                                  .autoSpots()
                              : _team.scores.autoSpots(),
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
                              ? _team.scores
                                  .where((e) => e.dice == _dice)
                                  .toList()
                                  .teleSpots()
                              : _team.scores.teleSpots(),
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
                              ? _team.scores
                                  .where((e) => e.dice == _dice)
                                  .toList()
                                  .endSpots()
                              : _team.scores.endSpots(),
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
        isCollapsed: _team.scores.diceScores(_dice).length < 2,
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
                              team: _team,
                            )));
                setState(() {});
              } else {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MatchList(
                              event: widget.event,
                              team: _team,
                            )));
                setState(() {});
              }
            },
            color: CupertinoColors.systemGreen,
            child: Text('Matches'),
          )),
      if (Platform.isIOS) Padding(padding: EdgeInsets.all(5)),
      Container(
          width: MediaQuery.of(context).size.width / 2,
          child: PlatformButton(
            onPressed: () async {
              if (_team.targetScore == null) {
                _team.targetScore = Score(Uuid().v4(), Dice.none);
              }
              if (Platform.isIOS) {
                await Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => MatchView(
                              match: Match.defaultMatch(EventType.remote),
                              team: _team,
                              event: widget.event,
                            )));
                setState(() {});
              } else {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MatchView(
                              match: Match.defaultMatch(EventType.remote),
                              team: _team,
                              event: widget.event,
                            )));
                setState(() {});
              }
            },
            color: Colors.indigoAccent,
            child: Text('Target'),
          )),
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(
          'General',
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ),
      ScoreCard(
        team: _team,
        event: widget.event,
        type: "general",
        scoreDivisions: _team.scores,
        dice: _dice,
      ),
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
      ScoreCard(
        team: _team,
        event: widget.event,
        type: "auto",
        scoreDivisions: _team.scores.map((e) => e.autoScore).toList(),
        dice: _dice,
      ),
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(
          'Tele-Op',
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ),
      ScoreCard(
        team: _team,
        event: widget.event,
        type: "tele",
        scoreDivisions: _team.scores.map((e) => e.teleScore).toList(),
        dice: _dice,
      ),
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(
          'Endgame',
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ),
      ScoreCard(
        team: _team,
        event: widget.event,
        type: "endgame",
        scoreDivisions: _team.scores.map((e) => e.endgameScore).toList(),
        dice: _dice,
      ),
      Padding(
        padding: EdgeInsets.all(130),
      ),
    ];
  }
}
