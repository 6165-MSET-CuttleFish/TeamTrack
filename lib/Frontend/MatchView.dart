import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:provider/provider.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:teamtrack/backend.dart';
import 'package:teamtrack/score.dart';
import 'dart:io' show Platform;
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
  State createState() => _MatchView(match, team);
}

class _MatchView extends State<MatchView> {
  Team _selectedTeam = Team.nullTeam();
  Color _color = CupertinoColors.systemRed;
  Score _score = Score(Uuid().v4(), Dice.none);
  int _view = 0;
  Match? _match; // = Match.defaultMatch(EventType.remote);
  final Stream<int> _periodicStream =
      Stream.periodic(const Duration(milliseconds: 100), (i) => i);
  double _time = 0;
  List<double> lapses = [];
  int? _previousStreamValue = 0;
  bool _paused = true;
  _MatchView(Match? match, Team? team) {
    if (team != null) {
      _score = team.targetScore ?? Score(Uuid().v4(), Dice.none);
      _selectedTeam = team;
      _color = CupertinoColors.systemGreen;
    } else {
      _match = match;
      _selectedTeam = match?.red?.item1 ?? Team.nullTeam();
      _score = _selectedTeam.scores.firstWhere(
        (element) => element.id == match?.id,
        orElse: () => Score(Uuid().v4(), Dice.none),
      );
      if (_match!.type == EventType.remote)
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
              json.encode(eventHandler.data!.snapshot.value),
            ),
          );
          if (widget.team == null) {
            _match = widget.event.matches
                .firstWhere((element) => element.id == _match!.id, orElse: () {
              Navigator.pop(context);
              return Match.defaultMatch(EventType.remote);
            });
          }
          _selectedTeam = widget.event.teams.firstWhere(
              (team) => team.number == _selectedTeam.number, orElse: () {
            Navigator.pop(context);
            return Team.nullTeam();
          });
          if (widget.team != null) {
            _score = _selectedTeam.targetScore ?? Score(Uuid().v4(), Dice.none);
          } else {
            _score = _selectedTeam.scores.firstWhere(
                (element) => element.id == _match!.id,
                orElse: () => Score(Uuid().v4(), Dice.none));
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
                    elevation: 0.0,
                    actions: [
                      Text(_time.roundToDouble().toString()),
                      IconButton(
                        icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                        onPressed: () => setState(() => _paused = !_paused),
                      ),
                      IconButton(
                        icon: Icon(Icons.stop),
                        onPressed: () => setState(() {
                          _paused = true;
                          _time = 0;
                        }),
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
                          ]),
                    ),
                    child: Center(
                      child: Column(children: [
                        if (_match != null && _match!.type != EventType.remote)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                width: 100,
                                child: Text(_match?.redScore() ?? '0',
                                    style:
                                        Theme.of(context).textTheme.headline4),
                              ),
                              Container(
                                child: Text('-',
                                    style:
                                        Theme.of(context).textTheme.headline4),
                              ),
                              Container(
                                width: 100,
                                child: Text(_match?.blueScore() ?? '0',
                                    style:
                                        Theme.of(context).textTheme.headline4),
                              )
                            ],
                          ),
                        Padding(
                          padding: EdgeInsets.all(10),
                        ),
                        if (_match != null && _match?.type != EventType.remote)
                          buttonRow(),
                        Text(
                            _selectedTeam.name +
                                ' : ' +
                                _score.total().toString(),
                            style: Theme.of(context).textTheme.headline6),
                        if (widget.team == null)
                          DropdownButton<Dice>(
                            value: _match?.dice,
                            icon: Icon(Icons.height_rounded),
                            iconSize: 24,
                            elevation: 16,
                            style:
                                TextStyle(color: Theme.of(context).accentColor),
                            underline: Container(
                              height: 0.5,
                              color: Colors.deepPurpleAccent,
                            ),
                            onChanged: (newValue) {
                              setState(() {
                                HapticFeedback.mediumImpact();
                                _match?.setDice(newValue ?? Dice.one);
                              });
                              dataModel.saveEvents();
                              dataModel.uploadEvent(widget.event);
                            },
                            items: <Dice>[Dice.one, Dice.two, Dice.three]
                                .map<DropdownMenuItem<Dice>>((Dice value) {
                              return DropdownMenuItem<Dice>(
                                value: value,
                                child: Text('Stack Height : ' +
                                    value.stackHeight().toString()),
                              );
                            }).toList(),
                          ),
                        Padding(
                          padding: EdgeInsets.all(25),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                  child: Text(
                                'Autonomous : ' +
                                    _score.autoScore.total().toString(),
                                style: Theme.of(context).textTheme.caption,
                              )),
                              SizedBox(
                                child: Text(
                                    'Tele-Op : ' +
                                        _score.teleScore.total().toString(),
                                    style: Theme.of(context).textTheme.caption),
                              ),
                              SizedBox(
                                  child: Text(
                                      'Endgame : ' +
                                          _score.endgameScore
                                              .total()
                                              .toString(),
                                      style:
                                          Theme.of(context).textTheme.caption))
                            ],
                          ),
                        ),
                        Divider(
                          height: 5,
                          thickness: 2,
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
                                  setState(() {
                                    HapticFeedback.mediumImpact();
                                    _view = x ?? 0;
                                  });
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
                      ]),
                    ),
                  ),
                ),
              );
            });
      });

  void stateSetter() {
    dataModel.saveEvents();
    dataModel.uploadEvent(widget.event);
  }

  void teleStateSetter() {
    if (lapses.length == 0)
      lapses.add(_time);
    else
      lapses.add(_time - lapses.reduce((value, element) => value + element));
    if (lapses.length > 4) _score.teleScore.cycles = lapses.getBoxAndWhisker();
    stateSetter();
  }

  ListView viewSelect() {
    switch (_view) {
      case 0:
        return ListView(children: autoView());
      case 1:
        return ListView(children: teleView());
      default:
        return ListView(children: endView());
    }
  }

  List<Widget> endView() => _score.endgameScore
      .getElements()
      .map((e) => Incrementor(element: e, onPressed: stateSetter))
      .toList();

  List<Widget> teleView() => _score.teleScore
      .getElements()
      .map((e) => Incrementor(element: e, onPressed: teleStateSetter))
      .toList();

  List<Widget> autoView() => _score.autoScore
      .getElements()
      .map((e) => Incrementor(element: e, onPressed: stateSetter))
      .toList();

  Row buttonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
            flex: 1,
            child: PlatformButton(
              child: Text(
                _match?.red?.item1?.number ?? '?',
                style: TextStyle(
                    color: _selectedTeam == _match?.red?.item1
                        ? Colors.grey
                        : CupertinoColors.systemRed),
              ),
              onPressed: _selectedTeam == _match?.red?.item1
                  ? null
                  : () {
                      setState(() {
                        _selectedTeam = _match?.red?.item1 ?? Team.nullTeam();
                        _color = CupertinoColors.systemRed;
                        _score = _selectedTeam.scores.firstWhere(
                          (element) => element.id == _match?.id,
                          orElse: () => Score(Uuid().v4(), Dice.none),
                        );
                      });
                    },
            )),
        Flexible(
            flex: 1,
            child: PlatformButton(
              child: Text(
                _match?.red?.item2?.number ?? '?',
                style: TextStyle(
                  color: _selectedTeam == _match?.red?.item2
                      ? Colors.grey
                      : CupertinoColors.systemRed,
                ),
              ),
              onPressed: _selectedTeam == _match?.red?.item2
                  ? null
                  : () {
                      setState(() {
                        _selectedTeam = _match?.red?.item2 ?? Team.nullTeam();
                        _color = CupertinoColors.systemRed;
                        _score = _selectedTeam.scores.firstWhere(
                          (element) => element.id == _match?.id,
                          orElse: () => Score(Uuid().v4(), Dice.none),
                        );
                      });
                    },
            )),
        Spacer(),
        Flexible(
            flex: 1,
            child: PlatformButton(
              child: Text(
                _match?.blue?.item1?.number ?? '?',
                style: TextStyle(
                    color: _selectedTeam == _match?.blue?.item1
                        ? Colors.grey
                        : Colors.blue),
              ),
              onPressed: _selectedTeam == _match?.blue?.item1
                  ? null
                  : () {
                      setState(() {
                        _selectedTeam = _match?.blue?.item1 ?? Team.nullTeam();
                        _color = Colors.blue;
                        _score = _selectedTeam.scores.firstWhere(
                          (element) => element.id == _match?.id,
                          orElse: () => Score(Uuid().v4(), Dice.none),
                        );
                      });
                    },
            )),
        Flexible(
            flex: 1,
            child: PlatformButton(
              child: Text(
                _match?.blue?.item2?.number ?? '?',
                style: TextStyle(
                    color: _selectedTeam == _match?.blue?.item2
                        ? Colors.grey
                        : Colors.blue),
              ),
              onPressed: _selectedTeam == _match?.blue?.item2
                  ? null
                  : () => setState(() {
                        _selectedTeam = _match?.blue?.item2 ?? Team.nullTeam();
                        _color = Colors.blue;
                        _score = _selectedTeam.scores.firstWhere(
                          (element) => element.id == _match?.id,
                          orElse: () => Score(Uuid().v4(), Dice.none),
                        );
                      }),
            ))
      ],
    );
  }
}
