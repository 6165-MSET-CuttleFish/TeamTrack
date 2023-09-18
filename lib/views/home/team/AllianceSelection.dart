import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/models/GPTModel.dart';
import '../../../models/GameModel.dart';
import '../../../models/ScoreModel.dart';
import '../../../models/StatConfig.dart';
import 'AllianceSimulator.dart';
import 'TeamAllianceRecommend.dart';
import 'TeamRowAlliance.dart';

class AllianceSelection extends StatefulWidget {
  AllianceSelection({
    super.key,
    required this.event,
    required this.sortMode,
    required this.elementSort,
    required this.statConfig,
    required this.statistic,
  });
  final Event event;
  final OpModeType? sortMode;
  final ScoringElement? elementSort;
  final StatConfig statConfig;
  final Statistics statistic;

  @override
  State<AllianceSelection> createState() => _AllianceSelection();
}

class _AllianceSelection extends State<AllianceSelection> {
  int recommendedIndex = 0;
  String _sortBy = 'Score';

  void updateRecommended(int index) {
    setState(() {
      recommendedIndex = index;
    });
  }

  Future<void> _showSortOptions(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        button.localToGlobal(button.size.bottomRight(Offset.zero)).dx - 120,
        button.localToGlobal(Offset.zero).dy,
        button.localToGlobal(button.size.bottomRight(Offset.zero)).dx,
        button.localToGlobal(button.size.bottomRight(Offset.zero)).dy + 10,
      ),
      items: [
        PopupMenuItem(
          value: 'Score',
          child: Text('Score'),
        ),
        PopupMenuItem(
          value: 'Wins',
          child: Text('Wins'),
        ),
      ],
    ).then((selectedSort) {
      if (selectedSort != null) {
        setState(() {
          _sortBy = selectedSort;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final teams = widget.statConfig.sorted
        ? widget.event.teams.sortedTeams(
      widget.sortMode,
      widget.elementSort,
      widget.statConfig,
      widget.event.matches.values.toList(),
      widget.statistic,
    )
        : widget.event.teams.orderedTeams();

    final autonomousTeams = List.from(teams);
    final teleOpTeams = List.from(teams);
    final endgameTeams = List.from(teams);

    for (List<Team> teams in widget.event.alliances) {
      for (Team team in teams) {
        print (team.name);
      }
    }

    if (_sortBy == 'Wins') {
      teams.sort((a, b) {
        final aWLT = a.getWLT(widget.event)?.split('-').map(int.parse).toList() ?? [0, 0, 0];
        final bWLT = b.getWLT(widget.event)?.split('-').map(int.parse).toList() ?? [0, 0, 0];

        if (aWLT[0] != bWLT[0]) {
          return bWLT[0].compareTo(aWLT[0]);
        } else if (aWLT[1] != bWLT[1]) {
          return aWLT[1].compareTo(bWLT[1]);
        } else {
          final aScore = a.getAllianceScore(widget.event);
          final bScore = b.getAllianceScore(widget.event);
          if (aScore != bScore) {
            return bScore.compareTo(aScore);
          } else if (aScore != bScore) {
            return aScore.compareTo(bScore);
          } else {
            return teams.indexOf(a) - teams.indexOf(b);
          }
        }
      });
    } else {
      teams.sort((a, b) {
        final aScore = a.getAllianceScore(widget.event);
        final bScore = b.getAllianceScore(widget.event);

        if (aScore != bScore) {
          return bScore.compareTo(aScore);
        } else if (aScore != bScore) {
          return aScore.compareTo(bScore);
        } else {
          return teams.indexOf(a) - teams.indexOf(b);
        }
      });
    }

    autonomousTeams.sort((a, b) {
      final aScore = a.getSpecificScore(widget.event, OpModeType.auto);
      final bScore = b.getSpecificScore(widget.event, OpModeType.auto);

      if (aScore != bScore) {
        return bScore.compareTo(aScore);
      } else {
        return a.name.compareTo(b.name);
      }
    });

    teleOpTeams.sort((a, b) {
      final aScore = a.getSpecificScore(widget.event, OpModeType.tele);
      final bScore = b.getSpecificScore(widget.event, OpModeType.tele);

      if (aScore != bScore) {
        return bScore.compareTo(aScore);
      } else {
        return a.name.compareTo(b.name);
      }
    });

    endgameTeams.sort((a, b) {
      final aScore = a.getSpecificScore(widget.event, OpModeType.endgame);
      final bScore = b.getSpecificScore(widget.event, OpModeType.endgame);

      if (aScore != bScore) {
        return bScore.compareTo(aScore);
      } else if (aScore != bScore) {
        return aScore.compareTo(bScore);
      } else {
        return endgameTeams.indexOf(a) - endgameTeams.indexOf(b);
      }
    });

    teams[0].isRecommended = true;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: 30),
            Text('Alliance Selection'),
            SizedBox(width: 10)
          ],
        ),
        actions: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_sortBy',
                style: TextStyle(fontSize: 14.0),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () {
              _showSortOptions(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllianceSimulator(
                      event: widget.event,
                      sortMode: widget.sortMode,
                      elementSort: widget.elementSort,
                      statConfig: widget.statConfig,
                      statistic: widget.statistic
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Simulate Alliance Selection",
                    style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TeamRowAlliance(
              sortMode: widget.sortMode,
              elementSort: widget.elementSort,
              statistics: widget.statistic,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: teams.length,
              itemBuilder: (context, index) {
                Team team = teams[index];
                final partnerName = team.name;
                Color? isYellow = team.number == widget.event.userTeam.number
                    ? Colors.yellow.withOpacity(0.7)
                    : null;

                final wlt = team.getWLT(widget.event)?.split('-') ?? ['', '', ''];

                final teamTotalScore = team.getAllianceScore(widget.event);

                final indexAuto = autonomousTeams.indexOf(team);
                final indexTele = teleOpTeams.indexOf(team);
                final indexEndgame = endgameTeams.indexOf(team);

                List<int> parsedList = [indexAuto + 1, indexTele + 1, indexEndgame + 1, index + 1];

                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    color: isYellow,
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamAllianceRecommend(
                              team: team,
                              ranks: parsedList,
                              elementSort: widget.elementSort,
                              event: widget.event,
                              sortMode: widget.sortMode,
                              statConfig: widget.statConfig,
                              statistic: widget.statistic
                          ),
                        ),
                      );
                    },
                    child: ListTile(
                      title: Text(
                        partnerName,
                        style: TextStyle(fontSize: 18),
                      ),
                      subtitle: Row(
                        children: [
                          for (int i = 0; i < wlt.length; i++)
                            Row(
                              children: [
                                Text(
                                  wlt[i],
                                  style: TextStyle(color: wltColor(i)),
                                ),
                                if (i < wlt.length - 1) Text('-')
                              ],
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 50),
                          Text(
                            '$teamTotalScore',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}

Color wltColor(int i) {
  if (i == 0) {
    return Colors.green;
  } else if (i == 1) {
    return Colors.red;
  } else {
    return Colors.grey;
  }
}
