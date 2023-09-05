import 'package:flutter/material.dart';
import 'package:teamtrack/functions/Statistics.dart';
import '../../../models/GameModel.dart';
import '../../../models/ScoreModel.dart';
import '../../../models/StatConfig.dart';
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

     if (_sortBy == 'Wins') {
      // Sort the teams based on wins and losses
      teams.sort((a, b) {
        final aWLT = a.getWLT(widget.event)?.split('-').map(int.parse).toList() ?? [0, 0, 0];
        final bWLT = b.getWLT(widget.event)?.split('-').map(int.parse).toList() ?? [0, 0, 0];

        if (aWLT[0] != bWLT[0]) {
          return bWLT[0].compareTo(aWLT[0]); // Sort by wins
        } else if (aWLT[1] != bWLT[1]) {
          return aWLT[1].compareTo(bWLT[1]); // Sort by losses (lower is better)
        } else {
          final aScore = a.getTotalScore(widget.event);
          final bScore = b.getTotalScore(widget.event);
          if (aScore != bScore) {
            return bScore.compareTo(aScore); // Sort by wins
          } else if (aScore != bScore) {
            return aScore.compareTo(bScore); // Sort by losses (lower is better)
          } else {
            return teams.indexOf(a) - teams.indexOf(b); // Sort by team index
          }
        }
      });
     } else {
       teams.sort((a, b) {
         final aScore = a.getTotalScore(widget.event);
         final bScore = b.getTotalScore(widget.event);

         if (aScore != bScore) {
           return bScore.compareTo(aScore); // Sort by wins
         } else if (aScore != bScore) {
           return aScore.compareTo(bScore); // Sort by losses (lower is better)
         } else {
           return teams.indexOf(a) - teams.indexOf(b); // Sort by team index
         }
       });
     }


    autonomousTeams.sort((a, b) {
      final aScore = a.getSpecificScore(widget.event, OpModeType.auto);
      final bScore = b.getSpecificScore(widget.event, OpModeType.auto);

      if (aScore != bScore) {
        return bScore.compareTo(aScore); // Sort by autonomous scores (higher is better)
      } else {
        return a.name.compareTo(b.name); // Sort by team name (for stability)
      }
    });

    teleOpTeams.sort((a, b) {
      final aScore = a.getSpecificScore(widget.event, OpModeType.tele);
      final bScore = b.getSpecificScore(widget.event, OpModeType.tele);

      if (aScore != bScore) {
        return bScore.compareTo(aScore); // Sort by teleop scores (higher is better)
      } else {
        return a.name.compareTo(b.name); // Sort by team name (for stability)
      }
    });



    endgameTeams.sort((a, b) {
      final aScore = a.getSpecificScore(widget.event, OpModeType.endgame);
      final bScore = b.getSpecificScore(widget.event, OpModeType.endgame);

      if (aScore != bScore) {
        return bScore.compareTo(aScore); // Sort by wins
      } else if (aScore != bScore) {
        return aScore.compareTo(bScore); // Sort by losses (lower is better)
      } else {
        return endgameTeams.indexOf(a) - endgameTeams.indexOf(b); // Sort by team index
      }
    });

     teams[0].isRecommended = true;





    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(), // Empty SizedBox to push the title to the right
            Text('Alliance Selection'),
            SizedBox(), // Adjust the width as needed
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              recommendedIndex == -1
                  ? ''
                  : generateRecommendation(teams[recommendedIndex].name),
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ),
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

                final wlt = team.getWLT(widget.event)?.split('-') ??
                    ['', '', ''];

                final teamTotalScore = team.getTotalScore(widget.event);

                final indexAuto = autonomousTeams.indexOf(team);

                final indexTele = teleOpTeams.indexOf(team);

                final indexEndgame = endgameTeams.indexOf(team);



                List<int> parsedList = [indexAuto + 1, indexTele + 1, indexEndgame + 1, index + 1];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamAllianceRecommend(
                          teamName: partnerName,
                          ranks: parsedList,
                          numTeams: teams.length
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey,
                          width: 1.0,
                        ),
                      ),
                    ),
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
                          if (team.isRecommended != null) // Only show if isRecommended is not null
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/sample');
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 4.0,
                                  horizontal: 10.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  'Recommended',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                            ),
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

String generateRecommendation(String partnerName) {
  return "$partnerName is the recommended alliance partner because... idk";
}
