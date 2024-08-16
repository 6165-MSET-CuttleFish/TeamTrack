import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/events/EventShare.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/views/home/events/EventView.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:intl/intl.dart';
import '../../../components/misc/InfoPills.dart';
import '../team/TeamView.dart';

class EventsList extends StatefulWidget {
  EventsList({super.key, this.onTap});
  final void Function(Event)? onTap;
  @override
  State<EventsList> createState() => _EventsList();
}

class _EventsList extends State<EventsList> {
  var format = new DateFormat("MMMM dd, yyyy");
  String? _newName;
  double? _newNum;
  @override
  Widget build(BuildContext context) => SafeArea(
    child:Container(
      color: Theme.of(context).colorScheme.primary,
    padding: EdgeInsets.all(8),
    child:Container(

        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView(
          children: [
            Padding(
                padding: EdgeInsets.fromLTRB(30, 20, 30, 20),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Text(
                          'My Events',
                          style: Theme.of(context).textTheme.titleLarge),
                      Align(
                          alignment: Alignment.centerLeft,
                          child:MaterialButton(
                              shape:RoundedRectangleBorder(side: BorderSide.none,borderRadius: BorderRadius.all(Radius.circular(12))),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () { _chosen(EventType.local); },
                              child:Row(children:[
                                Icon(Icons.add,color:Colors.white),
                                Text("ADD",textAlign:TextAlign.right,style:Theme.of(context).textTheme.bodySmall?.apply(color:Colors.white),)
                              ]
                              )
                          )
                      )
                    ]
                )),
            Padding(
  padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
  child:SizedBox(
              height: MediaQuery.of(context).size.height*.4,
        child:

            ListView(
              children: localEvents(),
            ))),
            Padding(
                padding: EdgeInsets.fromLTRB(30, 20, 30, 20),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Text(
                          'Driver Practice',
                          style: Theme.of(context).textTheme.titleLarge),
                      Align(
                          alignment: Alignment.centerLeft,
                          child:MaterialButton(
                              shape:RoundedRectangleBorder(side: BorderSide.none,borderRadius: BorderRadius.all(Radius.circular(12))),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () { _chosen(EventType.analysis); },
                              child:Row(children:[
                                Icon(Icons.add,color:Colors.white),
                                Text( "ADD",textAlign:TextAlign.right,style:Theme.of(context).textTheme.bodySmall?.apply(color:Colors.white))
                              ]
                              )
                          )
                      )
                    ]
                )),
  Padding(
  padding: EdgeInsets.fromLTRB(20, 0, 20, 0),child:SizedBox(
                height: MediaQuery.of(context).size.height*.3,
                child:
                ListView(

                  children: driverAnalysis(),
                ))),
          ],
        ),
    )));

  List<Widget> localEvents() => dataModel.localEvents().map(eventTile).toList();

  List<Widget> remoteEvents() =>
      dataModel.remoteEvents().map(eventTile).toList();

  List<Widget> driverAnalysis() =>
      dataModel.driverAnalysis().map(eventTile).toList();

  Card eventTile(Event e) => Card(
color: Colors.white12,
      child:Slidable(
        startActionPane: ActionPane(
          // A motion is a widget used to control how the pane animates.
          motion: const StretchMotion(),

          // All actions are defined in the children parameter.
          children: [
            SlidableAction(
              onPressed: (_) => _onShare(e),
              icon: e.shared ? Icons.share : Icons.upload,
              backgroundColor: Colors.blue,
            ),
          ],
        ),
        endActionPane: ActionPane(
          // A motion is a widget used to control how the pane animates.
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: (_) {
                showPlatformDialog(
                  context: context,
                  builder: (BuildContext context) => PlatformAlert(
                    title: Text('Delete Event'),
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
                          if (e.shared)
                            onRemove(e);
                          else
                            setState(() => dataModel.events.remove(e));
                          dataModel.saveEvents();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
              icon: Icons.delete,
              backgroundColor: Colors.red,
            )
          ],
        ),
        child: ListTileTheme(
          iconColor: Theme.of(context).primaryColor,
          child: ListTile(

            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style:Theme.of(context).textTheme.bodyLarge?.apply(color:Colors.white),
                ),
                Row(
                  children:[
                    e.shared? InfoPills(text: "Shared", color: Colors.blueAccent):InfoPills(text: "Private", color: Colors.grey),
                    e.type == EventType.analysis? InfoPills(text:"Matches: "+e.matches.length.toString(),color:Colors.purple):Row()

            ]
                ),

              ],
            ),
            onTap: () async {
              if (widget.onTap != null) {
                final map = await e.getRef()?.once();
                e.updateLocal(
                  json.decode(
                    json.encode(
                      map?.snapshot.value,
                    ),
                  ),
                  context,
                );
                print(e.id);
                widget.onTap!(e);

              } else if(e.type!=EventType.analysis) {
                Navigator.push(
                  context,
                  platformPageRoute(
                    builder: (_) =>
                         EventView(
                          event: e,
                        ), settings: RouteSettings(name: "/activeEvent"),
                  ),
                );
              }
              else if(e.type==EventType.analysis) {
                String _newName =e.name;
                String _newNumber = 0.toString();
                if(e.getAllTeams().length==0) {
                  e.addTeam(
                    Team(_newNumber, _newName),
                  );
                }
                dataModel.saveEvents();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamView(
                      team: e.getAllTeams().first,
                      event: e,
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ));

  void _onShare(Event e) {
    if (!(context.read<User?>()?.isAnonymous ?? true)) {
      if (!e.shared) {
        showPlatformDialog(
          context: context,
          builder: (context) => PlatformAlert(
            title: Text('Upload Event'),
            content: Text(
              'Your event will still be private',
            ),
            actions: [
              PlatformDialogAction(
                child: Text('Cancel'),
                isDefaultAction: true,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              PlatformDialogAction(
                child: Text('Upload'),
                onPressed: () async {
                  showPlatformDialog(
                    context: context,
                    builder: (_) => PlatformAlert(
                      content: Center(child: PlatformProgressIndicator()),
                      actions: [
                        PlatformDialogAction(
                          child: Text('Back'),
                          isDefaultAction: true,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                  e.shared = true;
                  final json = e.toJson();
                  await firebaseDatabase
                      .ref()
                      .child("Events/${e.gameName}/${e.id}")
                      .set(json);
                  dataModel.events.remove(e);
                  setState(() => dataModel.saveEvents);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      } else {
        Navigator.of(context).push(
          platformPageRoute(
            builder: (context) => EventShare(
              event: e,
            ),
          ),
        );
      }
    } else {
      showPlatformDialog(
        context: context,
        builder: (context) => PlatformAlert(
          title: Text('Cannot Share Event'),
          content: Text('You must be logged in to share an event.'),
          actions: [
            PlatformDialogAction(
              child: Text('OK'),
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }
  void _chosen(EventType _newType) => showPlatformDialog(
    context: context,
    builder: (BuildContext context) => PlatformAlert(
      title: Text(
          'New ${_newType == EventType.remote ? 'Remote Event' :(_newType == EventType.local ? 'In Person Event': 'Driver Analysis')}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children:[
          PlatformTextField(
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            onChanged: (String input) {
              _newName = input;
            },
            placeholder: 'Enter name',
          ),
        ],
      ),
      actions: [
        PlatformDialogAction(
          isDefaultAction: true,
          child: Text('Cancel'),
          onPressed: () {
            _newName = '';
            _newNum = 0.0;
            Navigator.of(context).pop();
          },
        ),
        PlatformDialogAction(
          isDefaultAction: false,
          child: Text('Add'),
          onPressed: () {
            setState(
                  () {
                if (_newName!.isNotEmpty&&_newType!=EventType.analysis)
                  dataModel.events.add(Event(
                    name: _newName ?? Statics.gameName,
                    type: _newType ?? EventType.remote,
                    gameName: Statics.gameName,
                  ));
                if(_newName!.isNotEmpty&&_newType==EventType.analysis){
                  dataModel.events.add(Event(
                    name: _newName ?? Statics.gameName,
                    type: _newType ?? EventType.remote,
                    gameName: Statics.gameName,
                  ));
                }
                dataModel.saveEvents();
                _newName = '';
              },
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );

  void onRemove(Event e) async {
    final uid = context.read<User?>()?.uid;
    final map = await e.getRef()?.once();
    e.updateLocal(json.decode(json.encode(map?.snapshot.value)), context);
    if (e.users
            .firstWhere((element) => element.uid == context.read<User?>()?.uid)
            .role ==
        Role.admin)
      await e.getRef()?.remove();
    else
      await firebaseDatabase
          .ref()
          .child('Events/${e.gameName}/${e.id}/Permissions/$uid')
          .remove();
    dataModel.saveEvents();
  }
}
