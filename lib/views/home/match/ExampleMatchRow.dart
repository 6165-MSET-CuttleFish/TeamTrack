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
        leading: SizedBox(
            width: 35,
            child:Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children:[
                  Text('#',style: Theme.of(context).textTheme.titleLarge, textScaleFactor: .8,)
                ]
            )
        ),
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
        trailing: team != null ? null : Padding(
          padding: EdgeInsets.only(right:10),
            child:scoreDisplay()),
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
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color:
                    team == null ? (CupertinoColors.systemRed) : (Colors.grey),
              ),
            ),
            Text(" - ", style: GoogleFonts.montserrat()),
            Text(
              'Blue',
              style: GoogleFonts.montserrat(
                fontWeight: null,
                fontSize: 15,
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
            style: GoogleFonts.montserrat(
              fontSize: 10.5,
              color: Colors.green,
            ),
          ),
      ],
    );
  }
}
