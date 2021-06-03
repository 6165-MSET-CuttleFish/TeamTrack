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
  MatchView({Key key, this.match, this.team, this.event}) : super(key: key);
  final Match match;
  final Team team;
  final Event event;
  @override
  _MatchView createState() => _MatchView(match, team);
}

class _MatchView extends State<MatchView> {
  Team _selectedTeam;
  Color _color = CupertinoColors.systemRed;
  Score _score;
  int _view = 0;
  Match _match;
  _MatchView(Match match, Team team) {
    if (team != null) {
      _score = team.targetScore;
      _selectedTeam = team;
      _color = CupertinoColors.systemGreen;
    } else {
      _match = match;
      _selectedTeam = match.red.item1;
      _score = _selectedTeam.scores.firstWhere(
          (element) => element.id == match.id,
          orElse: () => Score(Uuid().v4(), Dice.none));
      if (_match.type == EventType.remote) _color = CupertinoColors.systemGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Database.Event>(
        stream: DatabaseServices(id: widget.event.id).getEventChanges,
        builder: (context, eventHandler) {
          if (eventHandler.hasData && !eventHandler.hasError) {
            widget.event.updateLocal(
                json.decode(json.encode(eventHandler.data.snapshot.value)));
            _selectedTeam = widget.event.teams.firstWhere(
                (team) => team.number == _selectedTeam.number, orElse: () {
              Navigator.pop(context);
              return Team.nullTeam();
            });
            _score = _selectedTeam.scores.firstWhere(
                (element) => element.id == _match.id,
                orElse: () => Score(Uuid().v4(), Dice.none));
          }
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: _color,
                title: Text('Match Stats'),
                elevation: 0.0,
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
                    if (widget.match != null &&
                        widget.match.type != EventType.remote)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            width: 100,
                            child: Text(_match.redScore(),
                                style: Theme.of(context).textTheme.headline4),
                          ),
                          Container(
                            child: Text('-',
                                style: Theme.of(context).textTheme.headline4),
                          ),
                          Container(
                            width: 100,
                            child: Text(_match.blueScore(),
                                style: Theme.of(context).textTheme.headline4),
                          )
                        ],
                      ),
                    Padding(
                      padding: EdgeInsets.all(10),
                    ),
                    if (widget.match.type != EventType.remote) buttonRow(),
                    Text(_selectedTeam.name + ' : ' + _score.total().toString(),
                        style: Theme.of(context).textTheme.headline6),
                    if (widget.team == null)
                      DropdownButton<Dice>(
                        value: _match.dice,
                        icon: Icon(Icons.height_rounded),
                        iconSize: 24,
                        elevation: 16,
                        style: TextStyle(color: Theme.of(context).accentColor),
                        underline: Container(
                          height: 0.5,
                          color: Colors.deepPurpleAccent,
                        ),
                        onChanged: (Dice newValue) {
                          setState(() {
                            HapticFeedback.mediumImpact();
                            _match.setDice(newValue);
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
                                      _score.endgameScore.total().toString(),
                                  style: Theme.of(context).textTheme.caption))
                        ],
                      ),
                    ),
                    Divider(
                      height: 5,
                      thickness: 2,
                    ),
                    if (Platform.isIOS)
                      SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: CupertinoSlidingSegmentedControl(
                            groupValue: _view,
                            children: <int, Widget>{
                              0: Text('Autonomous'),
                              1: Text('Tele-Op'),
                              2: Text('Endgame')
                            },
                            onValueChanged: (int x) {
                              setState(() {
                                HapticFeedback.mediumImpact();
                                _view = x;
                              });
                            },
                          )),
                    if (Platform.isAndroid)
                      SizedBox(
                        height: 50,
                        child: TabBar(
                          labelColor: Theme.of(context).accentColor,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: TextStyle(fontFamily: '.SF UI Display'),
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
                    if (Platform.isAndroid)
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
                    if (Platform.isIOS)
                      Expanded(
                        child: viewSelect(),
                      )
                  ]),
                ),
              ),
            ),
          );
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

  List<Widget> endView() {
    return [
      Row(children: [
        Padding(
          padding: EdgeInsets.all(5),
        ),
        Text('Power Shots'),
        Spacer(),
        RawMaterialButton(
          onPressed: _score.endgameScore.pwrShots > 0
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.endgameScore.pwrShots--;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.red,
          child: Icon(Icons.remove_circle_outline_rounded),
          shape: CircleBorder(),
        ),
        SizedBox(
          width: 20,
          child: Text(
            _score.endgameScore.pwrShots.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        RawMaterialButton(
          onPressed: _score.endgameScore.pwrShots < 3
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.endgameScore.pwrShots++;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.green,
          child: Icon(Icons.add_circle_outline_rounded),
          shape: CircleBorder(),
        )
      ]),
      Divider(
        height: 3,
      ),
      Row(children: [
        Padding(
          padding: EdgeInsets.all(5),
        ),
        Text('Wobbles in Drop'),
        Spacer(),
        RawMaterialButton(
          onPressed: _score.endgameScore.wobbleGoalsInDrop > 0
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.endgameScore.wobbleGoalsInDrop--;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.red,
          child: Icon(Icons.remove_circle_outline_rounded),
          shape: CircleBorder(),
        ),
        SizedBox(
          width: 20,
          child: Text(
            _score.endgameScore.wobbleGoalsInDrop.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        RawMaterialButton(
          onPressed: _score.endgameScore.wobbleGoalsInDrop +
                      _score.endgameScore.wobbleGoalsInStart <
                  2
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.endgameScore.wobbleGoalsInDrop++;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.green,
          child: Icon(Icons.add_circle_outline_rounded),
          shape: CircleBorder(),
        )
      ]),
      Divider(
        height: 3,
      ),
      Row(children: [
        Padding(
          padding: EdgeInsets.all(5),
        ),
        Text('Wobbles in Start'),
        Spacer(),
        RawMaterialButton(
          onPressed: _score.endgameScore.wobbleGoalsInStart > 0
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.endgameScore.wobbleGoalsInStart--;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.red,
          child: Icon(Icons.remove_circle_outline_rounded),
          shape: CircleBorder(),
        ),
        SizedBox(
          width: 20,
          child: Text(
            _score.endgameScore.wobbleGoalsInStart.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        RawMaterialButton(
          onPressed: _score.endgameScore.wobbleGoalsInDrop +
                      _score.endgameScore.wobbleGoalsInStart <
                  2
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.endgameScore.wobbleGoalsInStart++;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.green,
          child: Icon(Icons.add_circle_outline_rounded),
          shape: CircleBorder(),
        )
      ]),
      Divider(
        height: 3,
      ),
      Row(children: [
        Padding(
          padding: EdgeInsets.all(5),
        ),
        Text('Rings on Wobble'),
        Spacer(),
        RawMaterialButton(
          onPressed: _score.endgameScore.ringsOnWobble > 0
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.endgameScore.ringsOnWobble--;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.red,
          child: Icon(Icons.remove_circle_outline_rounded),
          shape: CircleBorder(),
        ),
        SizedBox(
          width: 20,
          child: Text(
            _score.endgameScore.ringsOnWobble.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        RawMaterialButton(
          onPressed: () {
            setState(() {
              HapticFeedback.mediumImpact();
              _score.endgameScore.ringsOnWobble++;
            });
            dataModel.saveEvents();
            dataModel.uploadEvent(widget.event);
          },
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.green,
          child: Icon(Icons.add_circle_outline_rounded),
          shape: CircleBorder(),
        )
      ])
    ];
  }

  List<Widget> teleView() {
    return [
      Row(children: [
        Padding(
          padding: EdgeInsets.all(5),
        ),
        Text('High Goals'),
        Spacer(),
        RawMaterialButton(
          onPressed: _score.teleScore.hiGoals > 0
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.teleScore.hiGoals--;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.red,
          child: Icon(Icons.remove_circle_outline_rounded),
          shape: CircleBorder(),
        ),
        SizedBox(
          width: 20,
          child: Text(
            _score.teleScore.hiGoals.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        RawMaterialButton(
          onPressed: () {
            setState(() {
              HapticFeedback.mediumImpact();
              _score.teleScore.hiGoals++;
            });
            dataModel.saveEvents();
            dataModel.uploadEvent(widget.event);
          },
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.green,
          child: Icon(Icons.add_circle_outline_rounded),
          shape: CircleBorder(),
        )
      ]),
      Divider(
        height: 3,
      ),
      Row(children: [
        Padding(
          padding: EdgeInsets.all(5),
        ),
        Text('Middle Goals'),
        Spacer(),
        RawMaterialButton(
          onPressed: _score.teleScore.midGoals > 0
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.teleScore.midGoals--;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.red,
          child: Icon(Icons.remove_circle_outline_rounded),
          shape: CircleBorder(),
        ),
        SizedBox(
          width: 20,
          child: Text(
            _score.teleScore.midGoals.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        RawMaterialButton(
          onPressed: () {
            setState(() {
              HapticFeedback.mediumImpact();
              _score.teleScore.midGoals++;
            });
            dataModel.saveEvents();
            dataModel.uploadEvent(widget.event);
          },
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.green,
          child: Icon(Icons.add_circle_outline_rounded),
          shape: CircleBorder(),
        )
      ]),
      Divider(
        height: 3,
      ),
      Row(children: [
        Padding(
          padding: EdgeInsets.all(5),
        ),
        Text('Low Goals'),
        Spacer(),
        RawMaterialButton(
          onPressed: _score.teleScore.lowGoals > 0
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.teleScore.lowGoals--;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.red,
          child: Icon(Icons.remove_circle_outline_rounded),
          shape: CircleBorder(),
        ),
        SizedBox(
          width: 20,
          child: Text(
            _score.teleScore.lowGoals.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        RawMaterialButton(
          onPressed: () {
            setState(() {
              HapticFeedback.mediumImpact();
              _score.teleScore.lowGoals++;
            });
            dataModel.saveEvents();
            dataModel.uploadEvent(widget.event);
          },
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.green,
          child: Icon(Icons.add_circle_outline_rounded),
          shape: CircleBorder(),
        )
      ]),
    ];
  }

  List<Widget> autoView() {
    return [
      Row(children: [
        Padding(
          padding: EdgeInsets.all(5),
        ),
        Text('High Goals'),
        Spacer(),
        RawMaterialButton(
          onPressed: _score.autoScore.hiGoals > 0
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.autoScore.hiGoals--;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.red,
          child: Icon(Icons.remove_circle_outline_rounded),
          shape: CircleBorder(),
        ),
        SizedBox(
          width: 20,
          child: Text(
            _score.autoScore.hiGoals.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        RawMaterialButton(
          onPressed: () {
            setState(() {
              HapticFeedback.mediumImpact();
              _score.autoScore.hiGoals++;
            });
            dataModel.saveEvents();
            dataModel.uploadEvent(widget.event);
          },
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.green,
          child: Icon(Icons.add_circle_outline_rounded),
          shape: CircleBorder(),
        )
      ]),
      Divider(
        height: 3,
      ),
      Row(children: [
        Padding(
          padding: EdgeInsets.all(5),
        ),
        Text('Middle Goals'),
        Spacer(),
        RawMaterialButton(
          onPressed: _score.autoScore.midGoals > 0
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.autoScore.midGoals--;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.red,
          child: Icon(Icons.remove_circle_outline_rounded),
          shape: CircleBorder(),
        ),
        SizedBox(
          width: 20,
          child: Text(
            _score.autoScore.midGoals.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        RawMaterialButton(
          onPressed: () {
            setState(() {
              HapticFeedback.mediumImpact();
              _score.autoScore.midGoals++;
            });
            dataModel.saveEvents();
            dataModel.uploadEvent(widget.event);
          },
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.green,
          child: Icon(Icons.add_circle_outline_rounded),
          shape: CircleBorder(),
        )
      ]),
      Divider(
        height: 3,
      ),
      Row(children: [
        Padding(
          padding: EdgeInsets.all(5),
        ),
        Text('Low Goals'),
        Spacer(),
        RawMaterialButton(
          onPressed: _score.autoScore.lowGoals > 0
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.autoScore.lowGoals--;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.red,
          child: Icon(Icons.remove_circle_outline_rounded),
          shape: CircleBorder(),
        ),
        SizedBox(
          width: 20,
          child: Text(
            _score.autoScore.lowGoals.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        RawMaterialButton(
          onPressed: () {
            setState(() {
              HapticFeedback.mediumImpact();
              _score.autoScore.lowGoals++;
            });
            dataModel.saveEvents();
            dataModel.uploadEvent(widget.event);
          },
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.green,
          child: Icon(Icons.add_circle_outline_rounded),
          shape: CircleBorder(),
        )
      ]),
      Divider(
        height: 3,
      ),
      Row(children: [
        Padding(
          padding: EdgeInsets.all(5),
        ),
        Text('Wobble Goals'),
        Spacer(),
        RawMaterialButton(
          onPressed: _score.autoScore.wobbleGoals > 0
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.autoScore.wobbleGoals--;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.red,
          child: Icon(Icons.remove_circle_outline_rounded),
          shape: CircleBorder(),
        ),
        SizedBox(
          width: 20,
          child: Text(
            _score.autoScore.wobbleGoals.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        RawMaterialButton(
          onPressed: _score.autoScore.wobbleGoals < 2
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.autoScore.wobbleGoals++;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.green,
          child: Icon(Icons.add_circle_outline_rounded),
          shape: CircleBorder(),
        )
      ]),
      Divider(
        height: 3,
      ),
      Row(children: [
        Padding(
          padding: EdgeInsets.all(5),
        ),
        Text('Power Shots'),
        Spacer(),
        RawMaterialButton(
          onPressed: _score.autoScore.pwrShots > 0
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.autoScore.pwrShots--;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.red,
          child: Icon(Icons.remove_circle_outline_rounded),
          shape: CircleBorder(),
        ),
        SizedBox(
          width: 20,
          child: Text(
            _score.autoScore.pwrShots.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        RawMaterialButton(
          onPressed: _score.autoScore.pwrShots < 3
              ? () {
                  setState(() {
                    HapticFeedback.mediumImpact();
                    _score.autoScore.pwrShots++;
                  });
                  dataModel.saveEvents();
                  dataModel.uploadEvent(widget.event);
                }
              : null,
          elevation: 2.0,
          fillColor: Theme.of(context).canvasColor,
          splashColor: Colors.green,
          child: Icon(Icons.add_circle_outline_rounded),
          shape: CircleBorder(),
        )
      ]),
      Divider(
        height: 3,
      ),
      Row(children: [
        Padding(
          padding: EdgeInsets.all(5),
        ),
        Text('Navigated'),
        Spacer(),
        PlatformSwitch(
          value: _score.autoScore.navigated,
          onChanged: (bool newVal) {
            setState(() {
              HapticFeedback.mediumImpact();
              _score.autoScore.navigated = newVal;
            });
            dataModel.saveEvents();
            dataModel.uploadEvent(widget.event);
          },
        ),
      ])
    ];
  }

  Row buttonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
            flex: 1,
            child: PlatformButton(
              child: Text(
                _match.red.item1.number,
                style: TextStyle(
                    color: _selectedTeam == _match.red.item1
                        ? Colors.grey
                        : CupertinoColors.systemRed),
              ),
              onPressed: _selectedTeam == _match.red.item1
                  ? null
                  : () {
                      setState(() {
                        _selectedTeam = _match.red.item1;
                        _color = CupertinoColors.systemRed;
                        _score = _selectedTeam.scores.firstWhere(
                            (element) => element.id == _match.id,
                            orElse: () => Score(Uuid().v4(), Dice.none));
                      });
                    },
            )),
        Flexible(
            flex: 1,
            child: PlatformButton(
              child: Text(
                _match.red.item2.number,
                style: TextStyle(
                  color: _selectedTeam == _match.red.item2
                      ? Colors.grey
                      : CupertinoColors.systemRed,
                ),
              ),
              onPressed: _selectedTeam == _match.red.item2
                  ? null
                  : () {
                      setState(() {
                        _selectedTeam = _match.red.item2;
                        _color = CupertinoColors.systemRed;
                        _score = _selectedTeam.scores.firstWhere(
                            (element) => element.id == _match.id,
                            orElse: () => Score(Uuid().v4(), Dice.none));
                      });
                    },
            )),
        Spacer(),
        Flexible(
            flex: 1,
            child: PlatformButton(
              child: Text(
                _match.blue.item1.number,
                style: TextStyle(
                    color: _selectedTeam == _match.blue.item1
                        ? Colors.grey
                        : Colors.blue),
              ),
              onPressed: _selectedTeam == _match.blue.item1
                  ? null
                  : () {
                      setState(() {
                        _selectedTeam = _match.blue.item1;
                        _color = Colors.blue;
                        _score = _selectedTeam.scores.firstWhere(
                            (element) => element.id == _match.id,
                            orElse: () => Score(Uuid().v4(), Dice.none));
                      });
                    },
            )),
        Flexible(
            flex: 1,
            child: PlatformButton(
              child: Text(
                _match.blue.item2.number,
                style: TextStyle(
                    color: _selectedTeam == _match.blue.item2
                        ? Colors.grey
                        : Colors.blue),
              ),
              onPressed: _selectedTeam == _match.blue.item2
                  ? null
                  : () {
                      setState(() {
                        _selectedTeam = _match.blue.item2;
                        _color = Colors.blue;
                        _score = _selectedTeam.scores.firstWhere(
                            (element) => element.id == _match.id,
                            orElse: () => Score(Uuid().v4(), Dice.none));
                      });
                    },
            ))
      ],
    );
  }
}
