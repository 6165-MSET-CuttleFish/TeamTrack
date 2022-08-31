import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';

import '../../api/APIKEYS.dart';
import '../../functions/APIMethods.dart';


class TemplateView extends StatefulWidget {
  TemplateView({
    Key? key,
    required this.eventKey,
    required this.eventName,
    this.isPreview = false,
  }) : super(key: key);
  final String eventKey;
  final String eventName;
  final bool isPreview;

  @override
  _TemplateView createState() => _TemplateView();
}

class _TemplateView extends State<TemplateView> {
  List bod = [];
  List data = [];

  EventType? _newType;
  String? _newName;
  _getTeams() {
    APIMethods.getTeams(widget.eventKey).then((response) {
      setState(() {
        bod = (json.decode(response.body).toList());
        //print(bod);
      });
    });
  }

  _getInfo() {
    APIMethods.getInfo(widget.eventKey).then((response) {
      setState(() {
        data = (json.decode(response.body).toList());
        print(data);
      });
    });
  }

  initState() {
    _getTeams();
    _getInfo();
    super.initState();
  }

  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.eventName),
          titleTextStyle: TextStyle(fontSize: 20),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: data.isEmpty
            ? Center(child: PlatformProgressIndicator())
            : Container(
                child: Column(
                    children: [
                  Text('Dates: ' +
                      data[0]['start_date'].substring(0, 10) +
                      ' - ' +
                      data[0]['end_date'].substring(0, 10)),
                  Text('Location: ' + data[0]['city']),
                  Text('Type: ' + data[0]['event_type_key']),
                  data[0]['division_name']
                      ?.let((that) => Text('Division: ' + that.toString())),
                  Expanded(
                    child: bod.isEmpty
                        ? Center(child: Text('No Teams Loaded Yet'))
                        : ListView.builder(
                            itemCount: bod.length,
                            itemBuilder: (context, index) {
                              return Card(
                                child: ListTile(
                                  title: Text(bod[index]['team']
                                          ['team_name_short']
                                      .toString()),
                                  subtitle: Text(
                                      bod[index]['team_number'].toString()),
                                ),
                              );
                            }),
                  ),
                  OutlinedButton(
                      onPressed: () {
                        _newType = EventType.local;
                        _newName = widget.eventName;
                        dataModel.events.add(Event(
                          name: _newName ?? Statics.gameName,
                          type: _newType ?? EventType.remote,
                          gameName: Statics.gameName,
                          eventKey: widget.eventKey,
                        ));
                        for (var x in bod) {
                          String _newName =
                              x['team']['team_name_short'].toString();
                          String _newNumber = x['team_number'].toString();
                          dataModel.events[dataModel.events.length - 1].addTeam(
                            Team(_newNumber, _newName),
                          );
                        }
                        dataModel.saveEvents();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(milliseconds: 1000),
                          content: Text('Event Created'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ));
                      },
                      child: Text('Create Event')),
                ].whereType<Widget>().toList()),
              ),
      );
}
