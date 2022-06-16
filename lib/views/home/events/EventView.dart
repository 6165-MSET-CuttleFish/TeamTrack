import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/views/LandingPage.dart' as LandingPage;
import 'package:teamtrack/views/home/match/MatchConfig.dart';
import 'package:teamtrack/views/home/match/MatchList.dart';
import 'package:teamtrack/components/CheckList.dart';
import 'package:teamtrack/views/home/team/TeamList.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:teamtrack/functions/Statistics.dart';

import '../../../api/APIKEYS.dart';

class EventView extends StatefulWidget {
  EventView({
    Key? key,
    required this.event,
    this.isPreview = false,
  }) : super(key: key);
  final Event event;
  final bool isPreview;
  @override
  _EventView createState() => _EventView();
}

class _EventView extends State<EventView> {
  OpModeType? sortingModifier;
  ScoringElement? elementSort;
  bool ascending = false;
  List<Widget> materialTabs() => [
        TeamList(
          event: widget.event,
          sortMode: sortingModifier,
          statConfig: widget.event.statConfig,
          elementSort: elementSort,
        ),
        MatchList(
          event: widget.event,
          ascending: ascending,
        ),
      ];
  int _tab = 0;
  List bod = [];
  _getMatches() async {
    APIKEYS.getMatches(widget.event.getKey()).then((response) {
      setState(() {
        bod = (json.decode(response.body).toList());
        //print(bod);
      });
    });
  }
  initState() {
    _getMatches();
    super.initState();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: widget.isPreview
              ? Text(widget.event.name)
              : (_tab == 0 ? Text('Teams') : Text('Matches')),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            if (_tab == 0)
              IconButton(
                icon: Icon(Icons.settings),
                tooltip: 'Configure',
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => CheckList(
                    state: this,
                    event: widget.event,
                    statConfig: widget.event.statConfig,
                  ),
                ),
              ),
            if(_tab!=0&&widget.event.hasKey()&&!widget.event.isloaded())
            IconButton(
              icon: Icon(Icons.refresh),
              tooltip: 'Reload Matches',
              onPressed: ()
              {
   print(widget.event.getKey());
                _getMatches();
                for(var x in bod) {

               setState( () {
                widget.event.addMatch(
                  Match(
                    Alliance(
                      widget.event.teams
                          .findAdd(
                          x['participants'][0]['team']['team_number']
                              .toString(),
                          x['participants'][0]['team']['team_name_short']
                              .toString(), widget.event),
                      widget.event.teams
                          .findAdd(
                          x['participants'][1]['team']['team_number']
                              .toString(),
                          x['participants'][1]['team']['team_name_short']
                              .toString(), widget.event),
                      widget.event.type,
                      widget.event.gameName,
                    ),
                    Alliance(
                      widget.event.teams
                          .findAdd(
                          x['participants'][2]['team']['team_number']
                              .toString(),
                          x['participants'][2]['team']['team_name_short']
                              .toString(), widget.event),
                      widget.event.teams
                          .findAdd(
                          x['participants'][3]['team']['team_number']
                              .toString(),
                          x['participants'][3]['team']['team_name_short']
                              .toString(), widget.event),
                      widget.event.type,
                      widget.event.gameName,
                    ),
                    widget.event.type,
                  ),
                );
              });
               setState((){});
               //   dataModel.saveEvents();
                }
   if(bod.length>0){
     widget.event.loadIn();
   }
              }

            ),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<OpModeType?>(
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
                            setState(() {
                              elementSort = null;
                              sortingModifier = newValue;
                            });
                            if (sortingModifier != null)
                              showModalBottomSheet(
                                context: context,
                                builder: (_) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    null,
                                    if (sortingModifier != null)
                                      ...Score("", Dice.none,
                                              widget.event.gameName)
                                          .getScoreDivision(sortingModifier)
                                          .getElements()
                                          .parse()
                                  ]
                                      .map(
                                        (e) => ListTile(
                                          title: Text(e?.name ?? "Total"),
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            setState(() => elementSort = e);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                              );
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
                                child: Text(value?.toVal() ?? "Total"),
                              );
                            },
                          ).toList(),
                        ),
                      ],
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
                          statConfig: widget.event.statConfig,
                          elementSort: elementSort,
                          teams: widget.event.statConfig.sorted
                              ? widget.event.teams.sortedTeams(
                                  sortingModifier,
                                  elementSort,
                                  widget.event.statConfig,
                                  widget.event.matches.values.toList(),
                                )
                              : widget.event.teams.orderedTeams(),
                          sortMode: sortingModifier,
                          event: widget.event,
                        )
                      : MatchSearch(
                          statConfig: widget.event.statConfig,
                          matches: widget.event.getSortedMatches(ascending),
                          event: widget.event,
                          ascending: ascending,
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
        floatingActionButton: widget.isPreview
            ? FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.primary,
                tooltip: 'Import Event',
                child: Icon(Icons.import_export),
                onPressed: () {
                  showPlatformDialog(
                    context: context,
                    builder: (_) => PlatformAlert(
                      title: Text('Import Event'),
                      content: Text(
                        'Are you sure?',
                      ),
                      actions: [
                        PlatformDialogAction(
                          child: Text('Cancel'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        PlatformDialogAction(
                          child: Text('Import'),
                          onPressed: () {
                            dataModel.events.add(widget.event);
                            LandingPage.tab = LandingPage.Tab.events;
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              )
            : widget.event.role != Role.viewer
                ? FloatingActionButton(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    tooltip: _tab == 0 ? 'Add Team' : 'Add Match',
                    child: Icon(Icons.add),
                    onPressed: () {
                      if (_tab == 0)
                        _teamConfig();
                      else
                        _matchConfig();
                    },
                  )
                : null,
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
              textInputAction: TextInputAction.next,
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
              textInputAction: TextInputAction.done,
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
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
