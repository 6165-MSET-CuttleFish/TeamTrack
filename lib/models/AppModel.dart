import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teamtrack/functions/Functions.dart';
import 'package:teamtrack/models/FakeRemoteConfig.dart';
import 'GameModel.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../providers/Theme.dart';
import '../functions/Extensions.dart';

class DataModel {
  List<Event> events = [];
  List<Event> sharedEvents = [];
  String? token;
  List<Event> inbox = [];
  List<TeamTrackUser> blockedUsers = [];

  List<Event> allEvents() => events + sharedEvents;

  List<Event> localEvents() =>
      allEvents().where((e) => e.type == EventType.local).toList();

  List<Event> remoteEvents() =>
      allEvents().where((e) => e.type == EventType.remote).toList();

  List<Event> liveEvents() =>
      allEvents().where((e) => e.type == EventType.live).toList();

  Future<void> saveEvents() async {
    final coded = events.map((e) => e.toJson()).toList();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("Events", jsonEncode(coded));
    print(coded);
  }

  Future<void> restoreEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var x = jsonDecode(prefs.getString("Events") ?? '') as List;
      events = x
          .map((e) => Event.fromJson(e))
          .where((element) => !element.shared)
          .toList();
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
    this.id,
  });
  Role role;
  String? email;
  String? displayName;
  String? photoURL;
  String? watchingTeam;
  String? id;
  TeamTrackUser.fromJson(Map<String, dynamic> json, this.id)
      : role = getRoleFromString(json['role']),
        email = json['email'],
        displayName = json['name'],
        watchingTeam = json['watchingTeam'],
        photoURL = json['photoURL'];
  TeamTrackUser.fromUser(User user)
      : role = Role.viewer,
        email = user.email,
        displayName = user.displayName,
        photoURL = user.photoURL,
        id = user.uid;
  Map<String, dynamic> toJson() => {
        'role': role.toRep(),
        'email': email,
        'name': displayName,
        'photoURL': photoURL,
        'watchingTeam': watchingTeam,
      };
}

DataModel dataModel = DataModel();
final DarkThemeProvider themeChangeProvider = new DarkThemeProvider();
final Database.FirebaseDatabase firebaseDatabase =
    Database.FirebaseDatabase.instance;
final FirebaseFunctions functions = FirebaseFunctions.instance;
final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
final FirebaseMessaging messaging = FirebaseMessaging.instance;
final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
final FakeRemoteConfig remoteConfig = FakeRemoteConfig();
