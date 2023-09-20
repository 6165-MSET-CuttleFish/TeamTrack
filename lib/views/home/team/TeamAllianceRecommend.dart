import 'package:flutter/material.dart';
import 'package:teamtrack/models/GPTModel.dart';
import 'dart:math';

import '../../../functions/Statistics.dart';
import '../../../models/GameModel.dart';
import '../../../models/ScoreModel.dart';
import '../../../models/StatConfig.dart';

class TeamAllianceRecommend extends StatefulWidget {
  TeamAllianceRecommend({
    required this.team,
    required this.ranks,
    required this.event,
    required this.sortMode,
    required this.elementSort,
    required this.statConfig,
    required this.statistic,
  });

  final List<int> ranks;
  final Team team;
  final Event event;
  final OpModeType? sortMode;
  final ScoringElement? elementSort;
  final StatConfig statConfig;
  final Statistics statistic;

  @override
  _TeamAllianceRecommendState createState() => _TeamAllianceRecommendState();
}

class _TeamAllianceRecommendState extends State<TeamAllianceRecommend> {
  bool _gamesExpanded = true;

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> categories = [
      {
        'title': 'Autonomous Pathing',
        'subcategories': [
          {'title': 'Preferred Side', 'value': 'Left'},
          {'title': 'Opponent Interference', 'value': 'Low'}
        ]
      },
      {
        'title': 'TeleOp Strategy',
        'subcategories': [
          {'title': 'Scoring Method', 'value': 'High Goals'},
          {'title': 'Defense', 'value': 'Zone Defense'}
        ]
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name),
      ),
      body: SingleChildScrollView(
        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            ListTile(
              title: Text('Game Period',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              trailing: Text('Rank',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            ),
            SizedBox(height: 10),
            _buildScoreRow('Autonomous', widget.ranks[0]),
            _buildDivider(),
            _buildScoreRow('Teleop', widget.ranks[1]),
            _buildDivider(),
            _buildScoreRow('Endgame', widget.ranks[2]),
            _buildDivider(),
            SizedBox(height: 20),
           // _buildExpandableGames(categories),
            SizedBox(height: 20),
            _buildDivisionRank(),
            SizedBox(height: 20),

           // _buildExplanation(widget.team)

            //_buildExplanation(widget.team)

          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int rank) {

    double rankPercentage = (rank / widget.event.teams.length) * 100;

    Color color;
    if (rankPercentage <= 20 || rank == 1) {
      color = Colors.green;
    } else if (rankPercentage <= 50) {
      color = Colors.yellow.shade700;
    } else {
      color = Colors.red;
    }


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          Spacer(),
          Text('$rank',
              style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold)),
          SizedBox(width: 10)
        ],
      ),
    );
  }

  Widget _buildDivider() {

    return Divider(
      color: Colors.grey[300],
      height: 30,
      indent: 30,
      endIndent: 30,
    );
  }

  Widget _buildExpandableGames(List<Map<String, dynamic>> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text('Compatibility Metric',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            trailing: IconButton(
              icon: Icon(_gamesExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _gamesExpanded = !_gamesExpanded;
                });
              },
            ),
          ),
          if (_gamesExpanded) ..._buildCategoryRows(categories),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryRows(List<Map<String, dynamic>> categories) {
    List<Widget> rows = [];

    for (var category in categories) {
      rows.add(ListTile(
        title: Text(category['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            for (var subcategory in category['subcategories'])
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0), // Add spacing here
                child: Text('${subcategory['title']}: ${subcategory['value']}'),
              ),
          ],
        ),
      ));
    }

    return rows;
  }


  Widget _buildDivisionRank() {
    int rankNum = widget.ranks[3];
    double rankPercentage = (rankNum / widget.event.teams.length) * 100;

    Color rankColor;
    if (rankPercentage <= 20 || rankNum == 1) {
      rankColor = Colors.green;
    } else if (rankPercentage <= 50) {
      rankColor = Colors.yellow.shade700;
    } else {
      rankColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Division Rank:  ',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
          SizedBox(height: 8),
          Text('${rankNum} ',
              style: TextStyle(fontSize: 30, color: rankColor)),
        ],
      ),
    );
  }

  Widget _buildExplanation(Team currTeam) {
    int rankNum = widget.ranks[3];
    double rankPercentage = (rankNum / widget.event.teams.length) * 100;

    String allianceExplanation = "GPT";/*"${GPTModel(
        selectorTeam: widget.event.rankedTeams[0],
        event: widget.event,
        sortMode: widget.sortMode,
        elementSort: widget.elementSort,
        statConfig: widget.statConfig,
        statistic: widget.statistic).

    returnModelFeedback()}";
    */
    Color explanationColor;

    return Container(
      color: Colors.grey[300],
      height: 10000,
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.all(24),
      child: Text(
        allianceExplanation,
        style: TextStyle(fontSize: 20, color: Colors.black),
      ),
    );
  }
}

class GameData {
  final int gameNumber;
  final int percentile;
  final int generatedScore;

  GameData({required this.gameNumber, required this.percentile})
      : generatedScore = _generateScore(percentile);

  static int _generateScore(int percentile) {
    final random = Random();
    int minScore = percentile * 10;
    int maxScore = minScore + (100 - percentile * 10);

    int s = 5;
    return s;
  }
}
