import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teamtrack/functions/Functions.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/logic/provider/Theme.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../functions/Extensions.dart';

class DataModel {
  List<Event> events = [];
  String? token;
  List<Event> localEvents() {
    return events.where((e) => e.type == EventType.local).toList();
  }

  List<Event> remoteEvents() {
    return events.where((e) => e.type == EventType.remote).toList();
  }

  List<Event> liveEvents() {
    return events.where((e) => e.type == EventType.live).toList();
  }

  void saveEvents() async {
    var coded = events.map((e) => e.toJson()).toList();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("Events", jsonEncode(coded));
    print(coded);
  }

  Future<void> restoreEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var x = jsonDecode(prefs.getString("Events") ?? '') as List;
      events = x.map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      print("failed");
    }
  }

  Future<HttpsCallableResult<dynamic>> shareEvent({
    required String name,
    required String email,
    required String authorEmail,
    required String id,
    required String type,
    required String authorName,
    required String gameName,
    required Role role,
  }) async {
    final HttpsCallable callable = functions.httpsCallable('shareEvent');
    return callable.call(
      {
        'email': email,
        'name': name,
        'id': id,
        'authorEmail': authorEmail,
        'type': type,
        'authorName': authorName,
        'gameName': gameName,
        'role': role.toRep(),
      },
    );
  }
}

enum Role {
  viewer,
  editor,
  admin,
}

class TeamTrackUser {
  TeamTrackUser(
      {required this.role, this.displayName, this.email, this.photoURL});
  Role role;
  String? email;
  String? displayName;
  String? photoURL;
  TeamTrackUser.fromJson(Map<String, dynamic> json)
      : role = getRoleFromString(json['role']),
        email = json['email'],
        displayName = json['displayName'],
        photoURL = json['photoURL'];
  Map<String, dynamic> toJson() => {
        'role': role.toRep(),
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
      };
}

DataModel dataModel = DataModel();
final DarkThemeProvider themeChangeProvider = new DarkThemeProvider();
final Database.FirebaseDatabase firebaseDatabase =
    Database.FirebaseDatabase.instance;
final FirebaseFunctions functions = FirebaseFunctions.instance;
final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
final RemoteConfig remoteConfig = RemoteConfig.instance;
final FirebaseMessaging messaging = FirebaseMessaging.instance;