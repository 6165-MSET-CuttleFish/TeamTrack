import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:teamtrack/api/APIKEYS.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:teamtrack/components/statistics/BarGraph.dart';
import 'package:teamtrack/components/scores/Incrementor.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/providers/Auth.dart';
import 'package:teamtrack/components/scores/ScoreSummary.dart';
import 'package:teamtrack/components/users/UsersRow.dart';
import 'package:uuid/uuid.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:provider/provider.dart';

class MatchView extends StatefulWidget {
  MatchView({super.key, this.match, this.team, required this.event});
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
  Score? _score;
  OpModeType _view = OpModeType.auto;
  Match? _match;
  final blue = Colors.blue;
  final red = CupertinoColors.systemRed;
  bool _showPenalties = true,
      _allianceTotal = false,
      _showRoles = false,
      _paused = true,
      _allowView = false,
      _endgameStarted = false;
  final _periodicStream =
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
    } else {
      _selectedTeam = _match?.red?.team1;
      if (team != null) {
        _selectedTeam = team;
        if (_match?.alliance(team) == _match?.blue) {
          _selectedAlliance = _match?.red;
        }
      }
      _score = _selectedTeam?.scores[_match?.id];
    }
    opModeExt.getAll().forEach(
      (type) {
        maxScoresInd[type] = {};
        maxScoresTarget[type] = {};
        maxScoresTotal[type] = {};
      },
    );
    opModeExt.getAll().forEach((type) => [
          null,
          ...Score('', Dice.none, event.gameName)
              .getScoreDivision(type)
              .getElements()
              .parse(putNone: false)
        ].forEach(
          (element) {
            maxScoresInd[type]?[element?.key] = event.teams.values
                .map(
                  (team) => team.scores.maxScore(
                    Dice.none,
                    false,
                    type,
                    element?.key,
                  ),
                )
                .maxValue();
            maxScoresTotal[type]?[element?.key] = event.matches.values
                .map((element) => [element.red, element.blue])
                .reduce((value, element) => value + element)
                .map((alliance) => alliance
                    ?.combinedScore()
                    .getScoreDivision(type)
                    .getScoringElementCount(element?.key)
                    ?.abs())
                .maxValue();
            maxScoresTarget[type]?[element?.key] = event.teams.values
                .map((team) => team.targetScore
                    ?.getScoreDivision(type)
                    .getElements()
                    .parse()
                    .firstWhere((element) => element.key == element.key,
                        orElse: () => ScoringElement.nullScore())
                    .scoreValue())
                .maxValue();
          },
        ));
  }

  Map<OpModeType?, Map<String?, double>> maxScoresInd = {};
  Map<OpModeType?, Map<String?, double>> maxScoresTarget = {};
  Map<OpModeType?, Map<String?, double>> maxScoresTotal = {};
  String? previouslyCycledElement;

  @override
  void initState() {
    super.initState();
    if (widget.match != null) {
      final user = firebaseAuth.currentUser;
      final ttuser = widget.event.getTTUserFromUser(user);
      final ref = widget.event
          .getRef()
          ?.child('matches/${widget.match?.id}/activeUsers/${user?.uid}');
      ref?.set(ttuser.toJson(_selectedTeam?.number));
      ref?.onDisconnect().remove();
    } else {
      _allianceTotal = false;
      try {
        http.get(
          Uri.parse('${APIKEYS.TOA_URL}/team/${widget.team?.number}'),
          headers: {
            'X-TOA-Key': APIKEYS.TOA_KEY,
            'X-Application-Origin': 'TeamTrack',
            'Content-Type': 'application/json',
          },
        ).then((value) {
          final body = (json.decode(value.body) as List);
          if (body.length != 0)
            setState(() => widget.team?.updateWithTOA(body[0]));
        });
      } catch (e) {
        print(e);
      }
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

  Map<OpModeType?, double> getMaxScoreInd() {
    Map<OpModeType?, double> maxScore = {};
    for (final type in opModeExt.getAll()) {
      maxScore[type] = maxScoresInd[type]?[null] ?? 0;
    }
    return maxScore;
  }

  Map<OpModeType?, double> getMaxScoreTotal() {
    Map<OpModeType?, double> maxScore = {};
    for (final type in opModeExt.getAll()) {
      maxScore[type] = maxScoresTotal[type]?[null] ?? 0;
    }
    return maxScore;
  }

  Map<OpModeType?, double> getMaxScoreTarget() {
    Map<OpModeType?, double> maxScore = {};
    for (final type in opModeExt.getAll()) {
      maxScore[type] = maxScoresTarget[type]?[null] ?? 0;
    }
    return maxScore;
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<DatabaseEvent>(
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
            _selectedAlliance = _match?.alliance(_selectedTeam);
            if (widget.match == null) {
              _score = _selectedTeam?.targetScore;
            } else {
              _score = _selectedTeam?.scores[_match?.id];
              _score?.teleScore.getElements().forEach((element) {
                element.incrementValue = incrementValue.totalCount();
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
                    if (_time > 90 && !_endgameStarted) {
                      HapticFeedback.heavyImpact();
                      _endgameStarted = true;
                    }
                  }
                }
              }
              final secondsLeft = 120 - _time;
              final minutes = secondsLeft >= 0 ? secondsLeft ~/ 60 : 0.0;
              final seconds = secondsLeft >= 0 ? secondsLeft % 60 : 0.0;
              String timerText =
                  '$minutes:${seconds.toInt().toString().padLeft(2, '0')}';
              return Container(
                child: DefaultTabController(
                  length: 3,
                  child: Scaffold(
                    appBar: AppBar(
                      backgroundColor: getAllianceColor(),
                      title: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: (_match?.activeUsers?.isNotEmpty ?? false)
                            ? RawMaterialButton(
                                onPressed: () => _showRoles = !_showRoles,
                                splashColor: Colors.transparent,
                                child: Hero(
                                  tag: _match?.id ?? '',
                                  child: UsersRow(
                                    users: _match?.activeUsers ?? [],
                                    showRole: _showRoles,
                                  ),
                                ),
                              )
                            : Text("Match Stats"),
                      ),
                      elevation: 0,
                      actions: widget.match != null
                          ? [
                            Center(
                                child:Text("Timer",
                                style:Theme.of(context).textTheme.titleSmall)
                            ),

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
                                                  transaction = Score(
                                                    _match?.id ?? Uuid().v4(),
                                                    _match?.dice ?? Dice.one,
                                                    widget.event.gameName,
                                                  ).toJson();
                                                  return Transaction.success(
                                                      transaction);
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
                                child: Text(timerText),
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
                            getAllianceColor(),
                            for (int i = 0; i < 6; i++)
                              Theme.of(context).canvasColor,
                            if (_time > 90)
                              for (int i = 0; i < 2; i++)
                                Colors.deepOrange.withOpacity(0.4),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            if ((_match?.type != EventType.remote ||
                                    _match?.type != EventType.analysis) &&
                                widget.match != null)
                              SizedBox(
                                  width: 0.9*MediaQuery.of(context).size.width,
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    width: 100,
                                    child: Text(
                                      _match
                                              ?.redScore(
                                                showPenalties: true,
                                              )
                                              .toString() ??
                                          '0',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                  ),
                                  DropdownButton<Dice>(
                                    value: _match?.dice,
                                    focusColor: Colors.black,
                                    icon: Icon(Icons.height_rounded),
                                    iconSize: 24,
                                    iconEnabledColor:
                                        Theme.of(context).shadowColor,
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
                                          .set((newValue ?? Dice.one)
                                              .toString());
                                      dataModel.saveEvents();
                                    },
                                    items: [Dice.one, Dice.two, Dice.three]
                                        .map<DropdownMenuItem<Dice>>(
                                          (value) => DropdownMenuItem<Dice>(
                                            value: value,
                                            child: Text(
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
                                                  .bodyLarge,
                                            ),
                                          ),
                                        )
                                        .toList(),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                           ),
                            if ((_match?.type != EventType.remote &&
                                    _match?.type != EventType.analysis) &&
                                _match != null)
                              buttonRow(),
                            Column(
                              children: [
                                UsersRow(
                                  users: _match?.activeUsers
                                          ?.where((user) =>
                                              user.watchingTeam ==
                                              _selectedTeam?.number)
                                          .toList() ??
                                      [],
                                  showRole: true,
                                  size: 20,
                                ),
                                Text(
                                  ("${_selectedTeam?.number} : ${_selectedTeam?.name ?? ''}"),
                                  style: Theme.of(context).textTheme.titleLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_match == null)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        if (widget.team?.city != null)
                                          Text(
                                            "from ${widget.team?.city}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        if (widget.team?.established != null)
                                          Text(
                                            "est. ${widget.team?.established}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 5.0,
                                    bottom: 5.0,
                                  ),
                                  child: RawMaterialButton(
                                    fillColor: _allianceTotal &&
                                            widget.event.type !=
                                                EventType.remote
                                        ? getAllianceColor().withOpacity(0)
                                        : null,
                                    onPressed: (widget.match != null &&
                                            widget.event.type !=
                                                EventType.remote)
                                        ? () => _allianceTotal = !_allianceTotal
                                        : null,
                                    child: ScoreSummary(
                                      event: widget.event,
                                      score: (widget.event.type ==
                                                      EventType.remote &&
                                                  widget.match != null) ||
                                              _allianceTotal
                                          ? _selectedAlliance?.combinedScore()
                                          : _score,
                                      maxes: (widget.event.type ==
                                                      EventType.remote &&
                                                  widget.match != null) ||
                                              _allianceTotal
                                          ? getMaxScoreTotal()
                                          : getMaxScoreInd(),
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
                                color: Colors.transparent,
                                child: ExpansionTile(
                                  leading: Checkbox(
                                    checkColor: Colors.black,
                                    fillColor:
                                        MaterialStateProperty.all(Colors.red),
                                    value: _showPenalties,
                                    onChanged: (_) =>
                                        _showPenalties = _ ?? false,
                                  ),
                                  title: Text(
                                    'Penalties',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  children: _score?.penalties
                                          .getElements()
                                          .map(
                                            (e) => Incrementor(
                                              getTime: () => _time,
                                              element: e,
                                              backgroundColor:
                                                  Colors.transparent,
                                              onPressed: () =>
                                                  stateSetter(e.key),
                                              event: widget.event,
                                              path:
                                                  teamPath(OpModeType.penalty),
                                              score: _score,
                                            ),
                                          )
                                          .toList() ??
                                      [],
                                ),
                              ),
                            if (NewPlatform.isIOS)
                              SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: CupertinoSlidingSegmentedControl<
                                    OpModeType>(
                                  groupValue: _view,
                                  children: {
                                    OpModeType.auto: Text('Autonomous',
                                    style: Theme.of(context).textTheme.titleSmall),
                                    OpModeType.tele: Text('Tele-Op',
                                        style: Theme.of(context).textTheme.titleSmall),
                                    OpModeType.endgame: Text('Endgame',
                                        style: Theme.of(context).textTheme.titleSmall)
                                  },
                                  onValueChanged: (OpModeType? type) {
                                    setState(
                                      () {
                                        HapticFeedback.mediumImpact();
                                        _view = type ?? OpModeType.auto;
                                      },
                                    );
                                  },
                                ),
                              ),
                            if (NewPlatform.isAndroid || NewPlatform.isWeb)
                              SizedBox(
                                height: 50,
                                child: Material(
                                  child: TabBar(
                                    labelColor:
                                        Theme.of(context).colorScheme.primary,
                                    unselectedLabelColor: Colors.grey,
                                    labelStyle: Theme.of(context).textTheme.titleSmall,
                                    tabs: opModeExt
                                        .getMain()
                                        .map(
                                          (type) => Tab(
                                            text: type.getName(),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            Divider(
                              height: 5,
                              thickness: 2,
                            ),
                            if (NewPlatform.isAndroid || NewPlatform.isWeb)
                              Expanded(
                                child: TabBarView(
                                  children: opModeExt
                                      .getMain()
                                      .map((type) => viewSelect(type))
                                      .toList(),
                                ),
                              ),
                            if (NewPlatform.isIOS)
                              Expanded(
                                child: viewSelect(_view),
                              )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

  void stateSetter([String? key]) {
    HapticFeedback.mediumImpact();
    dataModel.saveEvents();
    if (key != null && !widget.event.shared) previouslyCycledElement = key;
  }

  Color getAllianceColor() {
    if (_match != null && widget.event.type == EventType.local) {
      if (_selectedAlliance == _match?.red)
        return red;
      else
        return blue;
    }
    return CupertinoColors.systemGreen;
  }

  Row buttonRow() {
    final teams = _match?.getTeams().toList() ?? [];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final team in teams)
          SizedBox(
            child: PlatformButton(
              child: Text(
                team?.number ?? '?',
                style: TextStyle(
                  color: _selectedTeam == team
                      ? Colors.grey
                      : _match?.alliance(team) == _match?.red
                          ? red
                          : blue,
                ),
              ),
              onPressed: _selectedTeam == team
                  ? null
                  : () => setState(
                        () {
                          _selectedTeam = team;
                          _selectedAlliance = _match?.alliance(team);
                          _score = _selectedTeam?.scores[_match?.id];
                          incrementValue.normalCount = _score?.teleScore
                                  .getElements()[0]
                                  .incrementValue ??
                              1;
                          final user = context.read<User?>();
                          widget.event
                              .getRef()
                              ?.child(
                                  'matches/${widget.match?.id}/activeUsers/${user?.uid}/watchingTeam')
                              .set(_selectedTeam?.number);
                        },
                      ),
            ),
          ),
      ],
    );
  }

  Alliance? getPenaltyAlliance() {
    if (_match?.type == EventType.remote || _match?.type == EventType.analysis)
      return _selectedAlliance;
    if (_selectedAlliance == _match?.red) return _match?.blue;
    if (_selectedAlliance == _match?.blue) return _match?.red;
    return null;
  }

  String getDcName(OpModeType type) {
    switch (type) {
      case OpModeType.auto:
        return 'autoDc';
      case OpModeType.tele:
        return 'teleDc';
      default:
        return 'endDc';
    }
  }

  ListView viewSelect(OpModeType type) {
    return ListView(
      children: !_paused || _allowView || type == OpModeType.auto
          ? [
              if ((widget.event.type != EventType.remote ||
                      widget.event.type != EventType.analysis) &&
                  _match != null)
                RawMaterialButton(
                  onPressed: () {
                    setState(() {
                      _score?.getScoreDivision(type).robotDisconnected =
                          !(_score?.getScoreDivision(type).robotDisconnected ??
                              false);
                    });
                    widget.event
                        .getRef()
                        ?.child(teamPath(OpModeType.auto))
                        .parent
                        ?.update(
                      {
                        getDcName(type):
                            _score?.getScoreDivision(type).robotDisconnected ??
                                false
                      },
                    );
                  },
                  fillColor:
                      (_score?.getScoreDivision(type).robotDisconnected ??
                              false)
                          ? Colors.yellow.withOpacity(0.3)
                          : null,
                  child: BarGraph(
                    title: "Contribution",
                    vertical: false,
                    height: MediaQuery.of(context).size.width*.9,
                    width: 15,
                    val: _score
                            ?.getScoreDivision(type)
                            .total(markDisconnect: false)
                            ?.toDouble() ??
                        0.0,
                    max: _selectedAlliance
                            ?.combinedScore()
                            .getScoreDivision(type)
                            .total(markDisconnect: false)
                            ?.toDouble() ??
                        0.0,
                  ),
                ),
              Incrementor(
                backgroundColor: Colors.grey.withOpacity(0.3),
                getTime: () => _time,
                element: incrementValue,
                onPressed: () => setState(
                  () {
                    _score?.teleScore.getElements().forEach((element) {
                      if (!element.isBool) {
                        element.incrementValue = incrementValue.normalCount;
                      }
                      stateSetter();
                    });
                  },
                ),
              ),
              if (_score?.getScoreDivision(type).robotDisconnected ?? false)
                Column(
                  children: [
                    Icon(Icons.warning),
                    Center(child: Text("Robot Disconnected")),
                  ],
                ),
              if (!(_score?.getScoreDivision(type).robotDisconnected ?? false))
                ..._score
                        ?.getScoreDivision(type)
                        .getElements()
                        .parse()
                        .map(
                          (e) => Incrementor(
                            getTime: () => _time,
                            element: e,
                            onPressed: () => stateSetter(e.key),
                            event: widget.event,
                            path: teamPath(type),
                            score: _score,
                            max: widget.match != null
                                ? (maxScoresInd[type]?[e.key] ?? 0)
                                : maxScoresTarget[type]?[e.key] ?? 0,
                          ),
                        )
                        .toList() ??
                    [],
              if (widget.match != null)
                ..._selectedAlliance?.sharedScore
                        .getScoreDivision(type)
                        .getElements()
                        .parse()
                        .map(
                          (e) => Incrementor(
                            getTime: () => _time,
                            element: e,
                            onPressed: () => stateSetter(e.key),
                            event: widget.event,
                            path: matchPath(type),
                            score: _score,
                            backgroundColor:
                                getAllianceColor().withOpacity(0.3),
                          ),
                        ) ??
                    [],
            ]
          : [
            Material(
                child: Row(
                  mainAxisAlignment:MainAxisAlignment.spaceAround,
                    children:[
                  Text("Begin "+(type==OpModeType.tele?"Tele-Op":"End Game") +" Phase"),
                  IconButton(
                  icon: Icon(Icons.play_arrow),
                  tooltip: 'Driver Control Play',
                  onPressed: () {
                    _paused = false;
                    _allowView = true;
                  },
                )]),
              ),
            Material(child:Row(
            mainAxisAlignment:MainAxisAlignment.spaceAround,
            children:[
              Text("View "+(type==OpModeType.tele?"Tele-Op":"End Game") +" Controls"),IconButton(
                icon: Icon(Icons.visibility),
                tooltip: 'View',
                onPressed: () {
                  _allowView = true;
                },
              )]),),
            ],
    );
  }

  String teamPath(OpModeType opModeType) {
    if (widget.match == null) {
      return 'teams/${_selectedTeam?.number}/targetScore/${opModeType.toRep()}';
    }
    return 'teams/${_selectedTeam?.number}/scores/${_score?.id}/${opModeType.toRep()}';
  }

  String matchPath(OpModeType opModeType) =>
      'matches/${widget.match?.id}/${allianceColor()}/sharedScore/${OpModeType.endgame.toRep()}';

  void mutableIncrement(Object? mutableData, ScoringElement element) {
    if (widget.match == null) return;
    var ref = (mutableData as Map?)?[element.key];
    if (ref is Map) {
      if (ref['count'] < element.max!()) {
        lapses.add(
          (_time - sum).toPrecision(3),
        );
        sum = _time;
        if (!_paused && previouslyCycledElement == element.key) {
          mutableData?[element.key]
              ?['cycleTimes'] = [...(ref['cycleTimes'] ?? []), lapses.last];
        }
        previouslyCycledElement = element.key;
      }
    }
  }

  ScoringElement incrementValue = ScoringElement(
    name: 'Increment Value',
    min: () => 1,
    normalCount: 1,
    key: null,
    value: 1,
  );

  void onIncrement(ScoringElement element) {
    lapses.add(
      (_time - sum).toPrecision(3),
    );
    sum = _time;
    if (!_paused && previouslyCycledElement == element.key) {
      element.cycleTimes.add(lapses.last);
    }
    previouslyCycledElement = element.key;
  }

  String allianceColor() {
    if (_selectedAlliance == _match?.blue) {
      return 'blue';
    } else {
      return 'red';
    }
  }
}
