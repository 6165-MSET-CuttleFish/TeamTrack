import 'package:flutter/material.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/functions/Extensions.dart';

class TeamRowAlliance extends StatelessWidget {
  TeamRowAlliance(
      {
        super.key,
        this.sortMode,
        this.elementSort,
        required this.statistics
      });
  final Team team = Team('Team #', 'Team Name');
  final OpModeType? sortMode;
  final ScoringElement? elementSort;
  final Statistics statistics;
  Color wltColor(int i) {
    if (i == 0) {
      return Colors.green;
    } else if (i == 1) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
      ),
      child: ListTile(
        tileColor: Colors.grey.withOpacity(0.3),
        title: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                team.name,

              ),

            ],
          ),
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
            ),
            Padding(
              padding: EdgeInsets.all(
                30,
              ),
            ),
            IconButton(
              icon: Icon(Icons.info),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Score Calculator'),
                      content: Text("Score is calculated from individual contribution of a team in all their matches."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            Text('Score')
          ],
        ),
      ),
    );
  }
}
