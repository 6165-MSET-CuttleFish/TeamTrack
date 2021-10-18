import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';

read(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return json.decode(prefs.getString(key)!);
}

save(String key, value) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString(key, json.encode(value));
}

Role getRoleFromString(String role) {
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

EventType getTypeFromString(String statusAsString) {
  for (EventType element in EventType.values)
    if (element.toString() == statusAsString) return element;
  return EventType.remote;
}

UserType? getUserTypeFromString(String userType) {
  switch (userType) {
    case 'editor':
      return UserType.admin;
    case 'temp':
      return UserType.editor;
    case 'viewer':
      return UserType.viewer;
  }
}