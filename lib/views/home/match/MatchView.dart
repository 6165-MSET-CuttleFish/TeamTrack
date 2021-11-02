import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:flutter/foundation.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/providers/Auth.dart';
import 'package:teamtrack/views/home/match/UsersRow.dart';
import 'package:uuid/uuid.dart';
import 'package:teamtrack/functions/Extensions.dart';

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
  bool _showPenalties = true;
  bool _showRoles = false;
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
      _allowView = true;
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
  void initState() {
    super.initState();
    if (widget.team == null) {
      final user = AuthenticationService(FirebaseAuth.instance).getUser();
      final ttuser = widget.event.getTTUserFromUser(user);
      final ref = widget.event
          .getRef()
          ?.child('matches/${widget.match?.id}/activeUsers/${user?.uid}');
      ref?.set(ttuser.toJson());
      ref?.onDisconnect().remove();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Database.Event>(
        stream: widget.event.getRef()?.onValue,
        builder: (context, eventHandler) {
          if (eventHandler.hasData && !eventHandler.hasError) {
            widget.event.updateLocal(
              json.decode(
                json.encode(eventHandler.data?.snapshot.value),
              ),
              context,
            );
            if (widget.team == null) {
              _match = widget.event.matches[_match?.id];
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
                    title: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: (_match?.activeUsers?.isNotEmpty ?? false)
                          ? RawMaterialButton(
                              onPressed: () => _showRoles = !_showRoles,
                              splashColor: Colors.transparent,
                              child: UsersRow(
                                users: _match?.activeUsers ?? [],
                                showRole: _showRoles,
                              ),
                            )
                          : Text("Match Stats"),
                    ),
                    elevation: 0,
                    actions: widget.team == null
                        ? [
                            IconButton(
                              tooltip: "Reset Score",
                              icon: Icon(
                                Icons.restore,
                              ),
                              onPressed: () => showPlatformDialog(
                                context: context,
                                builder: (_) => PlatformAlert(
                                  title: Text('Reset Score'),
                                  content: Text('Are you sure?'),
                                  actions: [
                                    PlatformDialogAction(
                                      child: Text('Cancel'),
                                      isDefaultAction: true,
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                    PlatformDialogAction(
                                      child: Text('Confirm'),
                                      isDestructive: true,
                                      onPressed: () => setState(
                                        () {
                                          if (widget.event.shared) {
                                            if (_match != null) {
                                              widget.event
                                                  .getRef()
                                                  ?.child(
                                                      'teams/${_selectedTeam?.number}/scores/${_score?.id}')
                                                  .runTransaction(
                                                      (transaction) {
                                                transaction.value = Score(
                                                  _match?.id ?? Uuid().v4(),
                                                  _match?.dice ?? Dice.one,
                                                  widget.event.gameName,
                                                ).toJson();
                                                return transaction;
                                              });
                                            }
                                          } else {
                                            _score?.reset();
                                          }
                                          dataModel.saveEvents();
                                          Navigator.pop(context);
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                _time.roundToDouble().toString(),
                              ),
                            ),
                            IconButton(
                              tooltip: "Driver Control",
                              icon: Icon(
                                  _paused ? Icons.play_arrow : Icons.pause),
                              onPressed: () => setState(() {
                                _paused = !_paused;
                                _allowView = true;
                              }),
                            ),
                            IconButton(
                              icon: Icon(Icons.stop),
                              onPressed: () => setState(
                                () {
                                  lapses.clear();
                                  _paused = true;
                                  _time = 0;
                                },
                              ),
                            ),
                          ]
                        : [],
                  ),
                  body: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _color,
                          for (int i = 0; i < 6; i++)
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
                                    _match
                                            ?.redScore(
                                                showPenalties: _showPenalties)
                                            .toString() ??
                                        '0',
                                    style:
                                        Theme.of(context).textTheme.headline4,
                                  ),
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
                                    _match
                                            ?.blueScore(
                                                showPenalties: _showPenalties)
                                            .toString() ??
                                        '0',
                                    style:
                                        Theme.of(context).textTheme.headline4,
                                  ),
                                ),
                              ],
                            ),
                          if (_match?.type != EventType.remote &&
                              _match != null)
                            buttonRow(),
                          Text(
                            (_selectedTeam?.name ?? '') +
                                ' : ' +
                                (widget.event.type != EventType.remote
                                    ? (_score
                                            ?.total(
                                              showPenalties:
                                                  widget.event.type ==
                                                          EventType.remote
                                                      ? _showPenalties
                                                      : false,
                                            )
                                            .toString() ??
                                        '')
                                    : (_match?.score(
                                            showPenalties: _showPenalties) ??
                                        '')),
                            style: Theme.of(context).textTheme.headline6,
                          ),
                          if (widget.team == null)
                            DropdownButton<Dice>(
                              value: _match?.dice,
                              icon: Icon(Icons.height_rounded),
                              iconSize: 24,
                              elevation: 16,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary),
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
                                    ?.runTransaction((mutableData) {
                                  mutableData.value['matches'][_match?.id]
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
                                      json.decode(
                                            remoteConfig.getString(
                                              widget.event.gameName,
                                            ),
                                          )['Dice']['name'] +
                                          ' : ' +
                                          value.toVal(widget.event.gameName),
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                          if (getPenaltyAlliance() != null &&
                              widget.team == null)
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
                                            path: teamPath(OpModeType.penalty),
                                            score: _score,
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
                                        (widget.event.type != EventType.remote
                                            ? (_score?.autoScore
                                                    .total()
                                                    .toString() ??
                                                '0')
                                            : (_selectedAlliance
                                                    ?.total()
                                                    .autoScore
                                                    .total()
                                                    .toString() ??
                                                '0')),
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                ),
                                SizedBox(
                                  child: Text(
                                      'Tele-Op : ' +
                                          (widget.event.type != EventType.remote
                                              ? (_score?.teleScore
                                                      .total()
                                                      .toString() ??
                                                  '0')
                                              : (_selectedAlliance
                                                      ?.total()
                                                      .teleScore
                                                      .total()
                                                      .toString() ??
                                                  '0')),
                                      style:
                                          Theme.of(context).textTheme.caption),
                                ),
                                SizedBox(
                                  child: Text(
                                      'Endgame : ' +
                                          (widget.event.type != EventType.remote
                                              ? (_score?.endgameScore
                                                      .total()
                                                      .toString() ??
                                                  '0')
                                              : (_selectedAlliance
                                                      ?.total()
                                                      .endgameScore
                                                      .total()
                                                      .toString() ??
                                                  '0')),
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
                                labelColor:
                                    Theme.of(context).colorScheme.primary,
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
    HapticFeedback.mediumImpact();
    dataModel.saveEvents();
  }

  Row buttonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          child: PlatformButton(
            child: Text(
              _match?.red?.team1?.number ?? '?',
              style: TextStyle(
                color: _selectedTeam == _match?.red?.team1
                    ? Colors.grey
                    : CupertinoColors.systemRed,
              ),
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
        SizedBox(
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
        SizedBox(
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
        SizedBox(
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

  Alliance? getPenaltyAlliance() {
    if (_match?.type == EventType.remote) return _selectedAlliance;
    if (_selectedAlliance == _match?.red) return _match?.blue;
    if (_selectedAlliance == _match?.blue) return _match?.red;
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

  String teamPath(OpModeType opModeType) {
    if (widget.team != null) {
      return 'teams/${_selectedTeam?.number}/targetScore/${opModeType.toRep()}';
    }
    return 'teams/${_selectedTeam?.number}/scores/${_score?.id}/${opModeType.toRep()}';
  }

  String matchPath(OpModeType opModeType) =>
      'matches/${widget.match?.id}/${allianceColor()}/sharedScore/${OpModeType.endgame.toRep()}';

  List<Widget> autoView() => [
        ..._score?.autoScore
                .getElements()
                .parse()
                .map(
                  (e) => Incrementor(
                    element: e,
                    onPressed: stateSetter,
                    event: widget.event,
                    path: teamPath(OpModeType.auto),
                    score: _score,
                  ),
                )
                .toList() ??
            [],
        if (widget.team == null)
          ..._selectedAlliance?.sharedScore.teleScore.getElements().parse().map(
                    (e) => Incrementor(
                      element: e,
                      onPressed: stateSetter,
                      event: widget.event,
                      path: matchPath(OpModeType.auto),
                      score: _score,
                      backgroundColor: Colors.green,
                    ),
                  ) ??
              []
      ];

  List<Widget> teleView() => !_paused || _allowView
      ? [
          Incrementor(
            backgroundColor: Colors.blue.withOpacity(0.3),
            element: incrementValue,
            onPressed: () => setState(
              () {
                _score?.teleScore.getElements().forEach((element) {
                  element.incrementValue = incrementValue.count;
                  stateSetter();
                });
              },
            ),
          ),
          Incrementor(
            backgroundColor: Colors.red.withOpacity(0.3),
            element: _score?.teleScore.misses ?? ScoringElement(),
            onPressed: stateSetter,
            event: widget.event,
            path: teamPath(OpModeType.auto),
            score: _score,
          ),
          Padding(padding: EdgeInsets.all(5)),
          ..._score?.teleScore
                  .getElements()
                  .parse()
                  .map(
                    (e) => Incrementor(
                      element: e,
                      onPressed: stateSetter,
                      onDecrement: widget.team == null ? increaseMisses : null,
                      onIncrement: _paused ? null : onIncrement,
                      event: widget.event,
                      path: teamPath(OpModeType.tele),
                      score: _score,
                      mutableIncrement: (mutableData) {
                        if (widget.team != null) {
                          var ref = mutableData.value[e.key];
                          if (ref < e.max!())
                            mutableData.value[e.key] =
                                (ref ?? 0) + incrementValue.count;
                          return mutableData;
                        }
                        var ref = mutableData.value;
                        if (ref[e.key] < e.max!()) {
                          mutableData.value[e.key] =
                              (ref[e.key] ?? 0) + e.incrementValue;
                          lapses.add(
                            (_time -
                                    (lapses.length != 0
                                        ? lapses.reduce(
                                            (value, element) => value + element)
                                        : 0))
                                .toPrecision(3),
                          );
                          if (!_paused) {
                            mutableData.value['CycleTimes'] = lapses;
                            if (_time < 90)
                              mutableData.value['TeleCycles'] =
                                  (ref['TeleCycles'] ?? 0) + 1;
                            else
                              mutableData.value['EndgameCycles'] =
                                  (ref['EndgameCycles'] ?? 0) + 1;
                          }
                        }
                        return mutableData;
                      },
                      mutableDecrement: (mutableData) {
                        if (widget.team != null) {
                          var ref = mutableData.value[e.key];
                          if (ref < e.max!())
                            mutableData.value[e.key] = (ref ?? 0) - 1;
                          return mutableData;
                        }
                        var ref = mutableData.value;
                        if (ref[e.key] < e.max!()) {
                          mutableData.value[e.key] =
                              (ref[e.key] ?? 0) - e.decrementValue;
                          if (!_paused) {
                            mutableData.value['Misses'] =
                                (ref['Misses'] ?? 0) + 1;
                          }
                        }
                        return mutableData;
                      },
                    ),
                  )
                  .toList() ??
              [],
          if (widget.team == null)
            ..._selectedAlliance?.sharedScore.teleScore
                    .getElements()
                    .parse()
                    .map(
                      (e) => Incrementor(
                        element: e,
                        onPressed: stateSetter,
                        onDecrement:
                            widget.team == null ? increaseMisses : null,
                        event: widget.event,
                        path: matchPath(OpModeType.tele),
                        score: _score,
                        backgroundColor: Colors.green,
                      ),
                    ) ??
                []
        ]
      : [
          Material(
            child: IconButton(
              icon: Icon(Icons.play_arrow),
              tooltip: 'Driver Control Play',
              onPressed: () {
                _paused = false;
                _allowView = true;
              },
            ),
          ),
          Material(
            child: IconButton(
              icon: Icon(Icons.visibility),
              tooltip: 'View',
              onPressed: () {
                _allowView = true;
              },
            ),
          ),
        ];

  List<Widget> endView() => !_paused || _allowView
      ? [
          ..._score?.endgameScore
                  .getElements()
                  .parse()
                  .map(
                    (e) => Incrementor(
                      element: e,
                      onPressed: stateSetter,
                      event: widget.event,
                      path: teamPath(OpModeType.endgame),
                      score: _score,
                    ),
                  )
                  .toList() ??
              [],
          Padding(padding: EdgeInsets.all(5)),
          if (widget.team == null)
            ..._selectedAlliance?.sharedScore.endgameScore
                    .getElements()
                    .parse()
                    .map(
                      (e) => Incrementor(
                        element: e,
                        onPressed: stateSetter,
                        event: widget.event,
                        path: matchPath(OpModeType.endgame),
                        score: _score,
                        backgroundColor: Colors.green.withOpacity(0.3),
                      ),
                    ) ??
                []
        ]
      : [
          Material(
            child: IconButton(
              tooltip: 'Driver Control Play',
              icon: Icon(Icons.play_arrow),
              onPressed: () {
                _paused = false;
                _allowView = true;
              },
            ),
          ),
          Material(
            child: IconButton(
              icon: Icon(Icons.visibility),
              tooltip: 'View',
              onPressed: () {
                _allowView = true;
              },
            ),
          ),
        ];
  ScoringElement incrementValue = ScoringElement(
      name: 'Increment Value', min: () => 1, count: 1, key: null);
  void increaseMisses() async {
    if (!widget.event.shared) _score?.teleScore.misses.count++;
    widget.event.getRef()?.runTransaction(
      (mutableData) {
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
      },
    );
  }

  void onIncrement() {
    lapses.add(
      (_time -
              (lapses.length != 0
                  ? lapses.reduce((value, element) => value + element)
                  : 0))
          .toPrecision(3),
    );
    _score?.teleScore.cycleTimes = lapses;
    if (widget.team != null) {
      widget.event
          .getRef()
          ?.child('teams/${_selectedTeam?.number}')
          .runTransaction((mutableData) {
        final scoreIndex = _score?.id;
        mutableData.value['scores'][scoreIndex]['TeleScore']['CycleTimes'] =
            lapses;
        return mutableData;
      });
    }
  }

  String allianceColor() {
    if (_selectedAlliance == widget.match?.blue) {
      return 'blue';
    } else {
      return 'red';
    }
  }
}
