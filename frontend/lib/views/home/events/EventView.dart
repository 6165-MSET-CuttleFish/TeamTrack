import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/views/home/match/MatchConfig.dart';
import 'package:teamtrack/views/home/match/MatchList.dart';
import 'package:teamtrack/components/statistics/CheckList.dart';
import 'package:teamtrack/views/home/team/TeamList.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/views/home/events/EventShare.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/functions/APIMethods.dart';

import '../../../providers/Theme.dart';
import '../team/AllianceSelection.dart';
import 'ImageView.dart';

class EventView extends StatefulWidget {
  EventView({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  State<EventView> createState() => _EventView();
}

class _EventView extends State<EventView> {
  OpModeType? sortingModifier;
  ScoringElement? elementSort;
  Statistics statistics = Statistics.MEDIAN;
  bool ascending = false;

  List<Widget> materialTabs() =>
      [

        Scaffold(
          body: TeamList(
            event: widget.event,
            sortMode: sortingModifier,
            statConfig: widget.event.statConfig,
            elementSort: elementSort,
            statistic: statistics,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: FloatingActionButton(
            child:
            Text(
              'Alliance Selection',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleSmall
                  ?.apply(color: Colors.white),
              textAlign: TextAlign.center,
              textScaleFactor: .7,
            ),

            onPressed: () {
              if (widget.event.userTeam.number != "0") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AllianceSelection(
                          event: widget.event,
                          sortMode: sortingModifier,
                          statConfig: widget.event.statConfig,
                          elementSort: elementSort,
                          statistic: statistics,
                        ),
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return AlertDialog(
                          title: Text('Enter Team Number'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                onChanged: (value) {
                                  widget.event.updateUserTeam(
                                      new Team(value, value));
                                  setState(() {});
                                },
                              ),
                              ...widget.event.teams.entries.where(
                                    (entry) =>
                                entry.value.number ==
                                    widget.event.userTeam.number,
                              ).map(
                                    (entry) =>
                                    ListTile(
                                      title: Text(entry.value.name),
                                      onTap: () {
                                        widget.event.updateUserTeam(
                                            entry.value);
                                      },
                                    ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              child: Text('Submit'),
                              onPressed: () {
                                if (widget.event.teams.containsKey(
                                    widget.event.userTeam.number)) {
                                  if (widget.event.userTeam.number != "0") {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AllianceSelection(
                                              event: widget.event,
                                              sortMode: sortingModifier,
                                              statConfig: widget.event
                                                  .statConfig,
                                              elementSort: elementSort,
                                              statistic: statistics,
                                            ),
                                      ),
                                    );
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Team Does Not Exist'),
                                          content: Text(
                                              'The provided team number does not exist.'),
                                          actions: <Widget>[
                                            TextButton(
                                              child: Text('OK'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                }
                                setState(() {
                                  _newName = '';
                                });
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              }
            },
          ),
        ),
        MatchList(
          event: widget.event,
          ascending: ascending,
        ),
      ];
  int _tab = 0;
  List bod = [];

  _getMatches() async {
    if (widget.event.hasKey()) {
      final response = await APIMethods.getMatches(widget.event.getKey() ?? '');
      setState(() {
        print(response.body);
        bod = (json.decode(response.body).toList());
         print(bod.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        appBar: AppBar(
          title: (_tab == 0 ? Text('') : FittedBox(
              fit: BoxFit.scaleDown,child:Text('Matches'))),
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .primary,
          actions: [
            if (_tab == 0)
              Container(
                  padding: const EdgeInsets.all(0.0),
                  width: 30.0,
                  child: IconButton(
                    icon: Icon(Icons.settings),
                    tooltip: 'Configure',
                    onPressed: () =>
                        showModalBottomSheet(
                          context: context,
                          builder: (_) =>
                              CheckList(
                                state: this,
                                event: widget.event,
                                statConfig: widget.event.statConfig,
                              ),
                        ),
                  )),


            IconButton(
              icon: Icon(widget.event.shared ? Icons.share : Icons.upload),
              tooltip: 'Share',
              onPressed: () => _onShare(widget.event),
            ),
            if (_tab != 0 && widget.event.hasKey())
              IconButton(
                  icon: Icon(Icons.photo_camera),
                  tooltip: 'Import Match Schedule',
                  onPressed: () async {
                    Navigator.of(context).push(
                      platformPageRoute(
                        builder: (context) =>
                            ImageView(
                              event: widget.event,
                            ),
                      ),
                    ).then((_) {
                      setState(() {

                      });
                    });
                  }),
  if (_tab != 0 && widget.event.hasKey())
              IconButton(
                  icon: Icon(Icons.refresh),
                  tooltip: 'Fetch API Scores',
                  onPressed: () async {
                    //print(widget.event.getKey());
                    await _getMatches();
                    int p = 1;
                    //print(bod.toString());
                    List<Match> bruh = widget.event.getSortedMatches(ascending);
                    for (var x in bod) {
                      if (widget.event.matches.length < p) {
                        setState(() {
                          if (widget.event.matches.length > p - 1) {
                            bruh[widget.event.matches.length - p].setAPIScore(x['red_score'], x['blue_score']);
                          }
                          p++;
                        });
                      }
                    }

                    setState(() {});
                    dataModel.saveEvents();
                  }
              ),
            if (_tab == 0)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<Statistics>(
                      value: statistics,
                      icon: Icon(Icons.functions,
                          color: Colors.white),
                      iconSize: 24,
                      elevation: 16,
                      dropdownColor: Theme.of(context).colorScheme.primary,
                      underline: Container(
                        height: 0.5,
                        color: Colors.deepPurple,
                      ),
                      onChanged: (newValue) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          statistics = newValue ?? Statistics.MEDIAN;
                        });
                      },
                      items: Statistics.values
                          .map(
                            (value) =>
                            DropdownMenuItem<Statistics>(
                              value: value,
                              child: Text(value.name,
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.apply(color: Colors.white),
                                textScaleFactor: .9,),
                            ),
                      )
                          .toList(),
                    ),
                  ],
                ),
              ),
            _tab != 0
                ? IconButton(
              tooltip: "Sort",
              icon: Icon(
                  ascending
                      ? CupertinoIcons.sort_up
                      : CupertinoIcons.sort_down
                  ,
                  color: Colors.white
              ),
              onPressed: () {
                setState(() {
                  ascending = !ascending;
                });
              },
            )
                :  Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<OpModeType?>(
                    value: sortingModifier,
                    icon: Icon(Icons.sort,
                        color: Colors.white),
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
                          isScrollControlled: true,
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
                                title: Text(e?.name ?? "Total",
                                  style: Theme.of(context).textTheme.titleMedium?.apply(color: Colors.white),
                                  textScaleFactor: .9,),
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
                    dropdownColor: Theme.of(context).colorScheme.primary,
                    items: opModeExt
                        .getAll()
                        .map(
                          (value) => DropdownMenuItem<OpModeType?>(
                        value: value,
                        child: Text(value?.toVal() ?? "Total",
                          style: Theme.of(context).textTheme.titleMedium?.apply(color: Colors.white),
                          textScaleFactor: .9,),
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),

            IconButton(
              icon: Icon(
                Icons.search,
              ),
              onPressed: () {
                print(widget.event.id);
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
                      statistics,
                    )
                        : widget.event.teams.orderedTeams(),
                    sortMode: sortingModifier,
                    event: widget.event,
                    statistics: statistics, isUserTeam: false,
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
        bottomNavigationBar: (widget.event.type != EventType.remote &&
            widget.event.type != EventType.analysis)
            ? CurvedNavigationBar(
          animationCurve: Curves.easeOutQuint,
          animationDuration: const Duration(milliseconds: 1000),
          buttonBackgroundColor: Theme.of(context).colorScheme.secondary,
          color: Theme.of(context).textTheme.bodyLarge?.color ??
              Colors.black,
          index: _tab,
          backgroundColor: Colors.transparent,
          onTap: (index) => setState(() => _tab = index),
          items: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.person_3_fill,
                  size: 18,
                  color: _tab == 1 ? Theme.of(context).canvasColor : null,
                ),
                Text(
                  'Teams',
                  style: TextStyle(
                    fontSize: 8,
                    color:
                    _tab == 1 ? Theme.of(context).canvasColor : null,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.sportscourt_fill,
                  size: 18,
                  color: _tab == 0 ? Theme.of(context).canvasColor : null,
                ),
                Text(
                  'Matches',
                  style: TextStyle(
                    fontSize: 8,
                    color:
                    _tab == 0 ? Theme.of(context).canvasColor : null,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          ],
        )
            : null,


        body: materialTabs()[_tab],
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: widget.event.role != Role.viewer
            ? FloatingActionButton(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .primary,
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
      builder: (BuildContext context) =>
          PlatformAlert(
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
                  placeholder: 'Team Name',
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (input) =>
                  _newName =
                  widget.event != EventType.analysis
                      ? input
                      : widget.event.name,
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
                      _newNumber =
                          _newNumber.split('').reduce((value, element) =>
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

  void _onShare(Event e) {
    if (!(context
        .read<User?>()
        ?.isAnonymous ?? true)) {
      if (!e.shared) {
        showPlatformDialog(
          context: context,
          builder: (context) =>
              PlatformAlert(
                title: Text('Upload Event'),
                content: Text(
                  'Your event will still be private',
                ),
                actions: [
                  PlatformDialogAction(
                    child: Text('Cancel'),
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  PlatformDialogAction(
                    child: Text('Upload'),
                    onPressed: () async {
                      showPlatformDialog(
                        context: context,
                        builder: (_) =>
                            PlatformAlert(
                              content: Center(
                                  child: PlatformProgressIndicator()),
                              actions: [
                                PlatformDialogAction(
                                  child: Text('Back'),
                                  isDefaultAction: true,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                      );
                      e.shared = true;
                      final json = e.toJson();
                      await firebaseDatabase
                          .ref()
                          .child("Events/${e.gameName}/${e.id}")
                          .set(json);
                      dataModel.events.remove(e);
                      setState(() => dataModel.saveEvents);
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
        );
      } else {
        Navigator.of(context).push(
          platformPageRoute(
            builder: (context) =>
                EventShare(
                  event: e,
                ),
          ),
        );
      }
    } else {
      showPlatformDialog(
        context: context,
        builder: (context) =>
            PlatformAlert(
              title: Text('Cannot Share Event'),
              content: Text('You must be logged in to share an event.'),
              actions: [
                PlatformDialogAction(
                  child: Text('OK'),
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
      );
    }
  }

  void _onAlliance(Event e) {
    if (!(context
        .read<User?>()
        ?.isAnonymous ?? true)) {
      if (!e.shared) {
        showPlatformDialog(
          context: context,
          builder: (context) =>
              PlatformAlert(
                title: Text('Upload Event'),
                content: Text(
                  'Your event will still be private',
                ),
                actions: [
                  PlatformDialogAction(
                    child: Text('Cancel'),
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  PlatformDialogAction(
                    child: Text('Upload'),
                    onPressed: () async {
                      showPlatformDialog(
                        context: context,
                        builder: (_) =>
                            PlatformAlert(
                              content: Center(
                                  child: PlatformProgressIndicator()),
                              actions: [
                                PlatformDialogAction(
                                  child: Text('Back'),
                                  isDefaultAction: true,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                      );
                      e.shared = true;
                      final json = e.toJson();
                      await firebaseDatabase
                          .ref()
                          .child("Events/${e.gameName}/${e.id}")
                          .set(json);
                      dataModel.events.remove(e);
                      setState(() => dataModel.saveEvents);
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
        );
      } else {
        Navigator.of(context).push(
          platformPageRoute(
            builder: (context) =>
                EventShare(
                  event: e,
                ),
          ),
        );
      }
    } else {
      showPlatformDialog(
        context: context,
        builder: (context) =>
            PlatformAlert(
              title: Text('Cannot Share Event'),
              content: Text('You must be logged in to share an event.'),
              actions: [
                PlatformDialogAction(
                  child: Text('OK'),
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
      );
    }
  }

}
