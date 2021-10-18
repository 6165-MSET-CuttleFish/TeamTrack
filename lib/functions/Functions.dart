import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teamtrack/models/AppModel.dart';

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