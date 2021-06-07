import 'package:teamtrack/Frontend/TeamView.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';

class TeamList extends StatefulWidget {
  TeamList({Key key, this.event, this.dataModel}) : super(key: key);
  final Event event;
  final DataModel dataModel;
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
  Widget build(BuildContext context) {
    return ListView(
      children: widget.event.teams.sortedTeams()
          .map((e) => Slidable(
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
                                      setState(() {
                                        widget.event.deleteTeam(e);
                                      });
                                      dataModel.saveEvents();
                                      dataModel.uploadEvent(widget.event);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ));
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
                                    )));
                        setState(() {});
                      },
                    )),
              ))
          .toList(),
    );
  }
}
