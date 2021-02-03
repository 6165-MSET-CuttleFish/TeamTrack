import 'dart:io';

import 'package:TeamTrack/TeamView.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:TeamTrack/MatchView.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'backend.dart';
import 'package:TeamTrack/Graphic Assets/PlatformGraphics.dart';

class EventView extends StatefulWidget {
  EventView({Key key, this.event}) : super(key: key);
  final Event event;
  @override
  _EventView createState() => _EventView();
}

class _EventView extends State<EventView> {
  final slider = SlidableStrechActionPane();
  final secondaryActions = <Widget>[
    IconSlideAction(
      caption: 'Delete',
      icon: Icons.delete,
      color: Colors.red,
      onTap: () {},
    )
  ];
  List<Widget> materialTabs() {
    return <Widget>[
      ListView(
        children: widget.event.teams
            .map((e) => Slidable(
                  actionPane: slider,
                  secondaryActions: [
                    IconSlideAction(
                      icon: Icons.delete,
                      color: Colors.red,
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) => PlatformAlert(
                                  title: Text('Delete Team'),
                                  content: Text('Are you sure?'),
                                  actions: [
                                    PlatformDialogAction(
                                      isDefaultAction: true,
                                      child: Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    PlatformDialogAction(
                                      isDefaultAction: false,
                                      isDestructive: true,
                                      child: Text('Confirm'),
                                      onPressed: () {
                                        setState(() {
                                          widget.event.teams.remove(e);
                                        });
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ));
                      },
                    )
                  ],
                  child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        title: Text(e.name),
                        leading: Text(e.number,
                            style: Theme.of(context).textTheme.caption),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => TeamView(
                                        team: e,
                                        event: widget.event,
                                      )));
                        },
                      )),
                ))
            .toList(),
      ),
      ListView(
        semanticChildCount: widget.event.matches.length,
        children: widget.event.matches
            .map((e) => Slidable(
                actionPane: slider,
                secondaryActions: [
                  IconSlideAction(
                    icon: Icons.delete,
                    color: Colors.red,
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => PlatformAlert(
                                title: Text('Delete Match'),
                                content: Text('Are you sure?'),
                                actions: [
                                  PlatformDialogAction(
                                    isDefaultAction: true,
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  PlatformDialogAction(
                                    isDefaultAction: false,
                                    isDestructive: true,
                                    child: Text('Confirm'),
                                    onPressed: () {
                                      setState(() {
                                        e.red.item1.scores
                                            .removeWhere((f) => f.id == e.id);
                                        e.red.item2.scores
                                            .removeWhere((f) => f.id == e.id);
                                        e.blue.item1.scores
                                            .removeWhere((f) => f.id == e.id);
                                        e.blue.item2.scores
                                            .removeWhere((f) => f.id == e.id);
                                        widget.event.matches.remove(e);
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ));
                    },
                  )
                ],
                child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Column(children: [
                        Text(e.red.item1.name + ' & ' + e.red.item2.name),
                        Text(
                          'VS',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        Text(e.blue.item1.name + ' & ' + e.blue.item2.name)
                      ]),
                      trailing: Text(e.score()),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MatchView(match: e)));
                      },
                    ))))
            .toList(),
      ),
    ];
  }

  List<Widget> cupertinoTabs() {
    return <Widget>[
      CupertinoPageScaffold(
          child: SafeArea(
              child: Scaffold(
                  body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text('Teams'),
            previousPageTitle: 'Events',
            trailing: CupertinoButton(
              child: Text('Add'),
              onPressed: () {
                setState(() {
                  widget.event.teams.add(Team('7390', 'JCjos'));
                });
              },
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(widget.event.teams
                .map((e) => ListTile(
                      title: Text(e.name),
                      leading: Text(e.number,
                          style: Theme.of(context).textTheme.caption),
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => TeamView(team: e)));
                      },
                    ))
                .toList()),
          ),
        ],
      )))),
      CupertinoPageScaffold(
          child: SafeArea(
              child: Scaffold(
                  body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text('Matches'),
            previousPageTitle: 'Events',
            trailing: CupertinoButton(
              child: Text('Add'),
              onPressed: () {
                setState(() {
                  widget.event.matches.add(Match.defaultMatch(EventType.local));
                });
              },
            ),
            leading: CupertinoButton(
              child: Text('Events'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(widget.event.matches
                .map((e) => ListTile(
                      leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(e.red.item1.name + ' & ' + e.red.item2.name),
                            Text(
                              'VS',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(e.blue.item1.name + ' & ' + e.blue.item2.name)
                          ]),
                      trailing: Text(e.score()),
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => MatchView(match: e)));
                      },
                    ))
                .toList()),
          ),
        ],
      )))),
    ];
  }

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: _tab == 0 ? Text('Teams') : Text('Matches'),
          backgroundColor: Theme.of(context).accentColor,
        ),
        bottomNavigationBar: widget.event.type != EventType.remote
            ? BottomNavigationBar(
                currentIndex: _tab,
                onTap: (int index) {
                  setState(() {
                    _tab = index;
                  });
                },
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.person_3_fill),
                    label: 'Teams',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.sportscourt_fill),
                    label: 'Matches',
                  )
                ],
              )
            : null,
        body: materialTabs()[_tab],
        floatingActionButton: FloatingActionButton(
          tooltip: _tab == 0 ? 'Add Team' : 'Add Match',
          child: Icon(Icons.add),
          onPressed: () {
            if (_tab == 0) {
              _teamConfig();
            } else {
              _matchConfig();
            }
          },
        ),
      );
    } else {
      return CupertinoTabScaffold(
        tabBuilder: (BuildContext context, int index) {
          return CupertinoTabView(
            builder: (BuildContext context) {
              return CupertinoPageScaffold(child: cupertinoTabs()[_tab]);
            },
          );
        },
        tabBar: CupertinoTabBar(
          currentIndex: _tab,
          items: [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person_3_fill),
              label: 'Teams',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.sportscourt_fill),
              label: 'Matches',
            )
          ],
          onTap: (int x) {
            _tab = x;
          },
        ),
      );
    }
  }

  void _matchConfig() {
    if (Platform.isAndroid) {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return _addMatch();
          });
    } else {
      showCupertinoModalPopup(
          context: null,
          builder: (context) {
            return CupertinoPageScaffold(child: Text('Hello'));
          });
    }
  }

  String _newName;
  String _newNumber;
  void _teamConfig() {
    showDialog(
        context: context,
        builder: (BuildContext context) => PlatformAlert(
              title: Text('New Team'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlatformTextField(
                    placeholder: 'Team number',
                    keyboardType: TextInputType.number,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (String input) {
                      _newNumber = input;
                    },
                  ),
                  PlatformTextField(
                    placeholder: 'Team name',
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (String input) {
                      _newName = input;
                    },
                  ),
                ],
              ),
              actions: [
                PlatformDialogAction(
                  isDefaultAction: true,
                  child: Text('Cancel'),
                  onPressed: () {
                    _newName = '';
                    _newNumber = '';
                    Navigator.of(context).pop();
                  },
                ),
                PlatformDialogAction(
                  isDefaultAction: false,
                  child: Text('Save'),
                  onPressed: () {
                    setState(() {
                      if (_newNumber.isNotEmpty && _newName.isNotEmpty)
                        widget.event.addTeam(Team(_newNumber, _newName));
                      _newName = '';
                      _newNumber = '';
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }

  final List<TextEditingController> controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController()
  ];
  final names = ['', '', '', ''];
  String r0 = '';
  String r1 = '';
  String b0 = '';
  String b1 = '';
  final _formKey = GlobalKey<FormState>();
  List<Widget> _textFields() {
    var list = <Widget>[];
    for (int i = 0; i < 4; i++) {
      if (i == 0) {
        list.add(Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.transparent,
                width: 6,
              ),
              borderRadius: BorderRadius.circular(60),
              color: Colors.red,
            ),
            alignment: Alignment.center,
            child: Text(
              'Red Alliance',
              style: Theme.of(context).textTheme.headline6,
            )));
      } else if (i == 2) {
        list.add(Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.transparent,
                width: 6,
              ),
              borderRadius: BorderRadius.circular(60),
              color: Colors.blue,
            ),
            alignment: Alignment.center,
            child: Text(
              'Blue Alliance',
              style: Theme.of(context).textTheme.headline6,
            )));
      }
      list.add(
        Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Team number'),
                validator: (String value) {
                  if (names[i].isEmpty) {
                    return 'Number is required';
                  } else {
                    return null;
                  }
                },
                onChanged: (String val) {
                  setState(() {
                    names[i] = val;
                    controllers[i].value = TextEditingValue(
                      text: widget.event.teams
                          .firstWhere((element) =>
                              element.number ==
                              val
                                  .replaceAll(new RegExp(r' [^\w\s]+'), '')
                                  .replaceAll(' ', ''))
                          .name,
                      selection: TextSelection.fromPosition(
                        TextPosition(offset: val.length),
                      ),
                    );
                  });
                },
              ),
            ),
            Expanded(
                child: TextFormField(
              controller: controllers[i],
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: 'Name'),
              validator: (String value) {
                if (value.isEmpty) {
                  return 'Name is required';
                } else {
                  return null;
                }
              },
              onChanged: (String val) {
                setState(() {
                  controllers[i].value = TextEditingValue(
                    text: val,
                    selection: TextSelection.fromPosition(
                      TextPosition(offset: val.length),
                    ),
                  );
                });
              },
            )),
          ],
        ),
      );
    }
    list.add(PlatformButton(
      color: Colors.green,
      child: Text('Save'),
      onPressed: () {
        if (_formKey.currentState.validate()) {
          setState(() {
            widget.event.matches.add(Match(
                Alliance(
                    widget.event.teams.findAdd(names[0], controllers[0].text),
                    widget.event.teams.findAdd(names[1], controllers[1].text)),
                Alliance(
                    widget.event.teams.findAdd(names[2], controllers[2].text),
                    widget.event.teams.findAdd(names[3], controllers[3].text)),
                widget.event.type));
          });
          for (TextEditingController controller in controllers) {
            controller.text = '';
          }
          Navigator.pop(context);
        }
      },
    ));
    return list;
  }

  Widget _addMatch() {
    return Scaffold(
        appBar: AppBar(
          title: Text('Add Match'),
          backgroundColor: Theme.of(context).accentColor,
        ),
        body: SafeArea(
          child: Center(
              child: Form(
                  key: _formKey,
                  child: ListView(
                    children: _textFields(),
                  ))),
        ));
  }
}
