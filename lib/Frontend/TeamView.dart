import 'dart:math';
import 'package:teamtrack/Frontend/Assets/Collapsible.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:teamtrack/Frontend/ChangeList.dart';
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
import 'package:syncfusion_flutter_charts/charts.dart';

class TeamView extends StatefulWidget {
  TeamView({Key? key, required this.team, required this.event})
      : super(key: key);
  final Team team;
  final Event event;
  @override
  _TeamView createState() => _TeamView();
}

class _TeamView extends State<TeamView> {
  Dice _dice = Dice.none;
  final _selections = [true, true, false, false, false];
  Team _team = Team.nullTeam();
  bool removeOutliers = false;
  final endgameColor = Colors.red;
  final teleColor = Colors.blue;
  final autoColor = Colors.green;
  final generalColor = Color.fromRGBO(230, 30, 213, 1);
  bool showPenalties = false;
  bool _showCycles = false;
  @override
  Widget build(BuildContext context) {
    _team = widget.team;
    return Scaffold(
      bottomNavigationBar: NewPlatform.isIOS()
          ? SafeArea(
              child: CupertinoSlidingSegmentedControl(
                groupValue: _dice,
                children: <Dice, Widget>{
                  Dice.one: Text('0'),
                  Dice.two: Text('1'),
                  Dice.three: Text('4'),
                  Dice.none: Text('All Cases')
                },
                onValueChanged: (Dice? newDice) {
                  setState(
                    () {
                      _dice = newDice ?? Dice.none;
                    },
                  );
                },
              ),
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
                          setState(
                            () {
                              _dice = Dice.one;
                            },
                          );
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
                          setState(
                            () {
                              _dice = Dice.two;
                            },
                          );
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
                          setState(
                            () {
                              _dice = Dice.three;
                            },
                          );
                        }
                      : null,
                ),
                MaterialButton(
                  color:
                      _dice == Dice.none ? Theme.of(context).accentColor : null,
                  child: Text('All Cases'),
                  onPressed: () => setState(
                    () => _dice = Dice.none,
                  ),
                ),
              ],
            ),
      appBar: AppBar(
        title: Text(_team.name),
        backgroundColor: Theme.of(context).accentColor,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: removeOutliers,
                    onChanged: (_) => setState(
                      () {
                        removeOutliers = _ ?? false;
                        Navigator.pop(context);
                      },
                    ),
                    checkColor: Colors.black,
                    tileColor: Colors.green,
                    title: Text('Remove Outliers'),
                    subtitle: Icon(CupertinoIcons.arrow_branch),
                  ),
                  CheckboxListTile(
                    value: showPenalties,
                    onChanged: (_) {
                      setState(
                        () {
                          showPenalties = _ ?? false;
                          Navigator.pop(context);
                        },
                      );
                    },
                    checkColor: Colors.black,
                    tileColor: Colors.red,
                    title: Text('Include Penalties'),
                    subtitle: Icon(Icons.score_rounded),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.list),
            tooltip: 'Changelist',
            onPressed: () => Navigator.of(context).push(
              platformPageRoute(
                (context) => ChangeList(
                  team: _team,
                  event: widget.event,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<Database.Event>(
        stream: DatabaseServices(id: widget.event.id).getEventChanges,
        builder: (context, eventHandler) {
          if (eventHandler.hasData &&
              !eventHandler.hasError &&
              !dataModel.isProcessing) {
            widget.event.updateLocal(
              json.decode(
                json.encode(eventHandler.data?.snapshot.value),
              ),
            );
            _team = widget.event.teams[widget.team.number] ?? Team.nullTeam();
          }
          return ListView(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 5, right: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: body(),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _lineChart() => _team.scores.diceScores(_dice).length >= 2
      ? Stack(
          alignment: Alignment.topRight,
          children: [
            AspectRatio(
              aspectRatio: 1.20,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(18),
                  ),
                  color: Color(0xff232d37),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      right: 50.0, left: 12.0, top: 24, bottom: 12),
                  child: !_showCycles
                      ? LineChart(
                          LineChartData(
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
                                    fontSize: 10),
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
                                  if (value % 50 == 0)
                                    return value.toInt().toString();
                                  return '';
                                },
                                reservedSize: 28,
                                margin: 12,
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(
                                  color: const Color(0xff37434d), width: 1),
                            ),
                            minX: 0,
                            maxX: _team.scores
                                    .diceScores(_dice)
                                    .length
                                    .toDouble() -
                                1,
                            minY: 0,
                            maxY: [
                              widget.event.matches
                                  .maxAllianceScore(_team)
                                  .toDouble(),
                              _team.targetScore?.total().toDouble() ?? 0.0
                            ].reduce(max),
                            lineBarsData: [
                              LineChartBarData(
                                belowBarData: _team.targetScore != null
                                    ? BarAreaData(
                                        show: true,
                                        colors: [
                                          Colors.lightGreenAccent
                                              .withOpacity(0.2)
                                        ],
                                        cutOffY: _team.targetScore
                                            ?.total()
                                            .toDouble(),
                                        applyCutOffY: true,
                                      )
                                    : null,
                                aboveBarData: _team.targetScore != null
                                    ? BarAreaData(
                                        show: true,
                                        colors: [
                                          Colors.redAccent.withOpacity(0.2)
                                        ],
                                        cutOffY: _team.targetScore
                                            ?.total()
                                            .toDouble(),
                                        applyCutOffY: true,
                                      )
                                    : null,
                                show: _selections[0] &&
                                    widget.event.type != EventType.remote,
                                spots: widget.event.matches
                                    .where((e) =>
                                        e.dice == _dice || _dice == Dice.none)
                                    .toList()
                                    .spots(_team, _dice, showPenalties)
                                    .removeOutliers(removeOutliers),
                                colors: [
                                  Color.fromRGBO(255, 166, 0, 1),
                                ],
                                isCurved: true,
                                isStrokeCapRound: true,
                                preventCurveOverShooting: true,
                                barWidth: 5,
                              ),
                              LineChartBarData(
                                belowBarData: _team.targetScore != null
                                    ? BarAreaData(
                                        show: true,
                                        colors: [
                                          Colors.lightGreenAccent
                                              .withOpacity(0.2)
                                        ],
                                        cutOffY: _team.targetScore
                                            ?.total()
                                            .toDouble(),
                                        applyCutOffY: true,
                                      )
                                    : null,
                                aboveBarData: _team.targetScore != null
                                    ? BarAreaData(
                                        show: true,
                                        colors: [
                                          Colors.redAccent.withOpacity(0.2)
                                        ],
                                        cutOffY: _team.targetScore
                                            ?.total()
                                            .toDouble(),
                                        applyCutOffY: true,
                                      )
                                    : null,
                                show: _selections[1],
                                spots: _team.scores.values
                                    .where((e) =>
                                        e.dice == _dice || _dice == Dice.none)
                                    .toList()
                                    .spots(null, showPenalties: showPenalties)
                                    .removeOutliers(removeOutliers),
                                colors: [
                                  generalColor,
                                ],
                                isCurved: true,
                                isStrokeCapRound: true,
                                preventCurveOverShooting: true,
                                barWidth: 5,
                              ),
                              LineChartBarData(
                                show: _selections[2],
                                spots: _team.scores.values
                                    .where((e) =>
                                        e.dice == _dice || _dice == Dice.none)
                                    .toList()
                                    .spots(OpModeType.auto)
                                    .removeOutliers(removeOutliers),
                                colors: [
                                  autoColor,
                                ],
                                isCurved: true,
                                isStrokeCapRound: true,
                                preventCurveOverShooting: true,
                                barWidth: 5,
                              ),
                              LineChartBarData(
                                show: _selections[3],
                                spots: _team.scores.values
                                    .where((e) =>
                                        e.dice == _dice || _dice == Dice.none)
                                    .toList()
                                    .spots(OpModeType.tele)
                                    .removeOutliers(removeOutliers),
                                colors: [
                                  teleColor,
                                ],
                                isCurved: true,
                                isStrokeCapRound: true,
                                preventCurveOverShooting: true,
                                barWidth: 5,
                              ),
                              LineChartBarData(
                                show: _selections[4],
                                spots: _team.scores.values
                                    .where((e) =>
                                        e.dice == _dice || _dice == Dice.none)
                                    .toList()
                                    .spots(OpModeType.endgame)
                                    .removeOutliers(removeOutliers),
                                colors: [
                                  endgameColor,
                                ],
                                isCurved: true,
                                isStrokeCapRound: true,
                                preventCurveOverShooting: true,
                                barWidth: 5,
                              ),
                            ],
                          ),
                        )
                      : SfCartesianChart(
                          title: ChartTitle(
                              text: 'Cycle Times and Misses',
                              borderWidth: 2,
                              // Aligns the chart title to left
                              alignment: ChartAlignment.near,
                              textStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              )),
                          series: <ChartSeries>[
                            BoxAndWhiskerSeries<List<double>, int>(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Theme.of(context).accentColor,
                                  Theme.of(context).splashColor
                                ],
                              ),
                              dataSource: _team.scores
                                  .diceScores(_dice)
                                  .map((e) => e.teleScore.cycleTimes)
                                  .toList(),
                              boxPlotMode: BoxPlotMode.exclusive,
                              xValueMapper: (List<double> cycles, _) => _ + 1,
                              yValueMapper: (List<double> cycles, _) =>
                                  cycles.length != 0 ? cycles : [0, 0, 0, 0],
                            ),
                            ScatterSeries<int, int>(
                              dataSource: _team.scores
                                  .diceScores(_dice)
                                  .map((e) => e.teleScore.misses.count)
                                  .toList(),
                              xValueMapper: (int misses, _) => _ + 1,
                              yValueMapper: (int misses, _) => misses,
                            ),
                          ],
                        ),
                ),
              ),
            ),
            SizedBox(
              width: 45,
              height: 90,
              child: OutlinedButton(
                onPressed: () => setState(
                  () => _showCycles = !_showCycles,
                ),
                child: Text(
                  'Show Cycle Times',
                  style: TextStyle(
                    fontSize: 10,
                    color: _showCycles
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    _showCycles
                        ? Colors.grey.withOpacity(0.3)
                        : Colors.cyan.withOpacity(0.3),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: MaterialStateProperty.all(
                    EdgeInsets.all(0),
                  ),
                ),
              ),
            ),
          ],
        )
      : Text('');

  List<Widget> body() {
    return <Widget>[
      Collapsible(
        isCollapsed: _team.scores.diceScores(_dice).length < 2,
        child: Column(
          children: [
            Padding(
              padding: widget.event.type != EventType.remote
                  ? EdgeInsets.all(40)
                  : EdgeInsets.all(20),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 0,
              children: [
                if (widget.event.type != EventType.remote)
                  FlatButton(
                    color:
                        _selections[0] ? Color.fromRGBO(255, 166, 0, 1) : null,
                    splashColor: Color.fromRGBO(255, 166, 0, 1),
                    onPressed: () {
                      setState(
                        () {
                          _selections[0] = !_selections[0];
                        },
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      side: BorderSide(
                        color: Color.fromRGBO(255, 166, 0, 1),
                      ),
                    ),
                    child: Text('Alliance Total'),
                  ),
                FlatButton(
                  color: _selections[1] ? generalColor : null,
                  splashColor: generalColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(
                      color: generalColor,
                    ),
                  ),
                  child: Text('General'),
                  onPressed: () {
                    setState(
                      () {
                        _selections[1] = !_selections[1];
                      },
                    );
                  },
                ),
                FlatButton(
                  color: _selections[2] ? autoColor : null,
                  splashColor: autoColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: autoColor),
                  ),
                  child: Text('Autonomous'),
                  onPressed: () {
                    setState(
                      () {
                        _selections[2] = !_selections[2];
                      },
                    );
                  },
                ),
                FlatButton(
                  color: _selections[3] ? teleColor : null,
                  splashColor: teleColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: teleColor),
                  ),
                  child: Text('Tele-Op'),
                  onPressed: () {
                    setState(
                      () {
                        _selections[3] = !_selections[3];
                      },
                    );
                  },
                ),
                FlatButton(
                  color: _selections[4] ? endgameColor : null,
                  splashColor: endgameColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: endgameColor),
                  ),
                  child: Text('Endgame'),
                  onPressed: () {
                    setState(
                      () {
                        _selections[4] = !_selections[4];
                      },
                    );
                  },
                ),
              ],
            ),
            _lineChart(),
          ],
        ),
      ),
      Container(
        width: MediaQuery.of(context).size.width,
        child: PlatformButton(
          onPressed: () async {
            await Navigator.push(
              context,
              platformPageRoute(
                (context) => MatchList(
                  event: widget.event,
                  team: _team,
                ),
              ),
            );
            setState(() {});
          },
          color: CupertinoColors.systemGreen,
          child: Text('Matches'),
        ),
      ),
      if (NewPlatform.isIOS())
        Padding(
          padding: EdgeInsets.all(5),
        ),
      Container(
        width: MediaQuery.of(context).size.width / 2,
        child: PlatformButton(
          onPressed: () async {
            if (_team.targetScore == null) {
              _team.targetScore = Score(
                Uuid().v4(),
                Dice.none,
              );
              widget.event.getRef()?.runTransaction((mutableData) async {
                if ((mutableData.value['teams'] as Map)
                    .containsKey(widget.team.number)) {
                  mutableData.value['teams'][widget.team.number]
                      ['targetScore'] = Score(Uuid().v4(), Dice.none).toJson();
                }
                return mutableData;
              });
              dataModel.saveEvents();
              //dataModel.uploadEvent(widget.event);
            }
            await Navigator.push(
              context,
              platformPageRoute(
                (context) => MatchView(
                  match: Match.defaultMatch(EventType.remote),
                  event: widget.event,
                  team: _team,
                ),
              ),
            );
            setState(() {});
          },
          color: Colors.indigoAccent,
          child: Text('Target'),
        ),
      ),
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
        scoreDivisions: _team.scores.values.toList(),
        dice: _dice,
        removeOutliers: removeOutliers,
        matches:
            widget.event.type == EventType.remote ? null : widget.event.matches,
      ),
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(
          'Autonomous',
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ),
      ScoreCard(
        team: _team,
        event: widget.event,
        type: OpModeType.auto,
        scoreDivisions: _team.scores.values.map((e) => e.autoScore).toList(),
        dice: _dice,
        removeOutliers: removeOutliers,
        matches:
            widget.event.type == EventType.remote ? null : widget.event.matches,
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
        type: OpModeType.tele,
        scoreDivisions: _team.scores.values.map((e) => e.teleScore).toList(),
        dice: _dice,
        removeOutliers: removeOutliers,
        matches:
            widget.event.type == EventType.remote ? null : widget.event.matches,
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
        type: OpModeType.endgame,
        scoreDivisions: _team.scores.values.map((e) => e.endgameScore).toList(),
        dice: _dice,
        removeOutliers: removeOutliers,
        matches:
            widget.event.type == EventType.remote ? null : widget.event.matches,
      ),
      Padding(
        padding: EdgeInsets.all(130),
      ),
    ];
  }
}
