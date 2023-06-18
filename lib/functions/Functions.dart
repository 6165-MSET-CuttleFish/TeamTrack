import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/match/MatchView.dart';
import 'package:provider/provider.dart';

read(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return json.decode(prefs.getString(key)!);
}

save(String key, value) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString(key, json.encode(value));
}

Role getRoleFromString(String? role) {
  switch (role) {
    case "viewer":
      return Role.viewer;
    case "editor":
      return Role.editor;
    case "admin":
      return Role.admin;
    default:
      return Role.viewer;
  }
}

Dice getDiceFromString(String statusAsString) {
  for (Dice element in Dice.values) {
    if (element.toString() == statusAsString) {
      return element;
    }
  }
  return Dice.none;
}

EventType getTypeFromString(String? statusAsString) {
  for (EventType element in EventType.values)
    if (element.toString() == statusAsString) return element;
  return EventType.local;
}

Timestamp? getTimestampFromString(Map<String, dynamic>? map) {
  if (map?['seconds'] != null && map?['nanoseconds'] != null) {
    return Timestamp(map?['seconds'], map?['nanoseconds']);
  }
  return null;
}

void navigateToMatch(
  BuildContext context, {
  required Match match,
  required Event event,
  Team? team,
  State? state,
}) async {
  final user = context.read<User?>();
  final ttuser = event.getTTUserFromUser(user);
  event
      .getRef()
      ?.child('matches/${match.id}/activeUsers/${user?.uid}')
      .set(ttuser.toJson());
  await Navigator.push(
    context,
    platformPageRoute(
      builder: (context) => MatchView(
        match: match,
        event: event,
        team: team,
      ),
    ),
  );
  // ignore: invalid_use_of_protected_member
  state?.setState(() {});
}
