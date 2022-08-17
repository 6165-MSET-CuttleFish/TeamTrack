import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:skeletons/skeletons.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:intl/intl.dart';
import 'package:teamtrack/functions/APIMethods.dart';

class ClubView extends StatefulWidget {
  ClubView({
    Key? key,
    required this.target,
    this.isPreview = false,
  }) : super(key: key);
  final TeamTrackTeam target;
  final bool isPreview;
  @override
  _ClubView createState() => _ClubView();
}

class _ClubView extends State<ClubView> {
  EventType? _newType;
  String? _newName;
  initState() {
   setState(() {
print(widget.target.users[0].displayName);
   });
  }
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.target.teamName),
          titleTextStyle: TextStyle(fontSize: 20),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            IconButton(
              tooltip: 'Add Member',
              icon: Icon(Icons.person_add),
              onPressed: () {
              },
            )
          ],
        ),
    body: Container(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top:15,left:10),
                child:
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(child: Icon(Icons.credit_card
                            ,
                            size:15,)),
                            TextSpan(text: ' '+widget.target.teamNumber,
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
                            WidgetSpan(child: Icon(Icons.people
                              ,
                              size:15,)),
                            TextSpan(text: widget.target.users.length.toString(),
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
                          ],

                        ),
                      ),
                      ),
                  Expanded(
                    child:
                        ListView.builder(
                            itemCount: widget.target.users.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(color: Colors.white, width: 1),
                                  borderRadius: BorderRadius.circular(0),
                                ),
                                leading:
                                widget.target.users[index].photoURL!=null ?Padding(
                                  padding: EdgeInsets.only(bottom: 0)
                                  ,child:ClipRRect(
                                  borderRadius: BorderRadius.circular(300),
                                  child: Image.network(
                                    widget.target.users[index].photoURL!,
                                    height: 30,
                                  ),
                                ),
                                )
                            :
             Padding(
      padding: EdgeInsets.only(bottom:10),
  child:
  Icon(Icons.account_circle, size: 30)
  ),
                                title: Text(widget.target.users[index].displayName!),
                              );
                            }),
                  ),
  ])
  )
  );
}
