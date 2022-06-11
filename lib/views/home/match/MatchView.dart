import 'package:http/http.dart' as http;
import 'package:teamtrack/api/APIKEYS.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:teamtrack/components/BarGraph.dart';
import 'package:teamtrack/components/Incrementor.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/providers/Auth.dart';
import 'package:teamtrack/components/ScoreSummary.dart';
import 'package:teamtrack/components/UsersRow.dart';
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
      _allianceTotal = true,
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
    totalMaxTotal = event.matches.values
        .map((element) => [element.red, element.blue])
        .reduce((value, element) => value + element)
        .map((e) => e?.total().total())
        .maxValue();
    totalMaxInd = event.teams.values
        .map(
          (e) => _match == null
              ? e.targetScore?.total()
              : e.scores.maxScore(
                  Dice.none,
                  false,
                  null,
                  null,
                ),
        )
        .maxValue();
    autoMaxTotal = event.matches.values
        .map((element) => [element.red, element.blue])
        .reduce((value, element) => value + element)
        .map((e) => e?.total().autoScore.total())
        .maxValue();
    autoMaxInd = event.teams.values
        .map(
          (e) => _match == null
              ? e.targetScore?.autoScore.total()
              : e.scores.maxScore(Dice.none, false, OpModeType.auto, null),
        )
        .maxValue();
    teleMaxTotal = event.matches.values
        .map((element) => [element.red, element.blue])
        .reduce((value, element) => value + element)
        .map((e) => e?.total().teleScore.total())
        .maxValue();
    teleMaxInd = event.teams.values
        .map(
          (e) => _match == null
              ? e.targetScore?.teleScore.total()
              : e.scores.maxScore(Dice.none, false, OpModeType.tele, null),
        )
        .maxValue();
    endgameMaxTotal = event.matches.values
        .map((element) => [element.red, element.blue])
        .reduce((value, element) => value + element)
        .map((e) => e?.total().endgameScore.total())
        .maxValue();
    endgameMaxInd = event.teams.values
        .map(
          (e) => _match == null
              ? e.targetScore?.endgameScore.total()
              : e.scores.maxScore(Dice.none, false, OpModeType.endgame, null),
        )
        .maxValue();
    cyclesMaxTotal = event.matches.values
        .map((element) => [element.red, element.blue])
        .reduce((value, element) => value + element)
        .map((e) => e?.total().teleScore.totalCycles())
        .maxValue();
    cyclesMaxInd = event.teams.values
        .map(
          (e) => _match == null
              ? e.targetScore?.teleScore.totalCycles()
              : e.scores.values
                  .map((e) => e.teleScore.totalCycles())
                  .maxValue(),
        )
        .maxValue();
    teleCyclesMaxTotal = event.matches.values
        .map((element) => [element.red, element.blue])
        .reduce((value, element) => value + element)
        .map((e) => e?.total().teleScore.teleCycles())
        .maxValue();
    teleCyclesMaxInd = event.teams.values
        .map(
          (e) => _match == null
              ? e.targetScore?.teleScore.teleCycles()
              : e.scores.values.map((e) => e.teleScore.teleCycles()).maxValue(),
        )
        .maxValue();
    endgameCyclesMaxTotal = event.matches.values
        .map((element) => [element.red, element.blue])
        .reduce((value, element) => value + element)
        .map((e) => e?.total().teleScore.endgameCycles())
        .maxValue();
    endgameCyclesMaxInd = event.teams.values
        .map(
          (e) => _match == null
              ? e.targetScore?.teleScore.endgameCycles()
              : e.scores.values
                  .map((e) => e.teleScore.endgameCycles())
                  .maxValue(),
        )
        .maxValue();
    Score('', Dice.none, event.gameName)
        .autoScore
        .getElements()
        .parse(putNone: false)
        .forEach(
      (e) {
        maxAutoScores[e.key ?? ''] = event.teams.values
            .map(
              (team) => team.scores.values
                  .map((score) => score.autoScore
                      .getElements()
                      .parse()
                      .firstWhere((element) => element.key == e.key,
                          orElse: () => ScoringElement())
                      .scoreValue())
                  .maxValue(),
            )
            .maxValue();
        maxAutoTargets[e.key ?? ''] = event.teams.values
            .map((team) => team.targetScore?.autoScore
                .getElements()
                .parse()
                .firstWhere((element) => element.key == e.key,
                    orElse: () => ScoringElement())
                .scoreValue())
            .maxValue();
      },
    );
    Score('', Dice.none, event.gameName)
        .teleScore
        .getElements()
        .parse(putNone: false)
        .forEach(
      (e) {
        maxTeleScores[e.key ?? ''] = event.teams.values
            .map(
              (team) => team.scores.values
                  .map((score) => score.teleScore
                      .getElements()
                      .parse()
                      .firstWhere((element) => element.key == e.key,
                          orElse: () => ScoringElement())
                      .scoreValue())
                  .maxValue(),
            )
            .maxValue();
        maxTeleTargets[e.key ?? ''] = event.teams.values
            .map((team) => team.targetScore?.teleScore
                .getElements()
                .parse()
                .firstWhere((element) => element.key == e.key,
                    orElse: () => ScoringElement())
                .scoreValue())
            .maxValue();
      },
    );
    Score('', Dice.none, event.gameName)
        .endgameScore
        .getElements()
        .parse(putNone: false)
        .forEach(
      (e) {
        maxEndgameScores[e.key ?? ''] = event.teams.values
            .map(
              (team) => team.scores.values
                  .map((score) => score.endgameScore
                      .getElements()
                      .parse()
                      .firstWhere((element) => element.key == e.key,
                          orElse: () => ScoringElement())
                      .scoreValue())
                  .maxValue(),
            )
            .maxValue();
        maxEndgameTargets[e.key ?? ''] = event.teams.values
            .map((team) => team.targetScore?.endgameScore
                .getElements()
                .parse()
                .firstWhere((element) => element.key == e.key,
                    orElse: () => ScoringElement())
                .scoreValue())
            .maxValue();
      },
    );
  }

  double totalMaxTotal = 0,
      totalMaxInd = 0,
      autoMaxInd = 0,
      autoMaxTotal = 0,
      teleMaxInd = 0,
      teleMaxTotal = 0,
      endgameMaxInd = 0,
      endgameMaxTotal = 0;
  double cyclesMaxInd = 0,
      cyclesMaxTotal = 0,
      teleCyclesMaxInd = 0,
      teleCyclesMaxTotal = 0,
      endgameCyclesMaxInd = 0,
      endgameCyclesMaxTotal = 0,
      missesInd = 0,
      missesTotal = 0;
  Map<String, double> maxTeleScores = {};
  Map<String, double> maxEndgameScores = {};
  Map<String, double> maxAutoScores = {};
  Map<String, double> maxAutoTargets = {};
  Map<String, double> maxTeleTargets = {};
  Map<String, double> maxEndgameTargets = {};

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
    } else {
      _allianceTotal = false;
      try {
        http
            .get(
          Uri.parse('${APIKEYS.TOA_URL}/team/${widget.team?.number}'),
          headers: APIKEYS.TOA_HEADER,
        )
            .then((value) {
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
                    if (_time > 90 && !_endgameStarted) {
                      HapticFeedback.heavyImpact();
                      _endgameStarted = true;
                    }
                  }
                }
              }
              final secondsLeft = 120 - _time;
              final minutes = secondsLeft >= 0 ? secondsLeft ~/ 60 : 0;
              final seconds = secondsLeft >= 0 ? secondsLeft % 60 : 0;
              String timerText =
                  '$minutes:${seconds.toInt().toString().padLeft(2, '0')}';
              return Container(
                child: DefaultTabController(
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
                            if (_time > 90)
                              for (int i = 0; i < 2; i++)
                                Colors.deepOrange.withOpacity(0.4),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            if (_match?.type != EventType.remote &&
                                widget.match != null)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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
                                                  .bodyText1,
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
                                Text(
                                  ("${_selectedTeam?.number} : ${_selectedTeam?.name ?? ''}"),
                                  style: Theme.of(context).textTheme.headline6,
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
                                                .caption,
                                          ),
                                        if (widget.team?.established != null)
                                          Text(
                                            "est. ${widget.team?.established}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .caption,
                                          ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 5.0, bottom: 5.0),
                                  child: RawMaterialButton(
                                    fillColor: _allianceTotal &&
                                            widget.event.type !=
                                                EventType.remote
                                        ? _color.withOpacity(0.3)
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
                                          ? _selectedAlliance?.total()
                                          : _score,
                                      autoMax: (widget.event.type ==
                                                      EventType.remote &&
                                                  widget.match != null) ||
                                              _allianceTotal
                                          ? autoMaxTotal
                                          : autoMaxInd,
                                      teleMax: (widget.event.type ==
                                                      EventType.remote &&
                                                  widget.match != null) ||
                                              _allianceTotal
                                          ? teleMaxTotal
                                          : teleMaxInd,
                                      endMax: (widget.event.type ==
                                                      EventType.remote &&
                                                  widget.match != null) ||
                                              _allianceTotal
                                          ? endgameMaxTotal
                                          : endgameMaxInd,
                                      totalMax: (widget.event.type ==
                                                      EventType.remote &&
                                                  widget.match != null) ||
                                              _allianceTotal
                                          ? totalMaxTotal
                                          : totalMaxInd,
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
                                              element: e,
                                              onPressed: stateSetter,
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
                            if (NewPlatform.isAndroid || NewPlatform.isWeb)
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
            child: Text(
              _match?.red?.team2?.number ?? '?',
              style: TextStyle(
                color: _selectedTeam == _match?.red?.team2 ? Colors.grey : red,
              ),
            ),
            onPressed: _selectedTeam == _match?.red?.team2
                ? null
                : () => setState(
                      () {
                        _selectedTeam = _match?.red?.team2;
                        _selectedAlliance = _match?.red;
                        _color = red;
                        _score = _selectedTeam?.scores[_match?.id];
                      },
                    ),
          ),
        ),
        SizedBox(
          child: PlatformButton(
            child: Text(
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
            child: Text(
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
    return null;
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
        if (widget.event.type != EventType.remote && _match != null)
          RawMaterialButton(
            onPressed: () {
              setState(() {
                _score?.autoScore.robotDisconnected =
                    !(_score?.autoScore.robotDisconnected ?? false);
              });
              widget.event
                  .getRef()
                  ?.child(teamPath(OpModeType.auto))
                  .parent
                  ?.update(
                {'autoDc': _score?.autoScore.robotDisconnected ?? false},
              );
            },
            fillColor: (_score?.autoScore.robotDisconnected ?? false)
                ? Colors.yellow.withOpacity(0.3)
                : null,
            child: BarGraph(
              title: "Contribution",
              vertical: false,
              height: MediaQuery.of(context).size.width,
              width: 15,
              val: _score?.autoScore.total(markDisconnect: false)?.toDouble() ??
                  0.0,
              max: _selectedAlliance
                      ?.total()
                      .autoScore
                      .total(markDisconnect: false)
                      ?.toDouble() ??
                  0.0,
            ),
          ),
        if (_score?.autoScore.robotDisconnected ?? false)
          Column(
            children: [
              Icon(Icons.warning),
              Center(child: Text("Robot Disconnected")),
            ],
          ),
        if (!(_score?.autoScore.robotDisconnected ?? false))
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
                      max: widget.match != null
                          ? maxAutoScores[e.key] ?? 0
                          : maxAutoTargets[e.key] ?? 0,
                    ),
                  )
                  .toList() ??
              [],
        if (widget.match != null)
          ..._selectedAlliance?.sharedScore.autoScore.getElements().parse().map(
                    (e) => Incrementor(
                      element: e,
                      onPressed: stateSetter,
                      event: widget.event,
                      path: matchPath(OpModeType.auto),
                      score: _score,
                      backgroundColor: _color.withOpacity(0.3),
                    ),
                  ) ??
              [],
      ];

  List<Widget> teleView() => !_paused || _allowView
      ? [
          if (widget.event.type != EventType.remote && _match != null)
            RawMaterialButton(
              onPressed: () {
                setState(() {
                  _score?.teleScore.robotDisconnected =
                      !(_score?.teleScore.robotDisconnected ?? false);
                });
                widget.event
                    .getRef()
                    ?.child(teamPath(OpModeType.tele))
                    .parent
                    ?.update(
                  {'teleDc': _score?.teleScore.robotDisconnected ?? false},
                );
              },
              fillColor: (_score?.autoScore.robotDisconnected ?? false)
                  ? Colors.yellow.withOpacity(0.3)
                  : null,
              child: BarGraph(
                title: "Contribution",
                vertical: false,
                height: MediaQuery.of(context).size.width,
                width: 15,
                val: _score?.teleScore
                        .total(markDisconnect: false)
                        ?.toDouble() ??
                    0.0,
                max: _selectedAlliance
                        ?.total()
                        .teleScore
                        .total(markDisconnect: false)
                        ?.toDouble() ??
                    0.0,
              ),
            ),
          if (widget.event.type == EventType.remote && _match != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BarGraph(
                  height: 40,
                  title: "Total Cycles",
                  val: _score?.teleScore.totalCycles().toDouble() ?? 0.0,
                  max: (widget.event.type == EventType.remote &&
                              widget.match != null) ||
                          _allianceTotal
                      ? cyclesMaxTotal
                      : cyclesMaxInd,
                ),
                BarGraph(
                  height: 40,
                  title: "Tele-Op Cycles",
                  val: _score?.teleScore.teleCycles().toDouble() ?? 0.0,
                  max: (widget.event.type == EventType.remote &&
                              widget.match != null) ||
                          _allianceTotal
                      ? teleCyclesMaxTotal
                      : teleCyclesMaxInd,
                ),
                BarGraph(
                  height: 40,
                  title: "Endgame Cycles",
                  val: _score?.teleScore.endgameCycles().toDouble() ?? 0.0,
                  max: (widget.event.type == EventType.remote &&
                              widget.match != null) ||
                          _allianceTotal
                      ? endgameCyclesMaxTotal
                      : endgameCyclesMaxInd,
                ),
                BarGraph(
                  height: 40,
                  title: "Misses",
                  val: _score?.teleScore.misses.count.toDouble() ?? 0.0,
                  max: (widget.event.type == EventType.remote &&
                              widget.match != null) ||
                          _allianceTotal
                      ? missesTotal
                      : missesInd,
                  inverted: true,
                ),
              ],
            ),
          Incrementor(
            backgroundColor: Colors.grey.withOpacity(0.3),
            element: incrementValue,
            onPressed: () => setState(
              () {
                _score?.teleScore.getElements().forEach((element) {
                  if (!element.isBool) {
                    element.incrementValue = incrementValue.count;
                  }
                  stateSetter();
                });
              },
            ),
          ),
          if (_score?.teleScore.robotDisconnected ?? false)
            Column(
              children: [
                Icon(Icons.warning),
                Center(child: Text("Robot Disconnected")),
              ],
            ),
          if (!(_score?.teleScore.robotDisconnected ?? false))
            ..._score?.teleScore
                    .getElements()
                    .parse()
                    .map(
                      (e) => Incrementor(
                        element: e,
                        onPressed: stateSetter,
                        onDecrement:
                            widget.match != null ? increaseMisses : null,
                        onIncrement: _paused ? null : onIncrement,
                        event: widget.event,
                        path: teamPath(OpModeType.tele),
                        score: _score,
                        // mutableIncrement: (mutableData) {
                        //   if (widget.match == null) {
                        //     var ref = (mutableData as Map?)?[e.key];
                        //     if (ref < e.max!())
                        //       mutableData?[e.key] =
                        //           (ref ?? 0) + incrementValue.count;
                        //     return Transaction.success(mutableData);
                        //   }
                        //   var ref = mutableData as Map?;
                        //   if (ref?[e.key] < e.max!()) {
                        //     mutableData?[e.key] =
                        //         (ref?[e.key] ?? 0) + e.incrementValue;
                        //     lapses.add(
                        //       (_time - sum).toPrecision(3),
                        //     );
                        //     sum = _time;
                        //     if (!_paused) {
                        //       mutableData?['CycleTimes'] = lapses;
                        //     }
                        //   }
                        //   return Transaction.success(mutableData);
                        // },
                        // mutableDecrement: (mutableData) {
                        //   if (widget.match == null) {
                        //     var ref = (mutableData as Map?)?[e.key];
                        //     if (ref < e.max!())
                        //       mutableData?[e.key] = (ref ?? 0) - 1;
                        //     return Transaction.success(mutableData);
                        //   }
                        //   var ref = mutableData as Map?;
                        //   if (ref?[e.key] < e.max!()) {
                        //     mutableData?[e.key] =
                        //         (ref?[e.key] ?? 0) - e.decrementValue;
                        //     if (!_paused) {
                        //       mutableData?['Misses'] = (ref?['Misses'] ?? 0) + 1;
                        //     }
                        //   }
                        //   return Transaction.success(mutableData);
                        // },
                        max: widget.match != null
                            ? maxTeleScores[e.key] ?? 0
                            : maxTeleTargets[e.key] ?? 0,
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
                        backgroundColor: _color.withOpacity(0.3),
                      ),
                    ) ??
                [],
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
          if (widget.event.type != EventType.remote && _match != null)
            RawMaterialButton(
              onPressed: () {
                setState(() {
                  _score?.endgameScore.robotDisconnected =
                      !(_score?.endgameScore.robotDisconnected ?? false);
                });
                widget.event
                    .getRef()
                    ?.child(teamPath(OpModeType.endgame))
                    .parent
                    ?.update(
                  {'endDc': _score?.endgameScore.robotDisconnected ?? false},
                );
              },
              fillColor: (_score?.autoScore.robotDisconnected ?? false)
                  ? Colors.yellow.withOpacity(0.3)
                  : null,
              child: BarGraph(
                title: "Contribution",
                vertical: false,
                height: MediaQuery.of(context).size.width,
                width: 15,
                val: _score?.endgameScore
                        .total(markDisconnect: false)
                        ?.toDouble() ??
                    0.0,
                max: _selectedAlliance
                        ?.total()
                        .endgameScore
                        .total(markDisconnect: false)
                        ?.toDouble() ??
                    0.0,
              ),
            ),
          if (_score?.endgameScore.robotDisconnected ?? false)
            Column(
              children: [
                Icon(Icons.warning),
                Center(child: Text("Robot Disconnected")),
              ],
            ),
          if (!(_score?.endgameScore.robotDisconnected ?? false))
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
                        max: widget.match != null
                            ? maxEndgameScores[e.key] ?? 0
                            : maxEndgameTargets[e.key] ?? 0,
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
                        backgroundColor: _color.withOpacity(0.3),
                      ),
                    ) ??
                [],
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
          (mutableData as Map?)?['teams'] as Map;
          teamIndex = _selectedTeam?.number;
        } catch (e) {
          teamIndex = int.parse(_selectedTeam?.number ?? '');
        }
        final scoreIndex = _score?.id;
        var ref = (mutableData as Map?)?['teams'][teamIndex]['scores']
            [scoreIndex]['TeleScore']['Misses'];
        mutableData?['teams'][teamIndex]['scores'][scoreIndex]['TeleScore']
            ['Misses'] = (ref ?? 0) + 1;
        return Transaction.success(mutableData);
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
