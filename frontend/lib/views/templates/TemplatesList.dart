import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/components/statistics/BarGraph.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/APIMethods.dart';
import 'TemplateView.dart';
import 'package:skeletons/skeletons.dart';
class TemplatesList extends StatefulWidget {
  TemplatesList({super.key, this.onTap});
  final void Function(Event)? onTap;
  @override
  _TemplatesList createState() => _TemplatesList();
}
class _TemplatesList extends State<TemplatesList> {
  final seasonKey = '2021';
  final url = 'https://theorangealliance.org/api';
  bool loaded = false;
  // ···
  List bod = [];
  List bodvis = [];
  _getEvents() {
    APIMethods.getEvents().then((response) {
      setState(() {
        bod = (json.decode(response.body)
            .toList());
        bodvis=bod;
      });
    });
  }
  initState() {
    super.initState();
    _getEvents();
  }
  onSearch(String search) {
    setState(() {
      bodvis =
          bod.where((element) => element['event_name'].toString().toLowerCase().indexOf(search.toLowerCase())!=-1).where((element) => element['venue'].toString()!='Virtual').where((element) => element['venue'].toString()!='Remote').where((element) => element['venue'].toString()!='Remote Event').where((element) => element['event_name'].toString().toLowerCase().indexOf('remote'.toLowerCase())==-1)
              .toList();
    });
  }
  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeChangeProvider.darkTheme ? Colors.black:Colors.white,
        elevation: 0,
        //   backgroundColor: Colors.grey.shade900,
        title: Container(
          height: 37,
          color: themeChangeProvider.darkTheme ? Colors.black:Colors.white,
          child: CupertinoSearchTextField(
            onChanged: (value) => onSearch(value),
            placeholder: 'Search for Your Event',
            backgroundColor: themeChangeProvider.darkTheme ? Color.fromARGB(255, 50, 50, 50):Color.fromARGB(255, 220, 220, 220),
            /* decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[850],
                contentPadding: EdgeInsets.all(0),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500,),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none
                ),
                hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500
                ),
                hintText: "Search events"
            ),*/
          ),
        ),
      ), body: Container(
      child:bod.isEmpty ? Center(child: SkeletonItem(
          child: Column(
            children: [
              SizedBox(height: 5),
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


            ],
          )),
      ):bodvis.isEmpty ? Center(child: Text('No Results Found')):
      ListView.builder(
        padding: EdgeInsets.all(0),
        itemCount: bodvis.length,
        itemBuilder: (context, index) {
          return Container(
              decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: Colors.grey,
                  width: 1,),

          ),
          ),
          child:ListTile(
            dense:true,
            minVerticalPadding: 0,
              title: Text(bodvis[index]['event_name']
                , overflow: TextOverflow.ellipsis,),
              tileColor: Colors.transparent,
              onTap: () {
              print(bodvis[index]);
                Navigator.push(
                  context,
                  platformPageRoute(
                    builder: (_) =>
                        TemplateView(
                          event_key: bodvis[index]['event_key'],
                          event_name: bodvis[index]['event_name'],
                        ),
                  ),
                );
              }
          ));
        }

      ),

    ),
    );

  }
}