import 'package:flutter/services.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/match/MatchConfig.dart';
import 'package:teamtrack/views/home/match/MatchList.dart';
import 'package:teamtrack/views/home/team/TeamList.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class EventView extends StatefulWidget {
  EventView({Key? key, required this.event}) : super(key: key);
  final Event event;
  @override
  _EventView createState() => _EventView();
}

class _EventView extends State<EventView> {
  final slider = SlidableStrechActionPane();
  OpModeType? sortingModifier;
  bool ascending = false;
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: _tab == 0 ? Text('Teams') : Text('Matches'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            _tab != 0
                ? IconButton(
                    tooltip: "Sort",
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
                          teams: widget.event.teams.values.toList(),
                          event: widget.event,
                        )
                      : MatchSearch(
                          matches: widget.event.getSortedMatches(true),
                          event: widget.event,
                        ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: widget.event.type != EventType.remote
            ? CurvedNavigationBar(
                animationCurve: Curves.easeOutQuint,
                animationDuration: const Duration(milliseconds: 1000),
                buttonBackgroundColor: Theme.of(context).colorScheme.secondary,
                color: Theme.of(context).textTheme.bodyText1?.color ??
                    Colors.black,
                index: _tab,
                backgroundColor: Colors.transparent,
                onTap: (index) => setState(
                  () => _tab = index,
                ),
                items: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.person_3_fill,
                        size: 20,
                        color: _tab == 1 ? Theme.of(context).canvasColor : null,
                      ),
                      Text(
                        'Teams',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              _tab == 1 ? Theme.of(context).canvasColor : null,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.sportscourt_fill,
                        size: 20,
                        color: _tab == 0 ? Theme.of(context).canvasColor : null,
                      ),
                      Text(
                        'Matches',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              _tab == 0 ? Theme.of(context).canvasColor : null,
                        ),
                      ),
                    ],
                  )
                ],
              )
            : null,
        body: materialTabs()[_tab],
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.primary,
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
            child: Text('Add'),
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
