import 'package:flutter/material.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/functions/Extensions.dart';

class ExampleTeamRow extends StatelessWidget {
  ExampleTeamRow(
      {super.key, this.sortMode, this.elementSort, required this.statistics});
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
    final elementName = elementSort?.name ?? "";
    final wlt = ['W', 'L', 'T'];
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
                'Team Name',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Row(
                children: [
                  for (int i = 0; i < wlt.length; i++)
                    Row(
                      children: [
                        Text(
                          wlt[i],
                          style: TextStyle(color: wltColor(i), fontSize: 14),
                        ),
                        if (i < wlt.length - 1) Text('-')
                      ],
                    ),
                ],
              )
            ],
          ),
        ),
        leading:
        Center(
          widthFactor: 1.1,
    child:Text(
          team.number,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
          textScaleFactor: .8,
        ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 0.15*MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('% Change'),
                ],
              ),
            ),
            Padding(

              padding: EdgeInsets.fromLTRB(0, 0, 15, 0),
            ),
            SizedBox(
              width: 0.15*MediaQuery.of(context).size.width,
             child: Text('% ${statistics.name}')
            ),
          ],
        ),
      ),
    );
  }
}
