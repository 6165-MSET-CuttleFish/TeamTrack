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

class TeamView extends StatefulWidget {
  TeamView({
    super.key,
    required this.team,
    required this.event,
    this.isSoleWindow = true,
  });
  final Team team;
  final Event event;
  final bool isSoleWindow;
  @override
  State<TeamView> createState() => _TeamViewState(team);
}

class _TeamViewState extends State<TeamView> {
  _TeamViewState(this._team);
  Dice _dice = Dice.none;
  final _selections = {
    null: true,
    OpModeType.auto: false,
    OpModeType.tele: false,
    OpModeType.endgame: false,
    OpModeType.penalty: false,
  };
  Team _team;
  bool _showCycles = false;

  Score? maxScore;
  Score? teamMaxScore;

  @override
  void initState() {
    maxScore = Score('', Dice.none, widget.event.gameName);
    maxScore?.getElements().forEach(
      (element) {
        element.normalCount = widget.event.teams.values
            .map(
              (team) => !element.isBool
                  ? team.scores.values
                      .map(
                        (score) => score
                            .getElements()
                            .firstWhere((e) => e.key == element.key,
                                orElse: () => ScoringElement.nullScore())
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
                                orElse: () => ScoringElement.nullScore())
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

  bool getSelection(OpModeType? opModeType) => _selections[opModeType] ?? false;

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
                    : Theme.of(context).textTheme.bodySmall,
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
                  element.normalCount = !element.isBool
                      ? _team.scores.values
                          .map(
                            (score) => score
                                .getElements()
                                .firstWhere((e) => e.key == element.key,
                                    orElse: () => ScoringElement.nullScore())
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
                                    orElse: () => ScoringElement.nullScore())
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
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 0,
                              children: [
                                for (final opModeType in opModeExt.getAll())
                                  MaterialButton(
                                    color: getSelection(opModeType)
                                        ? opModeType.getColor()
                                        : null,
                                    splashColor: opModeType.getColor(),
                                    onPressed: () {
                                      setState(
                                        () => _selections[opModeType] =
                                            !(_selections[opModeType] ?? true),
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
                      for (final opModeType in opModeExt.getAll())
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 10),
                          child: ScoreCard(
                            allianceTotal:
                                widget.event.statConfig.allianceTotal,
                            team: _team,
                            event: widget.event,
                            targetScore:
                                _team.targetScore?.getScoreDivision(opModeType),
                            scoreDivisions: _team.scores
                                .sortedScores()
                                .map((e) => e.getScoreDivision(opModeType))
                                .toList(),
                            dice: _dice,
                            removeOutliers:
                                widget.event.statConfig.removeOutliers,
                            matches: widget.event.getSortedMatches(true),
                            title: opModeType.getName(),
                            type: opModeType,
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
                                        fontSize: 10,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 35,
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
                              for (final opModeType in opModeExt.getAll())
                                LineChartBarData(
                                  show: _selections[opModeType] ?? false,
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
                                              type: opModeType)
                                          .removeOutliers(widget
                                              .event.statConfig.removeOutliers)
                                      : _team.scores
                                          .diceScores(_dice)
                                          .spots(opModeType)
                                          .removeOutliers(
                                            widget.event.statConfig
                                                .removeOutliers,
                                          ),
                                  color: opModeType.getColor(),
                                  isCurved: true,
                                  isStrokeCapRound: true,
                                  preventCurveOverShooting: true,
                                  barWidth: 5,
                                ),
                            ],
                          ),
                        )
                      : EmptyList(),
                ),
              ),
            ),
          ],
        )
      : Text('');
}
