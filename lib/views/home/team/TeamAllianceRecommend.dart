import 'package:flutter/material.dart';
import 'dart:math';

class TeamAllianceRecommend extends StatefulWidget {
  final String teamName;
  final List<int> ranks;
  final int numTeams;

  TeamAllianceRecommend({
    required this.teamName,
    required this.ranks,
    required this.numTeams,

  });


  @override
  _TeamAllianceRecommendState createState() => _TeamAllianceRecommendState();
}

class _TeamAllianceRecommendState extends State<TeamAllianceRecommend> {
  bool _gamesExpanded = true;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teamName),

      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text('Game Period', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              trailing: Text('Rank', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            ),

            _buildScoreRow('Autonomous', widget.ranks[0]),
            _buildDivider(),
            _buildScoreRow('Teleop', widget.ranks[1]),
            _buildDivider(),
            _buildScoreRow('Endgame', widget.ranks[2]),
            _buildDivider(),
            SizedBox(height: 20),
            _buildExpandableGames(),
            SizedBox(height: 20),
            _buildDivisionRank(),
            SizedBox(height: 20),
            _buildExplanation()
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int rank) {
    print (rank);
    print (widget.numTeams);
    Color color;
    if ((rank / widget.numTeams) < (1 / 3)) {
      color = Colors.green;
    } else if (rank / widget.numTeams < (2 / 3)) {
      color = Colors.yellow.shade700;
    } else {
      color = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          Spacer(), // Add a Spacer widget to push the second Text widget to the left
          Text('$rank', style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold)),
          SizedBox(width: 10)
        ],
      ),
    );


  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[300],
      height: 0.5,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildExpandableGames() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text('Games Played Together', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            trailing: IconButton(
              icon: Icon(_gamesExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _gamesExpanded = !_gamesExpanded;
                });
              },
            ),
          ),
          if (_gamesExpanded) ..._buildGameRows([
            GameData(gameNumber: 1, percentile: 30),
            GameData(gameNumber: 2, percentile: 80),
            GameData(gameNumber: 3, percentile: 0),
          ]),
        ],
      ),
    );
  }

  List<Widget> _buildGameRows(List<GameData> games) {
    List<Widget> rows = [];
    for (var game in games) {
      rows.addAll([
        Divider(color: Colors.grey[300], height: 0.5, indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Game ${game.gameNumber}', style: TextStyle(fontSize: 18, color: Colors.black)),
                  Spacer(),
                  Text('${200}', style: TextStyle(fontSize: 18, color: Colors.black)),
                  SizedBox(width: 5)
                ],
              ),
              SizedBox(height: 4),
            ],
          ),
        ),
      ]);
    }
    return rows;
  }

  Widget _buildDivisionRank() {
    int rankNum = widget.ranks[3];
    double rankPercentage = (rankNum / 27) * 100;

    Color rankColor;
    if (rankPercentage <= 20) {
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
          Text('Division Rank:  ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
          SizedBox(height: 8),
          Text('${rankNum} ', style: TextStyle(fontSize: 30, color: rankColor)),
        ],
      ),
    );
  }

  Widget _buildExplanation() {
    int rankNum = widget.ranks[3];
    double rankPercentage = (rankNum / 27) * 100;

    String allianceExplanation;
    Color explanationColor;
    if (rankPercentage <= 20) {
      allianceExplanation = "High autonomous scores and the complementing styles of play between your two teams";
      explanationColor = Colors.black;
    } else if (rankPercentage >= 50) {
      allianceExplanation = "LA GPT OK";
      explanationColor = Colors.black;
    } else {
      allianceExplanation = "LA GPT TRASH";
      explanationColor = Colors.black;
    }
    return Container(
      color: Colors.grey[300],
      height: 10000,
      alignment: Alignment.topLeft, // Align the content to the top left
      padding: const EdgeInsets.all(24),
      child: Text(
        allianceExplanation,
        style: TextStyle(fontSize: 20, color: explanationColor),
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
