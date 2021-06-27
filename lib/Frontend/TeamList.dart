import 'package:teamtrack/Frontend/TeamView.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:firebase_database/firebase_database.dart' as Database;
import 'dart:convert';

class TeamList extends StatefulWidget {
  TeamList({Key? key, required this.event}) : super(key: key);
  final Event event;
  @override
  State<StatefulWidget> createState() => _TeamList();
}

class _TeamList extends State<TeamList> {
  final slider = SlidableStrechActionPane();
  final secondaryActions = <Widget>[
    IconSlideAction(
      icon: Icons.delete,
      color: Colors.red,
      onTap: () {},
    )
  ];
  @override
  Widget build(BuildContext context) => StreamBuilder<Database.Event>(
        stream: DatabaseServices(id: widget.event.id).getEventChanges,
        builder: (context, eventHandler) {
          if (eventHandler.hasData &&
              !eventHandler.hasError &&
              !dataModel.isProcessing) {
            widget.event.updateLocal(
              json.decode(
                json.encode(eventHandler.data?.snapshot.value),
              ),
            );
          }
          return ListView(
            children: widget.event.teams
                .sortedTeams()
                .map(
                  (e) => Slidable(
                    actionPane: slider,
                    secondaryActions: [
                      IconSlideAction(
                        icon: Icons.delete,
                        color: Colors.red,
                        onTap: () {
                          showPlatformDialog(
                            context: context,
                            builder: (BuildContext context) => PlatformAlert(
                              title: Text('Delete Team'),
                              content: Text('Are you sure?'),
                              actions: [
                                PlatformDialogAction(
                                  isDefaultAction: true,
                                  child: Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                PlatformDialogAction(
                                  isDefaultAction: false,
                                  isDestructive: true,
                                  child: Text('Confirm'),
                                  onPressed: () {
                                    String? s;
                                    setState(
                                      () => s = widget.event.deleteTeam(e),
                                    );
                                    dataModel.saveEvents();
                                    //dataModel.uploadEvent(widget.event);
                                    Navigator.of(context).pop();
                                    if (s != null)
                                      showPlatformDialog(
                                        context: context,
                                        builder: (context) => PlatformAlert(
                                          title: Text('Error'),
                                          content: Text(
                                              'Team is currently being used in matches'),
                                          actions: [
                                            PlatformDialogAction(
                                              child: Text('Okay'),
                                              isDefaultAction: true,
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            )
                                          ],
                                        ),
                                      );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    ],
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        title: Text(e.name),
                        leading: Text(e.number,
                            style: Theme.of(context).textTheme.caption),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamView(
                                team: e,
                                event: widget.event,
                              ),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      );
}

class TeamSearch extends SearchDelegate<String?> {
  TeamSearch({required this.teams, required this.event});
  List<Team> teams;
  Event event;
  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isNotEmpty
        ? [
            ...teams.where(
              (q) => q.number.contains(query),
            ),
            ...teams.where(
              (q) => q.name.contains(query),
            ),
          ].toList()
        : teams;
    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey,
            width: 1,
          ),
        ),
        child: ListTile(
          leading: Text(suggestionList[index].number,
              style: Theme.of(context).textTheme.caption),
          title: Text(suggestionList[index].name),
          onTap: () {
            close(context, null);
            Navigator.push(
              context,
              platformPageRoute(
                (context) => TeamView(
                  event: event,
                  team: suggestionList[index],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
