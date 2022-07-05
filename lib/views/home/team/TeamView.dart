import 'package:teamtrack/components/Collapsible.dart';
import 'package:teamtrack/components/EmptyList.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/components/ScoreCard.dart';
import 'package:teamtrack/components/ScoringElementStats.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/change/ChangeList.dart';
import 'package:teamtrack/views/home/match/MatchList.dart';
import 'package:teamtrack/views/home/match/MatchView.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teamtrack/components/CheckList.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:teamtrack/functions/Extensions.dart';

class TeamView extends StatefulWidget {
  TeamView({
    Key? key,
    required this.team,
    required this.event,
    this.isSoleWindow = true,
  }) : super(key: key);
  final Team team;
  final Event event;
  final bool isSoleWindow;
  @override
  _TeamViewState createState() => _TeamViewState(team);
}

class _TeamViewState extends State<TeamView> {
  _TeamViewState(this._team);
  Dice _dice = Dice.none;
  final _selections = [true, false, false, false];
  Team _team;
  bool _showCycles = false;
  final endgameColor = Colors.deepOrange;
  final penaltyColor = Colors.red;
  final teleColor = Colors.blue;
  final autoColor = Colors.green;
  final generalColor = Color.fromRGBO(230, 30, 213, 1);

  Score? maxScore;
  Score? teamMaxScore;

  @override
  void initState() {
    maxScore = Score('', Dice.none, widget.event.gameName);
    maxScore?.getElements().forEach(
      (element) {
        element.count = widget.event.teams.values
            .map(
              (team) => !element.isBool
                  ? team.scores.values
                      .map(
                        (score) => score
                            .getElements()
                            .firstWhere((e) => e.key == element.key,
                                orElse: () => ScoringElement())
                            .countFactoringAttempted(),
                      )
                      .whereType<int>()
                      .median()
                      .toInt()
                  : team.scores.values
                      .map(
                        (score) => score
                            .getElements()
                            .firstWhere((e) => e.key == element.key,
                                orElse: () => ScoringElement())
                            .countFactoringAttempted(),
                      )
                      .whereType<int>()
                      .accuracy()
                      .toInt(),
            )
            .maxValue()
            .toInt();
      },
    );
    super.initState();
  }

  bool getSelection(OpModeType? opModeType) {
    if (opModeType == null) {
      return _selections[0];
    } else if (opModeType == OpModeType.auto) {
      return _selections[1];
    } else if (opModeType == OpModeType.tele) {
      return _selections[2];
    } else if (opModeType == OpModeType.endgame) {
      return _selections[3];
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: NewPlatform.isIOS
            ? SafeArea(
                child: CupertinoSlidingSegmentedControl(
                  groupValue: _dice,
                  children: Dice.values.asMap().map(
                        (key, value) => MapEntry(
                          value,
                          Text(
                            value == Dice.none
                                ? 'All Cases'
                                : value.toVal(
                                    widget.event.gameName,
                                  ),
                          ),
                        ),
                      ),
                  onValueChanged: (Dice? newDice) => setState(
                    () => _dice = newDice ?? Dice.none,
                  ),
                ),
              )
            : ButtonBar(
                alignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: _dice == Dice.one
                          ? MaterialStateProperty.all(
                              Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    child: Text(Dice.one.toVal(widget.event.gameName)),
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
                  OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: _dice == Dice.two
                          ? MaterialStateProperty.all(
                              Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    child: Text(Dice.two.toVal(widget.event.gameName)),
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
                  OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: _dice == Dice.three
                          ? MaterialStateProperty.all(
                              Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    child: Text(Dice.three.toVal(widget.event.gameName)),
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
                    color: _dice == Dice.none
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    child: Text('All Cases'),
                    onPressed: () => setState(
                      () => _dice = Dice.none,
                    ),
                  ),
                ],
              ),
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
                    : Theme.of(context).textTheme.caption,
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
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
        ),
        body: StreamBuilder<DatabaseEvent>(
          stream: widget.isSoleWindow ? widget.event.getRef()?.onValue : null,
          builder: (context, eventHandler) {
            _team = widget.team;
            if (eventHandler.hasData && !eventHandler.hasError) {
              widget.event.updateLocal(
                json.decode(
                  json.encode(eventHandler.data?.snapshot.value),
                ),
                context,
              );
              _team = widget.event.teams[widget.team.number] ?? Team.nullTeam();
              teamMaxScore = Score('', Dice.none, widget.event.gameName);
              teamMaxScore?.getElements().forEach(
                (element) {
                  element.count = !element.isBool
                      ? _team.scores.values
                          .map(
                            (score) => score
                                .getElements()
                                .firstWhere((e) => e.key == element.key,
                                    orElse: () => ScoringElement())
                                .countFactoringAttempted(),
                          )
                          .whereType<int>()
                          .toList()
                          .median()
                          .toInt()
                      : _team.scores.values
                          .map(
                            (score) => score
                                .getElements()
                                .firstWhere((e) => e.key == element.key,
                                    orElse: () => ScoringElement())
                                .countFactoringAttempted(),
                          )
                          .whereType<int>()
                          .accuracy()
                          .toInt();
                },
              );
            }
            return ListView(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 5, right: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Collapsible(
                        isCollapsed: _team.scores.diceScores(_dice).length <= 1,
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
                                for (final opModeType in [
                                  null,
                                  OpModeType.auto,
                                  OpModeType.tele,
                                  OpModeType.endgame
                                ])
                                  FlatButton(
                                    color: getSelection(opModeType)
                                        ? opModeType.getColor()
                                        : null,
                                    splashColor: opModeType.getColor(),
                                    onPressed: () {
                                      setState(
                                        () {
                                          if (opModeType == null) {
                                            _selections[0] = !_selections[0];
                                          } else if (opModeType ==
                                              OpModeType.auto) {
                                            _selections[1] = !_selections[1];
                                          } else if (opModeType ==
                                              OpModeType.tele) {
                                            _selections[2] = !_selections[2];
                                          } else if (opModeType ==
                                              OpModeType.endgame) {
                                            _selections[3] = !_selections[3];
                                          }
                                        },
                                      );
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                      side: BorderSide(
                                        color: opModeType.getColor(),
                                      ),
                                    ),
                                    child: Text(opModeType.getName()),
                                  ),
                              ],
                            ),
                            _lineChart(),
                          ],
                        ),
                      ),
                      if (widget.isSoleWindow)
                        Container(
                          width: MediaQuery.of(context).size.width,
                          child: PlatformButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                platformPageRoute(
                                  builder: (context) => MatchList(
                                    event: widget.event,
                                    team: _team,
                                    ascending: false,
                                  ),
                                ),
                              );
                              setState(() {});
                            },
                            color: CupertinoColors.systemGreen,
                            child: Text('Matches'),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.all(5),
                      ),
                      if (widget.isSoleWindow)
                        Container(
                          width: MediaQuery.of(context).size.width / 2,
                          child: PlatformButton(
                            onPressed: () async {
                              if (_team.targetScore == null) {
                                _team.targetScore = Score(
                                  Uuid().v4(),
                                  Dice.none,
                                  widget.event.gameName,
                                );
                                await widget.event
                                    .getRef()
                                    ?.child('teams/${widget.team.number}')
                                    .runTransaction((mutableData) {
                                  (mutableData as Map?)?['targetScore'] = Score(
                                    Uuid().v4(),
                                    Dice.none,
                                    widget.event.gameName,
                                  ).toJson();
                                  return Transaction.success(mutableData);
                                });
                                dataModel.saveEvents();
                              }
                              await Navigator.push(
                                context,
                                platformPageRoute(
                                  builder: (context) => MatchView(
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
                      for (final opModeType in [
                        null,
                        OpModeType.auto,
                        OpModeType.tele,
                        OpModeType.endgame
                      ])
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 10),
                          child: ScoreCard(
                            allianceTotal:
                                widget.event.statConfig.allianceTotal,
                            team: _team,
                            event: widget.event,
                            scoreDivisions: _team.scores.values
                                .map((e) => e.getScoreDivision(opModeType))
                                .toList(),
                            dice: _dice,
                            removeOutliers:
                                widget.event.statConfig.removeOutliers,
                            matches: widget.event.getSortedMatches(true),
                            title: opModeType.getName(),
                            type: opModeType,
                            elements: opModeType != null
                                ? Column(
                                    children: teamMaxScore
                                            ?.getScoreDivision(opModeType)
                                            .getElements()
                                            .parse(putNone: false)
                                            .map(
                                              (element) => ScoringElementStats(
                                                element: element,
                                                maxElement: maxScore
                                                        ?.getScoreDivision(
                                                            opModeType)
                                                        .getElements()
                                                        .parse(putNone: false)
                                                        .firstWhere(
                                                          (e) =>
                                                              e.key ==
                                                              element.key,
                                                          orElse: () =>
                                                              ScoringElement(),
                                                        ) ??
                                                    element,
                                              ),
                                            )
                                            .toList() ??
                                        [],
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),
                )
              ],
            );
          },
        ),
      );

  Widget _lineChart() => _team.scores.diceScores(_dice).length > 1
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
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      right: 50.0, left: 12.0, top: 24, bottom: 12),
                  child: !_showCycles
                      ? LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              horizontalInterval: 1.0,
                              show: true,
                              drawVerticalLine: true,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.transparent,
                                );
                              },
                              getDrawingVerticalLine: (value) {
                                return FlLine(
                                  color: Colors.transparent,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, titleMeta) {
                                    return Text(
                                        value == value.toInt()
                                            ? (value + 1).toInt().toString()
                                            : "",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10));
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  // getTitlesWidget: (value, titleMeta) {
                                  //   return Text(value.toInt().toString(),
                                  //       style: TextStyle(
                                  //         fontWeight: FontWeight.bold,
                                  //         fontSize: 15,
                                  //       ));
                                  // },
                                  reservedSize: 35,
                                  //interval: 15,
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: false,
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: false,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(
                                  color: const Color(0xff37434d), width: 1),
                            ),
                            minX: 0,
                            minY: 0,
                            maxY: [
                              widget.event.statConfig.allianceTotal
                                  ? widget.event.matches.values
                                      .toList()
                                      .maxAllianceScore(dice: _dice)
                                      .toDouble()
                                  : widget.event.teams.maxScore(
                                      _dice,
                                      widget.event.statConfig.removeOutliers,
                                      null,
                                    ),
                              _team.targetScore?.total()?.toDouble() ?? 0.0
                            ].maxValue(),
                            lineBarsData: [
                              LineChartBarData(
                                belowBarData: _team.targetScore != null
                                    ? BarAreaData(
                                        show: true,
                                        color: Colors.lightGreenAccent
                                            .withOpacity(0.5),
                                        cutOffY: _team.targetScore
                                            ?.total()
                                            ?.toDouble(),
                                        applyCutOffY: true,
                                      )
                                    : null,
                                aboveBarData: _team.targetScore != null
                                    ? BarAreaData(
                                        show: true,
                                        color:
                                            Colors.redAccent.withOpacity(0.5),
                                        cutOffY: _team.targetScore
                                            ?.total()
                                            ?.toDouble(),
                                        applyCutOffY: true,
                                      )
                                    : null,
                                show: _selections[0],
                                spots: widget.event.statConfig.allianceTotal
                                    ? widget.event
                                        .getSortedMatches(true)
                                        .where((e) =>
                                            e.dice == _dice ||
                                            _dice == Dice.none)
                                        .toList()
                                        .spots(
                                          _team,
                                          _dice,
                                          widget.event.statConfig.showPenalties,
                                        )
                                        .removeOutliers(
                                          widget
                                              .event.statConfig.removeOutliers,
                                        )
                                    : _team.scores
                                        .diceScores(_dice)
                                        .spots(
                                          null,
                                          showPenalties: widget
                                              .event.statConfig.showPenalties,
                                        )
                                        .removeOutliers(
                                          widget
                                              .event.statConfig.removeOutliers,
                                        ),
                                color: generalColor,
                                isCurved: true,
                                isStrokeCapRound: true,
                                preventCurveOverShooting: true,
                                barWidth: 5,
                              ),
                              LineChartBarData(
                                show: _selections[1],
                                spots: widget.event.statConfig.allianceTotal
                                    ? widget.event
                                        .getSortedMatches(true)
                                        .where(
                                          (e) =>
                                              e.dice == _dice ||
                                              _dice == Dice.none,
                                        )
                                        .toList()
                                        .spots(_team, _dice, false,
                                            type: OpModeType.auto)
                                        .removeOutliers(widget
                                            .event.statConfig.removeOutliers)
                                    : _team.scores
                                        .diceScores(_dice)
                                        .spots(OpModeType.auto)
                                        .removeOutliers(
                                          widget
                                              .event.statConfig.removeOutliers,
                                        ),
                                color: autoColor,
                                isCurved: true,
                                isStrokeCapRound: true,
                                preventCurveOverShooting: true,
                                barWidth: 5,
                              ),
                              LineChartBarData(
                                show: _selections[2],
                                spots: widget.event.statConfig.allianceTotal
                                    ? widget.event
                                        .getSortedMatches(true)
                                        .where(
                                          (e) =>
                                              e.dice == _dice ||
                                              _dice == Dice.none,
                                        )
                                        .toList()
                                        .spots(_team, _dice, false,
                                            type: OpModeType.tele)
                                        .removeOutliers(
                                          widget
                                              .event.statConfig.removeOutliers,
                                        )
                                    : _team.scores
                                        .diceScores(_dice)
                                        .spots(OpModeType.tele)
                                        .removeOutliers(
                                          widget
                                              .event.statConfig.removeOutliers,
                                        ),
                                color: teleColor,
                                isCurved: true,
                                isStrokeCapRound: true,
                                preventCurveOverShooting: true,
                                barWidth: 5,
                              ),
                              LineChartBarData(
                                show: _selections[3],
                                spots: widget.event.statConfig.allianceTotal
                                    ? widget.event
                                        .getSortedMatches(true)
                                        .where(
                                          (e) =>
                                              e.dice == _dice ||
                                              _dice == Dice.none,
                                        )
                                        .toList()
                                        .spots(_team, _dice, false,
                                            type: OpModeType.endgame)
                                        .removeOutliers(widget
                                            .event.statConfig.removeOutliers)
                                    : _team.scores
                                        .diceScores(_dice)
                                        .spots(OpModeType.endgame)
                                        .removeOutliers(
                                          widget
                                              .event.statConfig.removeOutliers,
                                        ),
                                color: endgameColor,
                                isCurved: true,
                                isStrokeCapRound: true,
                                preventCurveOverShooting: true,
                                barWidth: 5,
                              ),
                            ],
                          ),
                        )
                      : EmptyList(),
                  // : SfCartesianChart(
                  //     tooltipBehavior: TooltipBehavior(enable: true),
                  //     title: ChartTitle(
                  //       text: 'Cycle Times and Misses',
                  //       borderWidth: 2,
                  //       // Aligns the chart title to left
                  //       alignment: ChartAlignment.near,
                  //       textStyle: TextStyle(
                  //         color: Colors.white,
                  //         fontSize: 14,
                  //       ),
                  //     ),
                  //     series: <ChartSeries>[
                  //       BoxAndWhiskerSeries<List<double>, int>(
                  //         xAxisName: "Match",
                  //         yAxisName: "Cycle Times (seconds)",
                  //         gradient: LinearGradient(
                  //           begin: Alignment.topCenter,
                  //           end: Alignment.bottomCenter,
                  //           colors: [Colors.deepPurple, Colors.green],
                  //         ),
                  //         dataSource: _team.scores
                  //             .diceScores(_dice)
                  //             .map((e) => [0.0])
                  //             .toList(),
                  //         boxPlotMode: BoxPlotMode.exclusive,
                  //         xValueMapper: (List<double> cycles, _) => _ + 1,
                  //         yValueMapper: (List<double> cycles, _) =>
                  //             cycles.length != 0 ? cycles : [0, 0, 0, 0],
                  //       ),
                  //       LineSeries<int, int>(
                  //         xAxisName: "Match",
                  //         yAxisName: "Total Misses",
                  //         dashArray: [10],
                  //         width: 2,
                  //         color: Colors.red,
                  //         dataSource: _team.scores
                  //             .diceScores(_dice)
                  //             .map((e) => e.teleScore.misses.count)
                  //             .toList(),
                  //         xValueMapper: (int misses, _) => _ + 1,
                  //         yValueMapper: (int misses, _) => misses,
                  //       ),
                  //       if (_selections[2])
                  //         LineSeries<int, int>(
                  //           xAxisName: "Match",
                  //           yAxisName: "Total Tele-Op Cycles",
                  //           width: 2,
                  //           color: teleColor,
                  //           dataSource: _team.scores
                  //               .diceScores(_dice)
                  //               .map((e) => 0)
                  //               .toList(),
                  //           xValueMapper: (int misses, _) => _ + 1,
                  //           yValueMapper: (int misses, _) => misses,
                  //         ),
                  //       if (_selections[3])
                  //         LineSeries<int, int>(
                  //           xAxisName: "Match",
                  //           yAxisName: "Total Endgame Cycles",
                  //           width: 2,
                  //           color: endgameColor,
                  //           dataSource: _team.scores
                  //               .diceScores(_dice)
                  //               .map((e) => [1])
                  //               .toList(),
                  //           xValueMapper: (int misses, _) => _ + 1,
                  //           yValueMapper: (int misses, _) => misses,
                  //         ),
                  //     ],
                  //   ),
                ),
              ),
            ),
            // SizedBox(
            //   width: 45,
            //   height: 90,
            //   child: OutlinedButton(
            //     onPressed: () => setState(
            //       () => _showCycles = !_showCycles,
            //     ),
            //     child: Text(
            //       'Show Cycle Times',
            //       style: Theme.of(context).textTheme.button,
            //       textAlign: TextAlign.center,
            //     ),
            //     style: ButtonStyle(
            //       backgroundColor: MaterialStateProperty.all(
            //         _showCycles
            //             ? Colors.grey.withOpacity(0.3)
            //             : Colors.cyan.withOpacity(0.3),
            //       ),
            //       shape: MaterialStateProperty.all(
            //         RoundedRectangleBorder(
            //           borderRadius: BorderRadius.all(
            //             Radius.circular(20),
            //           ),
            //         ),
            //       ),
            //       alignment: Alignment.center,
            //       padding: MaterialStateProperty.all(
            //         EdgeInsets.all(0),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        )
      : Text('');
}
