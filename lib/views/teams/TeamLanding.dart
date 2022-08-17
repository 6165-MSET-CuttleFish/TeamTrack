import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/APIMethods.dart';
import 'package:skeletons/skeletons.dart';

import 'ClubView.dart';
class TeamLanding extends StatefulWidget {
  TeamLanding({Key? key, this.onTap}) : super(key: key);
  final void Function(Event)? onTap;
  @override
  _TeamLanding createState() => _TeamLanding();

}
class _TeamLanding extends State<TeamLanding> {
  var teamList = dataModel.allTeams;
  String? _newName;
  String ? _newNumber;
  refresh() {
    setState(() {});
  }
  Widget build(BuildContext context) {
    return Scaffold(

       body: Padding(
         padding: EdgeInsets.all(10),
         child:  Column(

        children: [
         Expanded(
         child:
         ListView.builder(
            itemCount: teamList.length,
            itemBuilder: (context, index) {
              return Card(
                child:ListTile(
                  leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text(
                        teamList[index].teamNumber,
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      ]
                  ),
                    title: Text(teamList[index].teamName),
                    trailing:Icon(Icons.navigate_next),
            onTap: () {
    Navigator.push(
    context,
    platformPageRoute(
    builder: (_) => ClubView(
 target: teamList[index]
    ),
    ),
    );
    }

                ),);
            },

          ),
         ),
        ],


      )
    ),
      floatingActionButton: FloatingActionButton(
      tooltip: "Create Team",
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Icon(Icons.add),
      onPressed: _teamPressed,
    ),
    );
  }
  void _teamPressed() => showPlatformDialog(
    context: context,
    builder: (BuildContext context) => PlatformAlert(
      title: Text(
          'New Team'),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlatformTextField(
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              onChanged: (String input) {
                _newName = input;
              },
              placeholder: 'Enter name',
            ),
            PlatformTextField(
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              onChanged: (String input) {
                _newNumber = input;
              },
              placeholder: 'Enter Team Number',
            ),
          ]),
      actions: [
        PlatformDialogAction(
          isDefaultAction: true,
          child: Text('Cancel'),
          onPressed: () {
            _newName = '';
            _newNumber = '';
            Navigator.of(context).pop();
          },
        ),
        PlatformDialogAction(
          isDefaultAction: false,
          child: Text('Add'),
          onPressed: () {
            setState(
                  () {
                if (_newName!.isNotEmpty&&_newNumber!.isNotEmpty)
                  dataModel.teams.add(TeamTrackTeam(
                    teamName: _newName ?? Statics.gameName,
                    teamNumber: _newNumber ?? '',
                  ));
                dataModel.teams[dataModel.teams.length-1].users.add(context.read<User?>()!);
                print(dataModel.teams.toString());
                _newName = '';
                _newNumber = '';
                refresh();
              },
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}