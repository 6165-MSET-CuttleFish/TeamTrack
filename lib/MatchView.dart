import 'package:TeamTrack/PlatformGraphics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:TeamTrack/backend.dart';
import 'package:TeamTrack/score.dart';
import 'dart:io' show Platform;

class MatchView extends StatefulWidget {
  MatchView({Key key, this.match}) : super(key: key);
  final Match match;

  @override
  _MatchView createState() => _MatchView(match);
}

class _MatchView extends State<MatchView> {
  Match _match;
  Team _selectedTeam;
  Color _color = Colors.red;
  Score _score;
  int _view = 0;

  _MatchView(Match match) {
    this._match = match;
    _selectedTeam = match.red.item1;
    _score =
        _selectedTeam.scores.firstWhere((element) => element.id == _match.id);
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
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
                  ]),
            ),
            child: Center(
              child: Column(children: [
                Text(_match.score(),
                    style: Theme.of(context).textTheme.headline3),
                buttonRow(),
                Text(_selectedTeam.name + ' : ' + _score.total().toString(),
                    style: Theme.of(context).textTheme.headline6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<Dice>(
                      value: _match.dice,
                      icon: Icon(Icons.height_rounded),
                      iconSize: 24,
                      elevation: 16,
                      style: TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        height: 0.5,
                        color: Colors.deepPurpleAccent,
                      ),
                      onChanged: (Dice newValue) {
                        setState(() {
                          _match.dice = newValue;
                        });
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
                  ],
                ),
                if (Platform.isIOS)
                  CupertinoSlidingSegmentedControl(
                    groupValue: _view,
                    children: <int, Widget>{
                      0: Text('Autonomous : ' +
                          _score.autoScore.total().toString()),
                      1: Text(
                          'Tele-Op : ' + _score.teleScore.total().toString()),
                      2: Text(
                          'Endgame : ' + _score.endgameScore.total().toString())
                    },
                    onValueChanged: (int x) {
                      setState(() {
                        _view = x;
                      });
                    },
                  ),
                if (Platform.isAndroid)
                  SizedBox(
                    height: 50,
                    child: TabBar(
                      labelColor: Theme.of(context).accentColor,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: '.SF UI Display'),
                      tabs: [
                        Tab(
                          text: 'Autonomous : ' +
                              _score.autoScore.total().toString(),
                          //icon: Icon(Icons.ac_unit_outlined),
                        ),
                        Tab(
                          text: 'Tele-Op : ' +
                              _score.teleScore.total().toString(),
                        ),
                        Tab(
                          text: 'Endgame : ' +
                              _score.endgameScore.total().toString(),
                        )
                      ],
                    ),
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
                if (Platform.isIOS) Expanded(child: viewSelect())
              ]),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
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
                  ]),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Row(
                  // mainAxisAlignment: MainAxisAlignment.start,
                  // children: [Text(' Match Stats', style: Theme.of(context).textTheme.headline4)]
                  // ),
                  Text(_match.score(),
                      style: Theme.of(context).textTheme.headline4),
                  buttonRow(),
                  Text(_selectedTeam.name + ' : ' + _score.total().toString(),
                      style: Theme.of(context).textTheme.headline6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                            _match.dice = newValue;
                          });
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
                    ],
                  ),

                  CupertinoSlidingSegmentedControl(
                    groupValue: _view,
                    children: <int, Widget>{
                      0: Text('Autonomous : ' +
                          _score.autoScore.total().toString()),
                      1: Text(
                          'Tele-Op : ' + _score.teleScore.total().toString()),
                      2: Text(
                          'Endgame : ' + _score.endgameScore.total().toString())
                    },
                    onValueChanged: (int x) {
                      setState(() {
                        _view = x;
                      });
                    },
                  ),
                  Expanded(
                    child: viewSelect(),
                  )
                ],
              ),
            ),
          ));
    }
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
                    _score.endgameScore.pwrShots--;
                  });
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
                    _score.endgameScore.pwrShots++;
                  });
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
                    _score.endgameScore.wobbleGoalsInDrop--;
                  });
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
                    _score.endgameScore.wobbleGoalsInDrop++;
                  });
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
                    _score.endgameScore.wobbleGoalsInStart--;
                  });
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
                    _score.endgameScore.wobbleGoalsInStart++;
                  });
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
                    _score.endgameScore.ringsOnWobble--;
                  });
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
              _score.endgameScore.ringsOnWobble++;
            });
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
                    _score.teleScore.hiGoals--;
                  });
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
              _score.teleScore.hiGoals++;
            });
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
                    _score.teleScore.midGoals--;
                  });
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
              _score.teleScore.midGoals++;
            });
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
                    _score.teleScore.lowGoals--;
                  });
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
              _score.teleScore.lowGoals++;
            });
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
                    _score.autoScore.hiGoals--;
                  });
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
              _score.autoScore.hiGoals++;
            });
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
                    _score.autoScore.midGoals--;
                  });
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
              _score.autoScore.midGoals++;
            });
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
                    _score.autoScore.lowGoals--;
                  });
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
              _score.autoScore.lowGoals++;
            });
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
                    _score.autoScore.wobbleGoals--;
                  });
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
                    _score.autoScore.wobbleGoals++;
                  });
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
                    _score.autoScore.pwrShots--;
                  });
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
                    _score.autoScore.pwrShots++;
                  });
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
              _score.autoScore.navigated = newVal;
            });
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
                _match.red.item1.name,
                style: TextStyle(
                    color: _selectedTeam == _match.red.item1
                        ? Colors.grey
                        : Colors.red),
              ),
              onPressed: _selectedTeam == _match.red.item1
                  ? null
                  : () {
                      setState(() {
                        _selectedTeam = _match.red.item1;
                        _color = Colors.red;
                        _score = _selectedTeam.scores
                            .firstWhere((element) => element.id == _match.id);
                      });
                    },
            )),
        Flexible(
            flex: 1,
            child: PlatformButton(
              child: Text(
                _match.red.item2.name,
                style: TextStyle(
                  color: _selectedTeam == _match.red.item2
                      ? Colors.grey
                      : Colors.red,
                ),
              ),
              onPressed: _selectedTeam == _match.red.item2
                  ? null
                  : () {
                      setState(() {
                        _selectedTeam = _match.red.item2;
                        _color = Colors.red;
                        _score = _selectedTeam.scores
                            .firstWhere((element) => element.id == _match.id);
                      });
                    },
            )),
        Spacer(),
        Flexible(
            flex: 1,
            child: PlatformButton(
              child: Text(
                _match.blue.item1.name,
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
                        _score = _selectedTeam.scores
                            .firstWhere((element) => element.id == _match.id);
                      });
                    },
            )),
        Flexible(
            flex: 1,
            child: PlatformButton(
              child: Text(
                _match.blue.item2.name,
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
                        _score = _selectedTeam.scores
                            .firstWhere((element) => element.id == _match.id);
                      });
                    },
            ))
      ],
    );
  }
}
