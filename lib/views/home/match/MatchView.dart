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
import 'package:teamtrack/views/home/util/ScoreSummary.dart';
import 'package:teamtrack/views/home/util/UsersRow.dart';
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
  final blue = Colors.blue;
  final red = CupertinoColors.systemRed;
  bool _showPenalties = true,
      _allianceTotal = false,
      _showRoles = false,
      _paused = true,
      _allowView = false;
  final Stream<int> _periodicStream =
      Stream.periodic(const Duration(milliseconds: 100), (i) => i);
  double _time = 0;
  List<double> lapses = [];
  double sum = 0;
  int? _previousStreamValue = 0;
  _MatchView(this._match, Team? team, Event event) {
    _selectedAlliance = _match?.red;
    if (_match == null) {
      _allowView = true;
      _score = team?.targetScore;
      _selectedTeam = team;
      _color = CupertinoColors.systemGreen;
    } else {
      _selectedTeam = _match?.red?.team1;
      if (team != null) {
        _selectedTeam = team;
        if (_match?.alliance(team) == _match?.blue) {
          _selectedAlliance = _match?.red;
          _color = Colors.blue;
        }
      }
      _score = _selectedTeam?.scores[_match?.id];
      if (_match?.type == EventType.remote)
        _color = CupertinoColors.systemGreen;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.match != null) {
      final user = AuthenticationService(firebaseAuth).getUser();
      final ttuser = widget.event.getTTUserFromUser(user);
      final ref = widget.event
          .getRef()
          ?.child('matches/${widget.match?.id}/activeUsers/${user?.uid}');
      ref?.set(ttuser.toJson());
      ref?.onDisconnect().remove();
    }
  }

  @override
  void dispose() {
    final user = AuthenticationService(firebaseAuth).getUser();
    final ref = widget.event
        .getRef()
        ?.child('matches/${widget.match?.id}/activeUsers/${user?.uid}');
    ref?.remove();
    super.dispose();
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
            if (widget.match != null) {
              _match = widget.event.matches[_match?.id];
            }
            _selectedTeam = widget.event.teams[_selectedTeam?.number];
            _selectedAlliance = _match?.red;
            if (_color == CupertinoColors.systemRed)
              _selectedAlliance = _match?.red;
            else if (_color == Colors.blue) _selectedAlliance = _match?.blue;
            if (widget.match == null) {
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
                          : PlatformText("Match Stats"),
                    ),
                    elevation: 0,
                    actions: widget.match != null
                        ? [
                            IconButton(
                              tooltip: "Reset Score",
                              icon: Icon(
                                Icons.restore,
                              ),
                              onPressed: () => showPlatformDialog(
                                context: context,
                                builder: (_) => PlatformAlert(
                                  title: PlatformText('Reset Score'),
                                  content: PlatformText('Are you sure?'),
                                  actions: [
                                    PlatformDialogAction(
                                      child: PlatformText('Cancel'),
                                      isDefaultAction: true,
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                    PlatformDialogAction(
                                      child: PlatformText('Confirm'),
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
                              child: PlatformText(
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
                                  lapses = [];
                                  sum = 0;
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
                              widget.match != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  width: 100,
                                  child: PlatformText(
                                    _match
                                            ?.redScore(
                                                showPenalties: _showPenalties)
                                            .toString() ??
                                        '0',
                                    style:
                                        Theme.of(context).textTheme.headline4,
                                  ),
                                ),
                                DropdownButton<Dice>(
                                  value: _match?.dice,
                                  focusColor: Colors.black,
                                  icon: Icon(Icons.height_rounded),
                                  iconSize: 24,
                                  iconEnabledColor:
                                      Theme.of(context).colorScheme.primary,
                                  elevation: 16,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
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
                                        ?.child('matches/${_match?.id}/dice')
                                        .set((newValue ?? Dice.one).toString());
                                    dataModel.saveEvents();
                                  },
                                  items: [Dice.one, Dice.two, Dice.three]
                                      .map<DropdownMenuItem<Dice>>(
                                        (value) => DropdownMenuItem<Dice>(
                                          value: value,
                                          child: PlatformText(
                                            json.decode(
                                                  remoteConfig.getString(
                                                    widget.event.gameName,
                                                  ),
                                                )['Dice']['name'] +
                                                ' : ' +
                                                value.toVal(
                                                  widget.event.gameName,
                                                ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText1,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  width: 100,
                                  child: PlatformText(
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
                          Column(
                            children: [
                              PlatformText(
                                (_selectedTeam?.name ?? ''),
                                style: Theme.of(context).textTheme.headline6,
                              ),
                              RawMaterialButton(
                                fillColor: _allianceTotal
                                    ? _color.withOpacity(0.3)
                                    : null,
                                onPressed: () =>
                                    _allianceTotal = !_allianceTotal,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    right: 8.0,
                                    top: 8.0,
                                  ),
                                  child: ScoreSummary(
                                    event: widget.event,
                                    score: (widget.event.type ==
                                                    EventType.remote &&
                                                widget.match != null) ||
                                            _allianceTotal
                                        ? _selectedAlliance?.total()
                                        : _score,
                                    autoMax: (widget.event.type ==
                                                    EventType.remote &&
                                                widget.match != null) ||
                                            _allianceTotal
                                        ? widget.event.matches.values
                                            .map((element) =>
                                                [element.red, element.blue])
                                            .reduce((value, element) =>
                                                value + element)
                                            .map((e) =>
                                                e?.total().autoScore.total())
                                            .maxValue()
                                        : widget.event.teams.values
                                            .map((e) => widget.match == null
                                                ? e.targetScore?.autoScore
                                                    .total()
                                                : e.scores.maxScore(Dice.none,
                                                    false, OpModeType.auto))
                                            .maxValue(),
                                    teleMax: (widget.event.type ==
                                                    EventType.remote &&
                                                widget.match != null) ||
                                            _allianceTotal
                                        ? widget.event.matches.values
                                            .map((element) =>
                                                [element.red, element.blue])
                                            .reduce((value, element) =>
                                                value + element)
                                            .map((e) =>
                                                e?.total().teleScore.total())
                                            .maxValue()
                                        : widget.event.teams.values
                                            .map((e) => widget.match == null
                                                ? e.targetScore?.teleScore
                                                    .total()
                                                : e.scores.maxScore(Dice.none,
                                                    false, OpModeType.tele))
                                            .maxValue(),
                                    endMax: (widget.event.type ==
                                                    EventType.remote &&
                                                widget.match != null) ||
                                            _allianceTotal
                                        ? widget.event.matches.values
                                            .map((element) =>
                                                [element.red, element.blue])
                                            .reduce((value, element) =>
                                                value + element)
                                            .map((e) =>
                                                e?.total().endgameScore.total())
                                            .maxValue()
                                        : widget.event.teams.values
                                            .map((e) =>
                                                widget.match == null
                                                    ? e.targetScore
                                                        ?.endgameScore
                                                        .total()
                                                    : e.scores.maxScore(
                                                        Dice.none,
                                                        false,
                                                        OpModeType.endgame))
                                            .maxValue(),
                                    totalMax: (widget.event.type ==
                                                    EventType.remote &&
                                                widget.match != null) ||
                                            _allianceTotal
                                        ? widget.event.matches.values
                                            .map((element) =>
                                                [element.red, element.blue])
                                            .reduce((value, element) =>
                                                value + element)
                                            .map((e) => e?.total().total())
                                            .maxValue()
                                        : widget.event.teams.values
                                            .map((e) => widget.match == null
                                                ? e.targetScore?.total()
                                                : e.scores.maxScore(
                                                    Dice.none, false, null))
                                            .maxValue(),
                                    showPenalties: _showPenalties,
                                    height: 40,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (getPenaltyAlliance() != null &&
                              widget.match != null)
                            Material(
                              child: ExpansionTile(
                                  leading: Checkbox(
                                    checkColor: Colors.black,
                                    fillColor:
                                        MaterialStateProperty.all(Colors.red),
                                    value: _showPenalties,
                                    onChanged: (_) =>
                                        _showPenalties = _ ?? false,
                                  ),
                                  title: PlatformText(
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
                                              path:
                                                  teamPath(OpModeType.penalty),
                                              score: _score,
                                            ),
                                          )
                                          .toList() ??
                                      []),
                            ),
                          if (NewPlatform.isIOS)
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: CupertinoSlidingSegmentedControl(
                                groupValue: _view,
                                children: <int, Widget>{
                                  0: PlatformText('Autonomous'),
                                  1: PlatformText('Tele-Op'),
                                  2: PlatformText('Endgame')
                                },
                                onValueChanged: (int? x) {
                                  setState(
                                    () {
                                      HapticFeedback.mediumImpact();
                                      _view = x ?? 0;
                                    },
                                  );
                                },
                              ),
                            ),
                          if (NewPlatform.isAndroid)
                            SizedBox(
                              height: 50,
                              child: Material(
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
                            ),
                          Divider(
                            height: 5,
                            thickness: 2,
                          ),
                          if (NewPlatform.isAndroid)
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
                          if (NewPlatform.isIOS)
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
            child: PlatformText(
              _match?.red?.team1?.number ?? '?',
              style: TextStyle(
                color: _selectedTeam == _match?.red?.team1 ? Colors.grey : red,
              ),
            ),
            onPressed: _selectedTeam == _match?.red?.team1
                ? null
                : () => setState(
                      () {
                        _selectedTeam = _match?.red?.team1;
                        _selectedAlliance = _match?.red;
                        _color = red;
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
            child: PlatformText(
              _match?.red?.team2?.number ?? '?',
              style: TextStyle(
                color: _selectedTeam == _match?.red?.team2 ? Colors.grey : red,
              ),
            ),
            onPressed: _selectedTeam == _match?.red?.team2
                ? null
                : () {
                    setState(
                      () {
                        _selectedTeam = _match?.red?.team2;
                        _selectedAlliance = _match?.red;
                        _color = red;
                        _score = _selectedTeam?.scores[_match?.id];
                      },
                    );
                  },
          ),
        ),
        SizedBox(
          child: PlatformButton(
            child: PlatformText(
              _match?.blue?.team1?.number ?? '?',
              style: TextStyle(
                  color: _selectedTeam == _match?.blue?.team1
                      ? Colors.grey
                      : blue),
            ),
            onPressed: _selectedTeam == _match?.blue?.team1
                ? null
                : () {
                    setState(
                      () {
                        _selectedTeam = _match?.blue?.team1;
                        _selectedAlliance = _match?.blue;
                        _color = blue;
                        _score = _selectedTeam?.scores[_match?.id];
                      },
                    );
                  },
          ),
        ),
        SizedBox(
          child: PlatformButton(
            child: PlatformText(
              _match?.blue?.team2?.number ?? '?',
              style: TextStyle(
                  color: _selectedTeam == _match?.blue?.team2
                      ? Colors.grey
                      : blue),
            ),
            onPressed: _selectedTeam == _match?.blue?.team2
                ? null
                : () => setState(
                      () {
                        _selectedTeam = _match?.blue?.team2;
                        _selectedAlliance = _match?.blue;
                        _color = blue;
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
    if (widget.match == null) {
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
        if (widget.match != null)
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
            path: teamPath(OpModeType.tele),
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
                      onDecrement: widget.match != null ? increaseMisses : null,
                      onIncrement: _paused ? null : onIncrement,
                      event: widget.event,
                      path: teamPath(OpModeType.tele),
                      score: _score,
                      mutableIncrement: (mutableData) {
                        if (widget.match == null) {
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
                            (_time - sum).toPrecision(3),
                          );
                          sum = _time;
                          if (!_paused) {
                            mutableData.value['CycleTimes'] = lapses;
                          }
                        }
                        return mutableData;
                      },
                      mutableDecrement: (mutableData) {
                        if (widget.match == null) {
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
          if (widget.match != null)
            ..._selectedAlliance?.sharedScore.teleScore
                    .getElements()
                    .parse()
                    .map(
                      (e) => Incrementor(
                        element: e,
                        onPressed: stateSetter,
                        onDecrement:
                            widget.match != null ? increaseMisses : null,
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
          if (widget.match != null)
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
      (_time - sum).toPrecision(3),
    );
    sum = _time;
    _score?.teleScore.cycleTimes = lapses;
  }

  String allianceColor() {
    if (_selectedAlliance == _match?.blue) {
      return 'blue';
    } else {
      return 'red';
    }
  }
}
