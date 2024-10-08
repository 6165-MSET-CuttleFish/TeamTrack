import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teamtrack/functions/Functions.dart';
import 'GameModel.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../providers/Theme.dart';
import '../functions/Extensions.dart';

class DataModel {
  List<Event> events = [];
  List<Event> sharedEvents = [];
  String? token;
  List<Event> inbox = [];
  List<TeamTrackUser> blockedUsers = [];

  List<Event> allEvents() => sharedEvents + events;

  List<Event> localEvents() =>
      allEvents().where((e) => e.type == EventType.local).toList();

  List<Event> remoteEvents() =>
      allEvents().where((e) => e.type == EventType.remote).toList();

  List<Event> driverAnalysis() =>
      allEvents().where((e) => e.type == EventType.analysis).toList();

  Future<void> saveEvents() async {
    final coded = events.map((e) => e.toJson()).toList();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("Events", jsonEncode(coded));

  }

  void restoreEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      events = (jsonDecode(prefs.getString('Events') ?? '') as List)
          .map((e) => Event.fromJson(e))
          .where((element) => !element.shared)
          .toList();
    } catch (e) {
      print(e);
    }
  }
}

enum Role {
  admin,
  editor,
  viewer,
}

class TeamTrackUser {
  TeamTrackUser({
    required this.role,
    this.displayName,
    this.email,
    this.photoURL,
    this.uid,
  });
  Role role;
  String? email;
  String? displayName;
  String? photoURL;
  String? watchingTeam;
  String? uid;
  TeamTrackUser.fromJson(Map<String, dynamic> json, this.uid)
      : role = getRoleFromString(json['role']),
        email = json['email'],
        displayName = json['displayName'],
        watchingTeam = json['watchingTeam'],
        photoURL = json['photoURL'];
  TeamTrackUser.fromUser(User? user)
      : role = Role.viewer,
        email = user?.email,
        displayName = user?.displayName,
        photoURL = user?.photoURL,
        uid = user?.uid;
  Map<String, String?> toJson([String? teamNumber]) => {
        'role': role.toRep(),
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'watchingTeam': teamNumber ?? watchingTeam,
      };
}

final dataModel = DataModel();
final DarkThemeProvider themeChangeProvider = new DarkThemeProvider();
final FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;
final FirebaseFunctions functions = FirebaseFunctions.instance;
final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
final FirebaseMessaging messaging = FirebaseMessaging.instance;
final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
