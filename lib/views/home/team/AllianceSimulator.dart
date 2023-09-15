import 'dart:ffi';
import 'package:flutter/material.dart';
import '../../../functions/Statistics.dart';
import '../../../models/GPTModel.dart';
import '../../../models/GameModel.dart';
import '../../../models/ScoreModel.dart';
import '../../../models/StatConfig.dart';

class AllianceContainer extends StatefulWidget {
  final List<Team> alliance;
  final int allianceNumber;

  AllianceContainer(this.alliance, this.allianceNumber);

  @override
  _AllianceContainerState createState() => _AllianceContainerState();
}

class _AllianceContainerState extends State<AllianceContainer> {
  bool isExpanded = false;

  void toggleExpansion() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleExpansion,
      child: Container(
        width: 300,
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.deepPurple, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 2,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isExpanded)
                Text(
                  '${widget.alliance[0].number} ${widget.alliance[0].name}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.deepPurple),
                  textAlign: TextAlign.center,
                ),
              if (!isExpanded)
                SizedBox(height: 6),
              if (!isExpanded)
                Text(
                  '${widget.alliance[1].number} ${widget.alliance[1].name}',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              if (!isExpanded)
                SizedBox(height: 10),
              if (!isExpanded)
                Text(
                  '${widget.alliance[2].number} ${widget.alliance[2].name}',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              if (isExpanded)
                Text(
                  'Alliance ${widget.allianceNumber}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.deepPurple),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AllianceSimulator extends StatefulWidget {
  AllianceSimulator({
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
  State<AllianceSimulator> createState() => _AllianceSimulatorState();
}

class _AllianceSimulatorState extends State<AllianceSimulator> {
  List<int> allianceTurns = [1, 2, 3, 4];
  int currentTurn = 1;
  int currentPartner = 1;

  Team localTeam = new Team("", "");
  bool showLocal = true;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final teams = widget.statConfig.sorted
        ? widget.event.teams.sortedTeams(
      widget.sortMode,
      widget.elementSort,
      widget.statConfig,
      widget.event.matches.values.toList(),
      widget.statistic,
    )
        : widget.event.teams.orderedTeams();

    teams.sort((team1, team2) {
      int wins1 = int.parse(team1.getWLT(widget.event)!.substring(0, 1));
      int wins2 = int.parse(team2.getWLT(widget.event)!.substring(0, 1));
      int auton1 = team1.getSpecificScore(widget.event, OpModeType.auto);
      int auton2 = team2.getSpecificScore(widget.event, OpModeType.auto);
      int tele1 = team1.getSpecificScore(widget.event, OpModeType.tele);
      int tele2 = team2.getSpecificScore(widget.event, OpModeType.tele);
      int endgame1 = team1.getSpecificScore(widget.event, OpModeType.endgame);
      int endgame2 = team2.getSpecificScore(widget.event, OpModeType.endgame);

      if (wins1 != wins2) {
        return wins2.compareTo(wins1);
      } else if (auton1 != auton2) {
        return auton2.compareTo(auton1);
      } else if (endgame1 != endgame2) {
        return endgame2.compareTo(endgame1);
      } else {
        return tele2.compareTo(tele1);
      }
    });

    setState(() {
      widget.event.rankedTeams = List.from(teams);
    });
    if (widget.event.alliances[0][0].name == "") {
      widget.event.addAllianceTeam(widget.event.rankedTeams[0], 0, 0);
    }

  }

  void _searchForTeam(String query) {
    for (var team in widget.event.rankedTeams) {
      if (team.number == query) {
        setState(() {
          showLocal = true;
          localTeam = team;
        });
        break;
      } else {
        setState(() {
          showLocal = false;
        });
      }
    }
  }

  void _addToAlliance() {
    showLocal = false;
    if (widget.event.rankedTeams.contains(localTeam) && localTeam != widget.event.rankedTeams[0]) {
      if (currentPartner == 1) {
        widget.event.rankedTeams.remove(widget.event.rankedTeams[0]);
      }

      setState(() {
        widget.event.addAllianceTeam(localTeam, currentTurn - 1, currentPartner);
        widget.event.rankedTeams.remove(localTeam);
      });
      if (currentPartner == 1) {
        widget.event.addAllianceTeam(widget.event.rankedTeams[0], currentTurn, 0);
      }
      if (currentTurn == 4) {
        currentPartner++;
        currentTurn = 1;
      } else {
        currentTurn++;
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("The selected team is already in an alliance."),
            actions: <Widget>[
              TextButton(
                child: Text("Close"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(height: 10),
            Text('Alliance Simulator', style: TextStyle(fontSize: 20)),
            SizedBox(width: 50),
          ],
        ),
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentPartner == 2
                          ? (showLocal
                          ? '${widget.event.alliances[currentTurn - 1][0].name} selects: ${localTeam.name}'
                          : '${widget.event.alliances[currentTurn - 1][0].name} selects:')
                          : (showLocal
                          ? '${widget.event.rankedTeams[0].name} selects: ${localTeam.name}'
                          : '${widget.event.rankedTeams[0].name} selects:'),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  width: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: _searchForTeam,
                          decoration: InputDecoration(
                            labelText: 'Alliance Team Number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: _addToAlliance,
                      ),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(height: 30),
            Column(
              children: [
                for (var i = 0; i < 4; i++)
                  AllianceContainer(widget.event.alliances[i], i + 1),
                SizedBox(height: 50),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Text(
                    "${GPTModel(team: widget.event.rankedTeams[0]).returnModelFeedback()}",
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),

          ],
        ),


      ),
    );
  }
}
