import 'dart:ffi';
import 'package:flutter/material.dart';
<<<<<<< Updated upstream
=======
import 'package:teamtrack/api/APIKEYS.dart';
import 'package:teamtrack/functions/Extensions.dart';
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
=======
  String returnResponse = "Initial response";
  String prompt = "No Data";
  late ResponseModel _responseModel;

  List<double> autoRanks = [];
  List<double> teleRanks = [];
  List<double> endgameRanks = [];
  List<String> autoNames = [];
  List<String> teleNames = [];
  List<String> endgameNames = [];




  Widget _buildTable(Team team, List<double> autoRanks, List<double> teleRanks, List<double> endgameRanks, List<String> autoNames, List<String> teleNames, List<String> endgameNames) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Center(
          child: Text(
            'AI Recommendation',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        width: double.infinity,
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${team.number} ${team.name}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16.0),
            ExpansionTile(
              title: Text('Autonomous'),
              children: [
                Container(
                  color: Colors.white,
                  child: _buildSubTable(0, autoRanks, autoNames),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            ExpansionTile(
              title: Text('Teleop'),
              children: [
                Container(
                  color: Colors.white,
                  child: _buildSubTable(1, teleRanks, teleNames),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            ExpansionTile(
              title: Text('Endgame'),
              children: [
                Container(
                  color: Colors.white,
                  child: _buildSubTable(2, endgameRanks, endgameNames),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSubTable(int index, List<double> ranks, List<String> nameRanks) {
    List<TableRow> tableRows = [];

    // Header
    tableRows.add(
      TableRow(
        children: [
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Percent VS Average',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );

    // Rows
    for (int i = 0; i < ranks.length; i++) {
      tableRows.add(
        TableRow(
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(nameRanks[i].toString()),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  (ranks[i] == -1)
                      ? "not enough data"
                      : '${(ranks[i] * 100).toString()}%', // Add percent sign
                  style: TextStyle(
                    color: (ranks[i] == -1)
                        ? Colors.black // Text color for "not enough data"
                        : (ranks[i] < 0.7)
                        ? Colors.red
                        : (ranks[i] >= 0.7 && ranks[i] <= 1.3)
                        ? Colors.black // Change orange to black
                        : Colors.green,
                  ),
                ),
              ),
            ),

          ],
        ),
      );
    }

    return Table(
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      border: TableBorder.all(),
      children: tableRows,
    );
  }





  Future<void> _showPromptDialog(BuildContext context, String prompt, Team team) async {
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
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _buildTable(
                      team,
                      getRanks(widget.event, team, OpModeType.auto),
                      getRanks(widget.event, team, OpModeType.tele),
                      getRanks(widget.event, team, OpModeType.endgame),
                      autoNames,
                      teleNames,
                      endgameNames,
                    ),
                  ),
                );
              },
              child: Text('In Depth Analysis'),
            ),
          ],
        );
      },
    );
    if (key.currentContext != null) {
      Navigator.of(key.currentContext!, rootNavigator: true).pop();
    }
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
      body: jsonEncode(<String, dynamic>{
        "model": "gpt-3.5-turbo",
        "messages": [

          {
            "role": "user",
            "content": prompt
          },
        ],
        "max_tokens": 150,
        "temperature": 0.7,
        "top_p": 0.7,
      }),
    );

    setState(() {
      _responseModel = ResponseModel.fromJson(response.body);
      returnResponse = _responseModel.choices[0]['message']['content'];
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception('Failed to load questions');
    }
  }


>>>>>>> Stashed changes
  void updateRecommended(int index) {
    setState(() {
      recommendedIndex = index;
    });
  }

<<<<<<< Updated upstream
=======
  void _generatePromptForTeam(Team selectedTeam, List<dynamic> autonomousTeams, List<dynamic> teleOpTeams, List<dynamic> endgameTeams, List<Team> teams) {
    final indexAuto = autonomousTeams.indexOf(selectedTeam) + 1;
    final indexTele = teleOpTeams.indexOf(selectedTeam) + 1;
    final indexEndgame = endgameTeams.indexOf(selectedTeam) + 1;
    final index = teams.indexOf(selectedTeam) + 1;

    prompt = craftPrompt(
        teams.length, index, indexAuto, indexTele, indexEndgame, selectedTeam);


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

>>>>>>> Stashed changes
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
          child: Text('Percent Better Than Average'),
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

    teams[0].isRecommended = true;

<<<<<<< Updated upstream
=======
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

>>>>>>> Stashed changes
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
                width: 0.55*MediaQuery.of(context).size.width,
              child: FittedBox (
                fit: BoxFit.scaleDown,
                child: Text('Alliance Selection')
              ),
            ),
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
          //SizedBox(height: 30),
          /*ElevatedButton(
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
              padding: const EdgeInsets.all(18.0),
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

           */

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
<<<<<<< Updated upstream
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
=======
                      _generatePromptForTeam(team, autonomousTeams, teleOpTeams, endgameTeams, teams);
                      _showPromptDialog(context, returnResponse, team, );
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
=======
  List<double> getRanks(Event event, Team team, OpModeType type) {
    List<int> total = [];
    List<int> user = [];
    List<double> percent = [];

    int plays = 0;
    int userPlays = 0;
    bool doOnce = false;
    for (final match in event.matches.values) {
      for (Team? checkTeam in match.getTeams())
        if (checkTeam == team) {
          userPlays++;
        } else {
          plays++;
        }
      for (var newTeam in match.getTeams()) {
        var score = newTeam?.scores[match.id];

        ScoreDivision? autoScores = score?.getScoreDivision(OpModeType.auto);
        ScoreDivision? teleScores = score?.getScoreDivision(OpModeType.tele);
        ScoreDivision? endgameScores = score?.getScoreDivision(OpModeType.endgame);

        if (!doOnce && autoScores != null && teleScores != null && endgameScores != null) {
          int? length = 0;
          if (type == OpModeType.auto) {
            length = autoScores.elements.values.toList().length;
            autoNames = List<String>.filled(length, "");
            for (int i = 0; i < length; i++) {
              autoNames[i] = autoScores.elements.values.toList()[i].name;
            }
          } else if (type == OpModeType.tele) {
            length = teleScores.elements.values.toList().length;
            teleNames = List<String>.filled(length, "");
            for (int i = 0; i < length; i++) {
              teleNames[i] = teleScores.elements.values.toList()[i].name;
            }
          } else {
            length = endgameScores.elements.values.toList().length;
            endgameNames = List<String>.filled(length, "");
            for (int i = 0; i < length; i++) {
              endgameNames[i] = endgameScores.elements.values.toList()[i].name;
            }
          }
          total = List<int>.filled(length, 0);
          user = List<int>.filled(length, 0);
          percent = List<double>.filled(length, 0.0);

          doOnce = true;
        }

        if (type == OpModeType.auto && autoScores != null) {
          List<ScoringElement> elementList = autoScores.elements.values
              .toList();
          if (newTeam == team) {
            for (int i = 0; i < elementList.length; i++) {
              ScoringElement element = elementList[i];
              user[i] = element.scoreValue();
            }
          } else {
            for (int i = 0; i < elementList.length; i++) {
              ScoringElement element = elementList[i];
              total[i] = element.scoreValue();
            }
          }

// Now 'user' list contains the scoreValue of each element in the corresponding index

        }
        else if (type == OpModeType.tele && teleScores != null) {
          List<ScoringElement> elementList = teleScores.elements.values
              .toList();
          if (newTeam == team) {
            for (int i = 0; i < elementList.length; i++) {
              ScoringElement element = elementList[i];
              user[i] = element.scoreValue();
            }
          } else {
            for (int i = 0; i < elementList.length; i++) {
              ScoringElement element = elementList[i];
              total[i] = element.scoreValue();
            }
          }
        }
        else if (type == OpModeType.endgame && endgameScores != null) {
          List<ScoringElement> elementList = endgameScores.elements.values
              .toList();
          if (newTeam == team) {
            for (int i = 0; i < elementList.length; i++) {
              ScoringElement element = elementList[i];
              user[i] = element.scoreValue();
            }
          } else {
            for (int i = 0; i < elementList.length; i++) {
              ScoringElement element = elementList[i];
              total[i] = element.scoreValue();
            }
          }

// Now 'user' list contains the scoreValue of each element in the corresponding index

        }
      }
    }
    for (int i = 0; i < user.length; i++) {
      user[i] = (user[i] / userPlays).round();
    }
    for (int i = 0; i < total.length; i++) {
      total[i] = (total[i] / plays).round();
    }
    for (int i = 0; i < percent.length; i++) {
      print (user[i]);
      print (total[i]);
      if (total[i] != 0) {
        percent[i] = (((user[i]/total[i]) * 10).roundToDouble()) / 10;
      } else {
        percent[i] = -1;
      }


    }

    return percent;
  }

>>>>>>> Stashed changes
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
