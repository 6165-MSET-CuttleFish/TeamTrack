import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:flutter/foundation.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:teamtrack/backend.dart';
import 'package:teamtrack/score.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class MatchView extends StatefulWidget {
  MatchView({Key? key, this.match, this.team, required this.event})
      : super(key: key);
  @required
  final Match? match;
  final Team? team;
  final Event event;
  @override
  State createState() => _MatchView(match, team, event);
}

class _MatchView extends State<MatchView> {
  Team? _selectedTeam;
  Alliance? _selectedAlliance;
  Color _color = CupertinoColors.systemRed;
  Score? _score;
  int _view = 0;
  Match? _match;
  bool _showPenalties = false;
  final Stream<int> _periodicStream =
      Stream.periodic(const Duration(milliseconds: 100), (i) => i);
  double _time = 0;
  List<double> lapses = [];
  int? _previousStreamValue = 0;
  bool _paused = true;
  bool _allowView = false;
  _MatchView(this._match, Team? team, Event event) {
    _selectedAlliance = _match?.red;
    if (team != null) {
      _score = team.targetScore;
      _selectedTeam = team;
      _color = CupertinoColors.systemGreen;
    } else {
      _selectedTeam = _match?.red?.team1;
      _score = _selectedTeam?.scores[_match?.id];
      if (_match?.type == EventType.remote)
        _color = CupertinoColors.systemGreen;
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Database.Event>(
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
            if (widget.team == null) {
              _match = widget.event.matches.firstWhere(
                (element) => element.id == _match?.id,
                orElse: () {
                  return Match.defaultMatch(EventType.remote);
                },
              );
            }
            _selectedTeam = widget.event.teams[_selectedTeam?.number];
            _selectedAlliance = _match?.red;
            if (_color == CupertinoColors.systemRed)
              _selectedAlliance = _match?.red;
            else if (_color == CupertinoColors.systemBlue)
              _selectedAlliance = _match?.blue;
            if (widget.team != null) {
              _score = _selectedTeam?.targetScore;
            } else {
              _score = _selectedTeam?.scores[_match?.id];
              _score?.teleScore.getElements().forEach((element) {
                element.incrementValue = incrementValue.count;
              });
            }
          }
          return StreamBuilder<int>(
            stream: _periodicStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data != _previousStreamValue) {
                  _previousStreamValue = snapshot.data;
                  if (!_paused) {
                    _time += 1 / 10;
                  }
                }
              }
              return DefaultTabController(
                length: 3,
                child: Scaffold(
                  appBar: AppBar(
                    backgroundColor: _color,
                    title: Text('Match Stats'),
                    elevation: 0,
                    actions: [
                      Center(
                        child: Text(
                          _time.roundToDouble().toString(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                        onPressed: () => setState(() => _paused = !_paused),
                      ),
                      IconButton(
                        icon: Icon(Icons.stop),
                        onPressed: () => setState(
                          () {
                            _paused = true;
                            _time = 0;
                          },
                        ),
                      ),
                    ],
                  ),
                  body: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _color,
                          Theme.of(context).canvasColor,
                          Theme.of(context).canvasColor,
                          Theme.of(context).canvasColor,
                          Theme.of(context).canvasColor,
                          Theme.of(context).canvasColor,
                          Theme.of(context).canvasColor,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          if (_match?.type != EventType.remote &&
                              widget.team == null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  width: 100,
                                  child: Text(
                                      _match?.redScore(
                                              showPenalties: _showPenalties) ??
                                          '0',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline4),
                                ),
                                Container(
                                  child: Text('-',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline4),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  width: 100,
                                  child: Text(
                                      _match?.blueScore(
                                              showPenalties: _showPenalties) ??
                                          '0',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline4),
                                ),
                              ],
                            ),
                          if (_match?.type != EventType.remote &&
                              _match != null)
                            buttonRow(),
                          Text(
                              (_selectedTeam?.name ?? '') +
                                  ' : ' +
                                  (_score
                                          ?.total(
                                            showPenalties: widget.event.type ==
                                                    EventType.remote
                                                ? _showPenalties
                                                : false,
                                          )
                                          .toString() ??
                                      ''),
                              style: Theme.of(context).textTheme.headline6),
                          if (widget.team == null)
                            DropdownButton<Dice>(
                              value: _match?.dice,
                              icon: Icon(Icons.height_rounded),
                              iconSize: 24,
                              elevation: 16,
                              style: TextStyle(
                                  color: Theme.of(context).accentColor),
                              underline: Container(
                                height: 0.5,
                                color: Colors.deepPurple,
                              ),
                              onChanged: (newValue) {
                                setState(
                                  () {
                                    HapticFeedback.mediumImpact();
                                    _match?.setDice(newValue ?? Dice.one);
                                  },
                                );
                                widget.event
                                    .getRef()
                                    ?.runTransaction((mutableData) async {
                                  final matchIndex = (mutableData
                                          .value['matches'] as List)
                                      .indexWhere((element) =>
                                          element['id'] == (_match?.id ?? ''));
                                  mutableData.value['matches'][matchIndex]
                                      ['dice'] = newValue.toString();
                                  return mutableData;
                                });
                                dataModel.saveEvents();
                              },
                              items: [Dice.one, Dice.two, Dice.three]
                                  .map<DropdownMenuItem<Dice>>(
                                (value) {
                                  return DropdownMenuItem<Dice>(
                                    value: value,
                                    child: Text(
                                      'Stack Height : ' +
                                          value.stackHeight().toString(),
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                          if (getPenaltyAlliance() != null)
                            ExpansionTile(
                                leading: Checkbox(
                                  checkColor: Colors.black,
                                  fillColor:
                                      MaterialStateProperty.all(Colors.red),
                                  value: _showPenalties,
                                  onChanged: (_) => _showPenalties = _ ?? false,
                                ),
                                title: Text(
                                  'Penalties',
                                  style: TextStyle(fontSize: 16),
                                ),
                                children: _score?.penalties
                                        .getElements()
                                        .map(
                                          (e) => Incrementor(
                                            element: e,
                                            onPressed: stateSetter,
                                            event: widget.event,
                                            team: _selectedTeam,
                                            score: _score,
                                            opModeType: OpModeType.penalty,
                                            isTargetScore: widget.team != null,
                                          ),
                                        )
                                        .toList() ??
                                    []),
                          Padding(
                            padding: EdgeInsets.only(
                                left: 25, right: 25, bottom: 10, top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  child: Text(
                                    'Autonomous : ' +
                                        (_score?.autoScore.total().toString() ??
                                            '0'),
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                ),
                                SizedBox(
                                  child: Text(
                                      'Tele-Op : ' +
                                          (_score?.teleScore
                                                  .total()
                                                  .toString() ??
                                              '0'),
                                      style:
                                          Theme.of(context).textTheme.caption),
                                ),
                                SizedBox(
                                  child: Text(
                                      'Endgame : ' +
                                          (_score?.endgameScore
                                                  .total()
                                                  .toString() ??
                                              '0'),
                                      style:
                                          Theme.of(context).textTheme.caption),
                                )
                              ],
                            ),
                          ),
                          if (NewPlatform.isIOS())
                            SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: CupertinoSlidingSegmentedControl(
                                  groupValue: _view,
                                  children: <int, Widget>{
                                    0: Text('Autonomous'),
                                    1: Text('Tele-Op'),
                                    2: Text('Endgame')
                                  },
                                  onValueChanged: (int? x) {
                                    setState(
                                      () {
                                        HapticFeedback.mediumImpact();
                                        _view = x ?? 0;
                                      },
                                    );
                                  },
                                )),
                          if (NewPlatform.isAndroid())
                            SizedBox(
                              height: 50,
                              child: TabBar(
                                labelColor: Theme.of(context).accentColor,
                                unselectedLabelColor: Colors.grey,
                                labelStyle:
                                    TextStyle(fontFamily: '.SF UI Display'),
                                tabs: [
                                  Tab(
                                    text: 'Autonomous',
                                  ),
                                  Tab(
                                    text: 'Tele-Op',
                                  ),
                                  Tab(
                                    text: 'Endgame',
                                  )
                                ],
                              ),
                            ),
                          Divider(
                            height: 5,
                            thickness: 2,
                          ),
                          if (NewPlatform.isAndroid())
                            Expanded(
                              child: TabBarView(
                                children: [
                                  ListView(
                                    children: autoView(),
                                  ),
                                  ListView(
                                    children: teleView(),
                                  ),
                                  ListView(
                                    children: endView(),
                                  )
                                ],
                              ),
                            ),
                          if (NewPlatform.isIOS())
                            Expanded(
                              child: viewSelect(),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

  void stateSetter() {
    dataModel.saveEvents();
    //dataModel.uploadEvent(widget.event);
  }

  Alliance? getPenaltyAlliance() {
    if (_match?.type == EventType.remote) return _selectedAlliance;
    if (_selectedAlliance == _match?.red) return _match?.blue;
    if (_selectedAlliance == _match?.blue) return _match?.red;
  }

  void onIncrement() {
    if (lapses.length == 0)
      lapses.add(_time.toPrecision(3));
    else
      lapses.add(
        _time.toPrecision(3) -
            lapses.reduce((value, element) => value + element),
      );
    _score?.teleScore.cycleTimes = lapses;
    widget.event.getRef()?.runTransaction((mutableData) async {
      if (widget.team != null) {
        // mutableData.value['teams'][teamIndex]['targetScore']['TeleScore']
        //     ['Cycles'] = mutableData.value['teams']
        //         [teamIndex]['targetScore']['TeleScore']['Cycles'] =
        //     _score.teleScore.cycles;
        return mutableData;
      }
      final scoreIndex = _score?.id;
      var teamIndex;
      try {
        mutableData.value['teams'] as Map;
        teamIndex = _selectedTeam?.number;
      } catch (e) {
        teamIndex = int.parse(_selectedTeam?.number ?? '');
      }
      mutableData.value['teams'][teamIndex]['scores'][scoreIndex]['TeleScore']
          ['CycleTimes'] = _score?.teleScore.cycleTimes;
      return mutableData;
    });
  }

  ListView viewSelect() {
    switch (_view) {
      case 0:
        return ListView(
          children: autoView(),
        );
      case 1:
        return ListView(
          children: teleView(),
        );
      default:
        return ListView(
          children: endView(),
        );
    }
  }

  List<Widget> endView() => !_paused || _allowView
      ? _score?.endgameScore
              .getElements()
              .map(
                (e) => Incrementor(
                  element: e,
                  onPressed: stateSetter,
                  opModeType: OpModeType.endgame,
                  event: widget.event,
                  team: _selectedTeam,
                  score: _score,
                  isTargetScore: widget.team != null,
                ),
              )
              .toList() ??
          []
      : [
          Material(
            child: IconButton(
              icon: Icon(Icons.play_arrow),
              onPressed: () {
                _paused = false;
              },
            ),
          ),
          Material(
            child: IconButton(
              icon: Icon(Icons.visibility),
              onPressed: () {
                _allowView = true;
              },
            ),
          ),
        ];
  ScoringElement incrementValue = ScoringElement(
      name: 'Increment Value', min: () => 1, count: 1, key: null);
  void increaseMisses() async {
    _score?.teleScore.misses.count++;
    await widget.event.getRef()?.runTransaction((mutableData) async {
      var teamIndex;
      try {
        mutableData.value['teams'] as Map;
        teamIndex = _selectedTeam?.number;
      } catch (e) {
        teamIndex = int.parse(_selectedTeam?.number ?? '');
      }
      final scoreIndex = _score?.id;
      var ref = mutableData.value['teams'][teamIndex]['scores'][scoreIndex]
          ['TeleScore']['Misses'];
      mutableData.value['teams'][teamIndex]['scores'][scoreIndex]['TeleScore']
          ['Misses'] = (ref ?? 0) + 1;
      return mutableData;
    });
  }

  List<Widget> teleView() => !_paused || _allowView
      ? [
          Incrementor(
            backgroundColor: Colors.blue.withOpacity(0.3),
            element: incrementValue,
            onPressed: () => setState(
              () {
                _score?.teleScore.getElements().forEach((element) {
                  element.incrementValue = incrementValue.count;
                });
              },
            ),
          ),
          Incrementor(
            backgroundColor: Colors.red.withOpacity(0.3),
            element: _score?.teleScore.misses ?? ScoringElement(),
            onPressed: stateSetter,
            opModeType: OpModeType.tele,
            event: widget.event,
            team: _selectedTeam,
            score: _score,
            isTargetScore: widget.team != null,
          ),
          Padding(padding: EdgeInsets.all(5)),
          ..._score?.teleScore
                  .getElements()
                  .map(
                    (e) => Incrementor(
                      element: e,
                      onPressed: stateSetter,
                      onIncrement: onIncrement,
                      onDecrement: increaseMisses,
                      opModeType: OpModeType.tele,
                      event: widget.event,
                      team: _selectedTeam,
                      score: _score,
                      isTargetScore: widget.team != null,
                    ),
                  )
                  .toList() ??
              []
        ]
      : [
          Material(
            child: IconButton(
              icon: Icon(Icons.play_arrow),
              onPressed: () {
                _paused = false;
              },
            ),
          ),
          Material(
            child: IconButton(
              icon: Icon(Icons.visibility),
              onPressed: () {
                _allowView = true;
              },
            ),
          ),
        ];

  List<Widget> autoView() =>
      _score?.autoScore
          .getElements()
          .map(
            (e) => Incrementor(
              element: e,
              onPressed: stateSetter,
              opModeType: OpModeType.auto,
              event: widget.event,
              team: _selectedTeam,
              score: _score,
              isTargetScore: widget.team != null,
            ),
          )
          .toList() ??
      [];

  Row buttonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          flex: 1,
          child: PlatformButton(
            child: Text(
              _match?.red?.team1?.number ?? '?',
              style: TextStyle(
                  color: _selectedTeam == _match?.red?.team1
                      ? Colors.grey
                      : CupertinoColors.systemRed),
            ),
            onPressed: _selectedTeam == _match?.red?.team1
                ? null
                : () => setState(
                      () {
                        _selectedTeam = _match?.red?.team1;
                        _selectedAlliance = _match?.red;
                        _color = CupertinoColors.systemRed;
                        _score = _selectedTeam?.scores[_match?.id];
                        incrementValue.count =
                            _score?.teleScore.getElements()[0].incrementValue ??
                                1;
                      },
                    ),
          ),
        ),
        Flexible(
          flex: 1,
          child: PlatformButton(
            child: Text(
              _match?.red?.team2?.number ?? '?',
              style: TextStyle(
                color: _selectedTeam == _match?.red?.team2
                    ? Colors.grey
                    : CupertinoColors.systemRed,
              ),
            ),
            onPressed: _selectedTeam == _match?.red?.team2
                ? null
                : () {
                    setState(
                      () {
                        _selectedTeam = _match?.red?.team2;
                        _selectedAlliance = _match?.red;
                        _color = CupertinoColors.systemRed;
                        _score = _selectedTeam?.scores[_match?.id];
                      },
                    );
                  },
          ),
        ),
        Spacer(),
        Flexible(
          flex: 1,
          child: PlatformButton(
            child: Text(
              _match?.blue?.team1?.number ?? '?',
              style: TextStyle(
                  color: _selectedTeam == _match?.blue?.team1
                      ? Colors.grey
                      : Colors.blue),
            ),
            onPressed: _selectedTeam == _match?.blue?.team1
                ? null
                : () {
                    setState(
                      () {
                        _selectedTeam = _match?.blue?.team1;
                        _selectedAlliance = _match?.blue;
                        _color = Colors.blue;
                        _score = _selectedTeam?.scores[_match?.id];
                      },
                    );
                  },
          ),
        ),
        Flexible(
          flex: 1,
          child: PlatformButton(
            child: Text(
              _match?.blue?.team2?.number ?? '?',
              style: TextStyle(
                  color: _selectedTeam == _match?.blue?.team2
                      ? Colors.grey
                      : Colors.blue),
            ),
            onPressed: _selectedTeam == _match?.blue?.team2
                ? null
                : () => setState(
                      () {
                        _selectedTeam = _match?.blue?.team2;
                        _selectedAlliance = _match?.blue;
                        _color = Colors.blue;
                        _score = _selectedTeam?.scores[_match?.id];
                      },
                    ),
          ),
        )
      ],
    );
  }
}
