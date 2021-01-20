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
  Score score = Score(Uuid(), Dice.one);
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
                  Theme.of(context).canvasColor
                ]),
          ),
          child: Center(
            child: Column(children: [
              Text('270 - 590', style: Theme.of(context).textTheme.headline3),
              buttonRow(),
              Text(_selectedTeam.name + ' : 30',
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
                height: 50,
                child: TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.ac_unit_outlined),
                    ),
                    Tab(
                      text: 'Wow',
                    ),
                    Tab(
                      text: 'Wow',
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

  bool _val = false;
  ListView autoView() {
    return ListView(
      children: [
        Row(children: [
          Padding(
            padding: EdgeInsets.all(5),
          ),
          Text('High Goals'),
          Spacer(),
          IconButton(
            icon: Icon(Icons.remove_circle_outline_rounded),
            splashColor: Colors.blue,
            onPressed: () {},
          ),
          Text('1'),
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded),
            color: Colors.deepPurple,
            splashColor: Colors.blue,
            onPressed: () {},
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
            onPressed: () {
              setState(() {
                score.autoScore.midGoals++;
              });
            },
            elevation: 2.0,
            fillColor: Colors.white,
            splashColor: Colors.red,
            child: Icon(Icons.remove_circle_outline_rounded),
            shape: CircleBorder(),
          ),
          Text(score.autoScore.midGoals.toString()),
          RawMaterialButton(
            onPressed: () {},
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
            value: _val,
            onChanged: (bool newVal) {
              setState(() {
                _val = newVal;
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
                      : Colors.red),
            ),
            onPressed: _selectedTeam == _match.red.item2
                ? null
                : () {
                    setState(() {
                      _selectedTeam = _match.red.item2;
                      _color = Colors.red;
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
                    });
                  },
            disabledColor: Colors.grey,
          ),
        )
      ],
    );
  }
}
