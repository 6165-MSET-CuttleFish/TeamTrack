import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'dart:async';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/events/EventView.dart';
import 'package:teamtrack/views/home/events/EventsList.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../api/APIKEYS.dart';
import 'TemplateView.dart';
class TemplatesList extends StatefulWidget {
  TemplatesList({Key? key, this.onTap}) : super(key: key);
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
    APIKEYS.getEvents().then((response) {
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
          bod.where((element) => element['event_name'].toString().toLowerCase().indexOf(search.toLowerCase())!=-1)
              .toList();
    });
  }
  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey.shade900,
        title: Container(
          height: 38,
          child: TextField(
            onChanged: (value) => onSearch(value),
            decoration: InputDecoration(
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
            ),
          ),
        ),
      ), body: Container(
      child:ListView.builder(
        itemCount: bodvis.length,
        itemBuilder: (context, index) {
          return Card(
            child:ListTile(
                title: Text(bodvis[index]['event_name']),

                onTap: () {
                  Navigator.push(
                    context,
                    platformPageRoute(
                      builder: (_) => TemplateView(
                        event_key:bodvis[index]['event_key'],
                        event_name:bodvis[index]['event_name'],
                      ),
                    ),
                  );
                }
            ),);
        },

      ),

    ),
    );

  }
}