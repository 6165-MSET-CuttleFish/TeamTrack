import 'package:flutter/services.dart';
import 'package:teamtrack/Frontend/MatchConfig.dart';
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
  OpModeType? sortingModifier = OpModeType.auto;
  bool ascending = true;
  List<Widget> materialTabs() => [
        TeamList(
          event: widget.event,
          sortMode: sortingModifier,
        ),
        MatchList(
          event: widget.event,
          ascending: ascending,
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
          _tab != 0
              ? IconButton(
                  icon: Icon(
                    ascending
                        ? CupertinoIcons.sort_up
                        : CupertinoIcons.sort_down,
                  ),
                  onPressed: () {
                    setState(() {
                      ascending = !ascending;
                    });
                  },
                )
              : Center(
                  child: DropdownButton<OpModeType?>(
                    value: sortingModifier,
                    icon: Icon(Icons.sort),
                    iconSize: 24,
                    elevation: 16,
                    underline: Container(
                      height: 0.5,
                      color: Colors.deepPurple,
                    ),
                    onChanged: (newValue) {
                      HapticFeedback.lightImpact();
                      setState(() => sortingModifier = newValue);
                    },
                    items: [
                      null,
                      OpModeType.auto,
                      OpModeType.tele,
                      OpModeType.endgame,
                    ].map<DropdownMenuItem<OpModeType?>>(
                      (value) {
                        return DropdownMenuItem<OpModeType?>(
                          value: value,
                          child: Text((value?.toVal() ?? "Subtotal") + " "),
                        );
                      },
                    ).toList(),
                  ),
                ),
          IconButton(
            icon: Icon(
              Icons.search,
            ),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _tab == 0
                    ? TeamSearch(
                        teams: widget.event.teams.sortedTeams(sortingModifier),
                        event: widget.event,
                      )
                    : MatchSearch(
                        matches: widget.event.getSortedMatches(ascending),
                        event: widget.event,
                      ),
              );
            },
          ),
        ],
      ),
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

  void _matchConfig() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchConfig(event: widget.event),
      ),
    );
    setState(() {});
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
              onChanged: (input) => _newName = input,
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
                  _newNumber = _newNumber.split('').reduce((value, element) =>
                      int.tryParse(element) != null
                          ? value += element
                          : value = value);
                  if (_newNumber.isNotEmpty && _newName.isNotEmpty)
                    widget.event.addTeam(
                      Team(_newNumber, _newName),
                    );
                  _newName = '';
                  _newNumber = '';
                },
              );
              dataModel.saveEvents();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
