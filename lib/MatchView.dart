import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:teamtrack/backend.dart';
import 'package:teamtrack/score.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

class MatchView extends StatefulWidget {
  MatchView({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MatchView createState() => _MatchView(Match(
      Tuple2(Team('1', 'Alpha'), Team('2', 'Beta')),
      Tuple2(Team('3', 'Charlie'), Team('4', 'Delta')),
      EventType.local));
}

class _MatchView extends State<MatchView> {
  Match _match;
  Team _selectedTeam;
  Color _color = Colors.red;
  Score _score = Score(Uuid(), Dice.one);
  _MatchView(Match match) {
    this._match = match;
    _selectedTeam = match.red.item1;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Match Stats'),
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
                  Theme.of(context).canvasColor
                ]),
          ),
          child: Center(
            child: Column(children: [
              Text(_match.score(), style: Theme.of(context).textTheme.headline3),
              buttonRow(),
              Text(_selectedTeam.name + ' : ' + _score.total().toString(),
                  style: Theme.of(context).textTheme.headline6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Text('Stack Height '),
                  DropdownButton<Dice>(
                    value: _match.dice,
                    icon: Icon(Icons.height_rounded),
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
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
                        child: Text(
                            'Stack Height : ' + value.stackHeight().toString()),
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(
                child: TabBar(
                  labelColor: Colors.deepPurple,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(
                      text: 'Autonomous',
                      //icon: Icon(Icons.ac_unit_outlined),
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
              Expanded(
                child: TabBarView(
                  children: [
                    autoView(),

                    // second tab bar view widget
                    Container(
                        color: Colors.pink,
                        child: Center(
                          child: Text(
                            'Car',
                          ),
                        )),
                    Container(
                      color: Colors.red,
                      child: Center(
                        child: Text(
                          'Bike',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
  ListView autoView() {
    return ListView(
      children: [
        Row(children: [
          Padding(
            padding: EdgeInsets.all(5),
          ),
          Text('High Goals'),
          Spacer(),
          RawMaterialButton(
            onPressed: _score.autoScore.hiGoals > 0 ? () { setState(() {_score.autoScore.hiGoals--; });} : null,
            elevation: 2.0,
            fillColor: Colors.white,
            splashColor: Colors.red,
            child: Icon(Icons.remove_circle_outline_rounded),
            shape: CircleBorder(),
          ),
          SizedBox(
            width: 20,
            child: Text(_score.autoScore.hiGoals.toString(), textAlign: TextAlign.center,),
          ),
          RawMaterialButton(
            onPressed: () { setState(() {
              _score.autoScore.hiGoals++;
            }); },
            elevation: 2.0,
            fillColor: Colors.white,
            splashColor: Colors.green,
            child: Icon(Icons.add_circle_outline_rounded),
            shape: CircleBorder(),
          )
        ]),
        Divider(
          height: 3,
          color: Colors.black,
        ),
        Row(children: [
          Padding(
            padding: EdgeInsets.all(5),
          ),
          Text('Middle Goals'),
          Spacer(),
          RawMaterialButton(
            onPressed: _score.autoScore.midGoals > 0 ? () { setState(() {_score.autoScore.midGoals--; });} : null,
            elevation: 2.0,
            fillColor: Colors.white,
            splashColor: Colors.red,
            child: Icon(Icons.remove_circle_outline_rounded),
            shape: CircleBorder(),
          ),
          SizedBox(
            width: 20,
            child: Text(_score.autoScore.midGoals.toString(), textAlign: TextAlign.center,),
          ),
          RawMaterialButton(
            onPressed: () { setState(() {
              _score.autoScore.midGoals++;
            }); },
            elevation: 2.0,
            fillColor: Colors.white,
            splashColor: Colors.green,
            child: Icon(Icons.add_circle_outline_rounded),
            shape: CircleBorder(),
          )
        ]),
        Divider(
          height: 3,
          color: Colors.black,
        ),
        Row(children: [
          Padding(
            padding: EdgeInsets.all(5),
          ),
          Text('Low Goals'),
          Spacer(),
          RawMaterialButton(
            onPressed: _score.autoScore.lowGoals > 0 ? () { setState(() {_score.autoScore.lowGoals--; });} : null,
            elevation: 2.0,
            fillColor: Colors.white,
            splashColor: Colors.red,
            child: Icon(Icons.remove_circle_outline_rounded),
            shape: CircleBorder(),
          ),
          SizedBox(
            width: 20,
            child: Text(_score.autoScore.lowGoals.toString(), textAlign: TextAlign.center,),
          ),
          RawMaterialButton(
            onPressed: () { setState(() {
              _score.autoScore.lowGoals++;
            }); },
            elevation: 2.0,
            fillColor: Colors.white,
            splashColor: Colors.green,
            child: Icon(Icons.add_circle_outline_rounded),
            shape: CircleBorder(),
          )
        ]),
        Divider(
          height: 3,
          color: Colors.black,
        ),
        Row(children: [
          Padding(
            padding: EdgeInsets.all(5),
          ),
          Text('Wobble Goals'),
          Spacer(),
          RawMaterialButton(
            onPressed: _score.autoScore.wobbleGoals > 0 ? () { setState(() {_score.autoScore.wobbleGoals--; });} : null,
            elevation: 2.0,
            fillColor: Colors.white,
            splashColor: Colors.red,
            child: Icon(Icons.remove_circle_outline_rounded),
            shape: CircleBorder(),
          ),
          SizedBox(
            width: 20,
            child: Text(_score.autoScore.wobbleGoals.toString(), textAlign: TextAlign.center,),
          ),
          RawMaterialButton(
            onPressed: _score.autoScore.wobbleGoals < 2 ? () { setState(() {_score.autoScore.wobbleGoals++; });} : null,
            elevation: 2.0,
            fillColor: Colors.white,
            splashColor: Colors.green,
            child: Icon(Icons.add_circle_outline_rounded),
            shape: CircleBorder(),
          )
        ]),
        Divider(
          height: 3,
          color: Colors.black,
        ),
        Row(children: [
          Padding(
            padding: EdgeInsets.all(5),
          ),
          Text('Power Shots'),
          Spacer(),
          RawMaterialButton(
            onPressed: _score.autoScore.pwrShots > 0 ? () { setState(() {_score.autoScore.pwrShots--; });} : null,
            elevation: 2.0,
            fillColor: Colors.white,
            splashColor: Colors.red,
            child: Icon(Icons.remove_circle_outline_rounded),
            shape: CircleBorder(),
          ),
          SizedBox(
            width: 20,
            child: Text(_score.autoScore.pwrShots.toString(), textAlign: TextAlign.center,),
          ),
          RawMaterialButton(
            onPressed: _score.autoScore.pwrShots < 3 ? () { setState(() {_score.autoScore.pwrShots++; });} : null,
            elevation: 2.0,
            fillColor: Colors.white,
            splashColor: Colors.green,
            child: Icon(Icons.add_circle_outline_rounded),
            shape: CircleBorder(),
          )
        ]),
        Divider(
          height: 3,
          color: Colors.black,
        ),
        Row(children: [
          Padding(
            padding: EdgeInsets.all(5),
          ),
          Text('Navigated'),
          Spacer(),
          CupertinoSwitch(
            value: _score.autoScore.navigated,
            onChanged: (bool newVal) {
              setState(() {
                _score.autoScore.navigated = newVal;
              });
            },
          )
        ])
      ],
    );
  }

  Row buttonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          flex: 1,
          child: CupertinoButton(
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
                      _score = _selectedTeam.scores.firstWhere((element) => element.id == _match.id);
                    });
                  },
            disabledColor: Colors.grey,
          ),
        ),
        Flexible(
          flex: 1,
          child: CupertinoButton(
            child: Text(
              _match.red.item2.name,
              style: TextStyle(
                  color: _selectedTeam == _match.red.item2
                      ? Colors.grey
                      : Colors.red,),
            ),
            onPressed: _selectedTeam == _match.red.item2
                ? null
                : () {
                    setState(() {
                      _selectedTeam = _match.red.item2;
                      _color = Colors.red;
                      _score = _selectedTeam.scores.firstWhere((element) => element.id == _match.id);
                    });
                  },
            disabledColor: Colors.grey,
          ),
        ),
        Spacer(),
        Flexible(
          flex: 1,
          child: CupertinoButton(
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
                      _score = _selectedTeam.scores.firstWhere((element) => element.id == _match.id);
                    });
                  },
            disabledColor: Colors.grey,
          ),
        ),
        Flexible(
          flex: 1,
          child: CupertinoButton(
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
                      _score = _selectedTeam.scores.firstWhere((element) => element.id == _match.id);
                    });
                  },
            disabledColor: Colors.grey,
          ),
        )
      ],
    );
  }
}
