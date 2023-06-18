import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamtrack/models/GameModel.dart';

class ExampleMatchRow extends StatelessWidget {
  ExampleMatchRow({
    super.key,
    required this.event,
    this.team,
  });
  final Event event;
  final Team? team;

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
        title: team != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.type != EventType.remote && event.type != EventType.analysis)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Qual #'),
                          Container(
                            child: matchSummary(context),
                            width: 150,
                          ),
                          scoreDisplay(),
                        ],
                      ),
                    ),
                  Text(''),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  matchSummary(context),
                ],
              ),
        trailing: team != null ? null : scoreDisplay(),
        tileColor: Colors.grey.withOpacity(0.3),
      ),
    );
  }

  Widget matchSummary(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Red Alliance',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'VS',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            'Blue Alliance',
            style: Theme.of(context).textTheme.bodySmall,
          )
        ],
      );

  Widget scoreDisplay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Red',
              style: GoogleFonts.gugi(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color:
                    team == null ? (CupertinoColors.systemRed) : (Colors.grey),
              ),
            ),
            Text(" - ", style: GoogleFonts.gugi()),
            Text(
              'Blue',
              style: GoogleFonts.gugi(
                fontWeight: null,
                fontSize: 17,
                color: team == null
                    ? (Colors.blue)
                    : (CupertinoColors.activeOrange),
              ),
            ),
          ],
        ),
        if (event.eventKey != null)
          Text(
            'API Score',
            style: GoogleFonts.gugi(
              fontSize: 10.5,
              color: Colors.green,
            ),
          ),
      ],
    );
  }
}
