import 'package:teamtrack/Frontend/MatchList.dart';
import 'package:teamtrack/Frontend/TeamList.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';

class EventView extends StatefulWidget {
  EventView({Key? key, required this.event}) : super(key: key);
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
  List<Widget> materialTabs() => [
        TeamList(
          event: widget.event,
        ),
        MatchList(
          event: widget.event,
        ),
      ];

  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: _tab == 0 ? Text('Teams') : Text('Matches'),
          backgroundColor: Theme.of(context).accentColor,
          actions: [
            IconButton(
              icon: Icon(
                Icons.search,
              ),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: _tab == 0
                      ? TeamSearch(
                          teams: widget.event.teams.sortedTeams(),
                          event: widget.event,
                        )
                      : MatchSearch(
                          matches: widget.event.matches,
                          event: widget.event,
                        ),
                );
              },
            ),
          ]),
      bottomNavigationBar: widget.event.type != EventType.remote
          ? BottomNavigationBar(
              currentIndex: _tab,
              onTap: (index) {
                setState(
                  () {
                    _tab = index;
                  },
                );
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
        onPressed: () async {
          if (_tab == 0)
            _teamConfig();
          else
            _matchConfig();
        },
      ),
    );
  }

  void _matchConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _addMatch(),
      ),
    );
  }

  String _newName = '';
  String _newNumber = '';
  void _teamConfig() {
    showPlatformDialog(
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
            Padding(
              padding: EdgeInsets.all(5),
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
              setState(
                () {
                  if (_newNumber.isNotEmpty && _newName.isNotEmpty)
                    widget.event.addTeam(
                      Team(_newNumber, _newName),
                    );
                  _newName = '';
                  _newNumber = '';
                },
              );
              dataModel.saveEvents();
              dataModel.uploadEvent(widget.event);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  final List<TextEditingController> controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
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
        list.add(
          Container(
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
            ),
          ),
        );
      } else if (i == 2) {
        list.add(
          Container(
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
            ),
          ),
        );
      }
      list.add(
        Row(
          children: [
            Expanded(
              child: TextFormField(
                autofillHints: widget.event.teams.map((e) => e.number),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Team number'),
                validator: (String? value) {
                  if (names[i].isEmpty) {
                    return 'Number is required';
                  } else {
                    return null;
                  }
                },
                onChanged: (String val) {
                  setState(
                    () {
                      names[i] = val;
                      controllers[i].value = TextEditingValue(
                        text: widget.event.teams
                            .firstWhere(
                              (element) =>
                                  element.number ==
                                  val
                                      .replaceAll(
                                        RegExp(r' ,-.[^\w\s]+'),
                                        '',
                                      )
                                      .replaceAll(
                                        ' ',
                                        '',
                                      ),
                            )
                            .name,
                        selection: TextSelection.fromPosition(
                          TextPosition(offset: val.length),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: controllers[i],
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return 'Name is required';
                  } else {
                    return null;
                  }
                },
                onChanged: (String val) {
                  setState(
                    () {
                      controllers[i].value = TextEditingValue(
                        text: val,
                        selection: TextSelection.fromPosition(
                          TextPosition(offset: val.length),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    list.add(
      PlatformButton(
        color: Colors.green,
        child: Text('Save'),
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            setState(
              () {
                widget.event.matches.add(
                  Match(
                      Alliance(
                        widget.event.teams
                            .findAdd(names[0], controllers[0].text),
                        widget.event.teams
                            .findAdd(names[1], controllers[1].text),
                      ),
                      Alliance(
                        widget.event.teams
                            .findAdd(names[2], controllers[2].text),
                        widget.event.teams
                            .findAdd(names[3], controllers[3].text),
                      ),
                      widget.event.type),
                );
              },
            );
            for (TextEditingController controller in controllers) {
              controller.text = '';
            }
            dataModel.saveEvents();
            dataModel.uploadEvent(widget.event);
            Navigator.pop(context);
          }
        },
      ),
    );
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
            child: Padding(
              padding: EdgeInsets.only(left: 5, right: 5),
              child: ListView(
                children: _textFields(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
