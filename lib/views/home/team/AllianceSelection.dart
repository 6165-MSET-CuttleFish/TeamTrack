import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/api/APIKEYS.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/models/GPTModel.dart';
import 'package:http/http.dart' as http;
import '../../../functions/ResponseModel.dart';
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

  String returnResponse = "Initial response";
  String prompt = "No Data";
  late ResponseModel _responseModel;

  Future<void> _showPromptDialog(BuildContext context, String prompt) async {
    final GlobalKey<State> key = GlobalKey<State>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          key: key,
          title: Text('AI Recommendation'),
          content: FutureBuilder<void>(
            future: completionFunc(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('Loading...');
              } else if (snapshot.hasError) {
                return Text('Error fetching response');
              } else {
                return Text(returnResponse);
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
    // Close the dialog when the operation is complete
    Navigator.of(key.currentContext!, rootNavigator: true).pop();
  }


  completionFunc() async {
    if (returnResponse == 'Loading...') {
      setState(() => returnResponse = 'Loading...');
    }
    final response = await http.post(
      Uri.parse(APIKEYS.GPT_URL),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${APIKEYS.GPT_KEY}',
      },
      body: jsonEncode(
        {
          "model": "text-davinci-003",
          "prompt": prompt,
          "max_tokens": 150,
          "temperature": 0.7,
          "top_p": 0.7,
        },
      ),
    );

    setState(() {
      _responseModel = ResponseModel.fromJson(response.body);
      returnResponse = _responseModel.choices[0]['text'];
    });
  }


  void updateRecommended(int index) {
    setState(() {
      recommendedIndex = index;
    });
  }

  void _generatePromptForTeam(Team selectedTeam, List<dynamic> autonomousTeams, List<dynamic> teleOpTeams, List<dynamic> endgameTeams, List<Team> teams) {
    final indexAuto = autonomousTeams.indexOf(selectedTeam) + 1;
    final indexTele = teleOpTeams.indexOf(selectedTeam) + 1;
    final indexEndgame = endgameTeams.indexOf(selectedTeam) + 1;
    final index = teams.indexOf(selectedTeam) + 1;

    prompt = craftPrompt(
        teams.length, index, indexAuto, indexTele, indexEndgame, selectedTeam);
    print(returnResponse);

  }


  static String craftPrompt(int teamLength, int index, int indexAuto, int indexTele, int indexEndgame, Team displayTeam) {
    String prompt = "";
    String rankTone = "";
    String indexTone = "";
    String collaborative = "";

    if (indexAuto <= teamLength / 3) {
      rankTone += "{high ranking autonomous(Rank$indexAuto),";
    } else if (indexAuto <= teamLength * 2 / 3) {
      rankTone += "{neutral ranking autonomous(Rank$indexAuto),";
    } else {
      rankTone += "low ranking autonomous(Rank$indexAuto)}";
    }

    if (indexTele <= teamLength / 3) {
      rankTone += "{high ranking teleOp(Rank$indexTele),";
    } else if (indexTele <= teamLength * 2 / 3) {
      rankTone += "{neutral ranking teleOp(Rank$indexTele),";
    } else {
      rankTone += "low ranking teleOp(Rank$indexTele)}";
    }

    if (indexEndgame <= teamLength / 3) {
      rankTone += "{high ranking endgame(Rank$indexEndgame),";
    } else if (indexEndgame <= teamLength * 2 / 3) {
      rankTone += "{neutral ranking endgame(Rank$indexEndgame),";
    } else {
      rankTone += "low ranking endgame(Rank$indexEndgame)}";
    }

    if (index <= teamLength / 6) {
      indexTone = "highly recommended";
      collaborative = "great collaborative";
    } else if (index <= teamLength * 2 / 6) {
      indexTone = "recommended";
      collaborative = "good collaborative";
    } else if (index <= teamLength * 3 / 6) {
      indexTone = "moderately recommended";
      collaborative = "average collaborative";
    } else if (index <= teamLength * 4 / 6) {
      indexTone = "cautiously recommended";
      collaborative = "mediocre collaborative";
    } else if (index <= teamLength * 5 / 6) {
      indexTone = "not strongly recommended";
      collaborative = "low collaborative";
    } else {
      indexTone = "not recommended";
      collaborative = "low collaborative";
    }

    String GPTRecoTeam = "{${displayTeam.number} ${displayTeam.name}}";
    String startInstruct = "Provide a concise evaluation of $GPTRecoTeam for alliance selection. Considered $indexTone for alliance collaboration due to their performance in autonomous, teleOp, and endgame. Specifically,";
    String justifyRanks = "their rankings are $rankTone, reflecting a $collaborative approach.";

    prompt = startInstruct + justifyRanks;
    return prompt;
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
          value: 'Rank',
          child: Text('Rank'),
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

    Team displayTeam;
    teams[0].isRecommended = true;

    if (teams.length >= 2) {
      if (teams[0].number == widget.event.userTeam.number) {
        displayTeam = teams[1];
      } else {
        displayTeam = teams[0];
      }
    } else {
      displayTeam = teams[0];
      prompt = "Repeat: Please Add More Data";
    }

    final indexAuto = autonomousTeams.indexOf(displayTeam) + 1;
    final indexTele = teleOpTeams.indexOf(displayTeam) + 1;
    final indexEndgame = endgameTeams.indexOf(displayTeam) + 1;
    final index = teams.indexOf(displayTeam) + 1;

    if (teams.length >= 2) {
      prompt = craftPrompt(teams.length, index, indexAuto, indexTele, indexEndgame, displayTeam);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: 30),
            Text('Alliance Selection'),
            SizedBox(width: 10),
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
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TeamRowAlliance(
              sortMode: widget.sortMode,
              elementSort: widget.elementSort,
              statistics: widget.statistic,
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
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
                      _generatePromptForTeam(team, autonomousTeams, teleOpTeams, endgameTeams, teams);
                      _showPromptDialog(context, returnResponse);
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
