import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:skeletons/skeletons.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:intl/intl.dart';
import 'package:teamtrack/functions/APIMethods.dart';

class TemplateView extends StatefulWidget {
  TemplateView({
    super.key,
    required this.event_key,
    required this.event_name,
    this.isPreview = false,
  });
  final String event_key;
  final String event_name;
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
    APIMethods.getTeams(widget.event_key).then((response) {
      setState(() {
        bod = (json.decode(response.body).toList());
        //print(bod);
      });
    });
  }

  _getInfo() {
    APIMethods.getInfo(widget.event_key).then((response) {
      setState(() {
        data = (json.decode(response.body).toList());
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
      title: Text(widget.event_name),
      titleTextStyle: TextStyle(fontSize: 20),
      backgroundColor: Theme.of(context).colorScheme.primary,
    ),
    body: data.isEmpty
        ? SkeletonItem(
        child: Column(
          children: [
            SizedBox(height: 20),
            SkeletonLine(
              style: SkeletonLineStyle(
                height:15,
                width: themeChangeProvider.darkTheme? MediaQuery.of(context).size.width:MediaQuery.of(context).size.width-10,
              ),
            ),
            SizedBox(height: 10),
            SkeletonLine(
              style: SkeletonLineStyle(
                height:15,
                width: themeChangeProvider.darkTheme? MediaQuery.of(context).size.width:MediaQuery.of(context).size.width-10,
              ),
            ),
            SizedBox(height: 10),
            SkeletonLine(
              style: SkeletonLineStyle(
                height:15,
                width: themeChangeProvider.darkTheme? MediaQuery.of(context).size.width:MediaQuery.of(context).size.width-10,
              ),
            ),
            SizedBox(height: 20),

            SkeletonAvatar(
              style: SkeletonAvatarStyle(
                  width: themeChangeProvider.darkTheme? MediaQuery.of(context).size.width:MediaQuery.of(context).size.width-10,
                  height:55
              ),

            ),
            SizedBox(height: 8),
            SkeletonAvatar(
              style: SkeletonAvatarStyle(
                  width: themeChangeProvider.darkTheme? MediaQuery.of(context).size.width:MediaQuery.of(context).size.width-10,
                  height:55
              ),

            ),
            SizedBox(height: 8),
            SkeletonAvatar(
              style: SkeletonAvatarStyle(
                  width: themeChangeProvider.darkTheme? MediaQuery.of(context).size.width:MediaQuery.of(context).size.width-10,
                  height:55
              ),

            ),
            SizedBox(height: 8),
            SkeletonAvatar(
              style: SkeletonAvatarStyle(
                  width: themeChangeProvider.darkTheme? MediaQuery.of(context).size.width:MediaQuery.of(context).size.width-10,
                  height:55
              ),

            ),
            SizedBox(height: 8),
            SkeletonAvatar(
              style: SkeletonAvatarStyle(
                  width: themeChangeProvider.darkTheme? MediaQuery.of(context).size.width:MediaQuery.of(context).size.width-10,
                  height:55
              ),

            ),
            SizedBox(height: 8),
            SkeletonAvatar(
              style: SkeletonAvatarStyle(
                  width: themeChangeProvider.darkTheme? MediaQuery.of(context).size.width:MediaQuery.of(context).size.width-10,
                  height:55
              ),

            ),
            SizedBox(height: 8),
            SkeletonAvatar(
              style: SkeletonAvatarStyle(
                  width: themeChangeProvider.darkTheme? MediaQuery.of(context).size.width:MediaQuery.of(context).size.width-10,
                  height:55
              ),

            ),
            SizedBox(height: 8),
            SkeletonAvatar(
              style: SkeletonAvatarStyle(
                  width: themeChangeProvider.darkTheme? MediaQuery.of(context).size.width:MediaQuery.of(context).size.width-10,
                  height:55
              ),

            ),
            SizedBox(height: 8),
            SkeletonAvatar(
              style: SkeletonAvatarStyle(
                  width: themeChangeProvider.darkTheme? MediaQuery.of(context).size.width:MediaQuery.of(context).size.width-10,
                  height:20
              ),

            ),
            SizedBox(height: 8),
            SkeletonAvatar(
              style: SkeletonAvatarStyle(
                  width: themeChangeProvider.darkTheme? MediaQuery.of(context).size.width:MediaQuery.of(context).size.width-10,
                  height:40
              ),
            )
          ],
        ))
        : Container(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top:20,left:10),
              child:
              Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(child: Icon(Icons.calendar_today_rounded
                      ,
                      size:15,)),
                    TextSpan(text: ' '+ DateFormat.yMMMMd('en_US').format(DateTime.parse(data[0]['start_date'].substring(0, 10))) +
                        ' - ' +
                        DateFormat.yMMMMd('en_US').format(DateTime.parse(data[0]['end_date'].substring(0, 10)))+'\n',
                        style:TextStyle(
                          fontSize: 15,
                          fontFamily: 'Roboto',

                        )

                    ),
                    WidgetSpan(
                        child: Divider(
                          color:Colors.transparent,
                          height: 10,
                        )
                    ),
                    WidgetSpan(child: Icon(Icons.location_on
                      ,
                      size:15,)),
                    TextSpan(text: ' '+data[0]['venue']+'\n',
                        style:TextStyle(
                          overflow: TextOverflow.ellipsis,
                          fontSize: 15,
                          fontFamily: 'Roboto',

                        )

                    ),
                    WidgetSpan(
                        child: Divider(
                          color:Colors.transparent,
                          height: 10,
                        )
                    ),
                    WidgetSpan(child: Icon(Icons.tour_rounded
                      ,
                      size:15,)),
                    TextSpan(text: ' '+data[0]['event_type_key']+'\n',
                        style:TextStyle(
                          overflow: TextOverflow.ellipsis,
                          fontSize: 15,
                          fontFamily: 'Roboto',

                        )

                    ),
                  ],

                ),
              ),
            ),
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
            Container(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: EdgeInsets.only(left:5,right:5,top:5,bottom:5),
                child:
                MaterialButton(
                  onPressed: () {
                    _newType = EventType.local;
                    _newName = widget.event_name;
                    dataModel.events.add(Event(
                      name: _newName ?? Statics.gameName,
                      type: _newType ?? EventType.remote,
                      gameName: Statics.gameName,
                      eventKey: widget.event_key,
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
                        borderRadius: BorderRadius.circular(25.0 ),
                      ),
                    ));
                  },
                  color:  Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.all(0),
                  height: 50,
                  child: Text('Create Event',
                    style: TextStyle(
                      //    color: Colors.black,
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      color:themeChangeProvider.darkTheme ? Colors.black:Colors.white,
                    ),),
                ),
              ),
            ),
          ].whereType<Widget>().toList()),
    ),
  );
}