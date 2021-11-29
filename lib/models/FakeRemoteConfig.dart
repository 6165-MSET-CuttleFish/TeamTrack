import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';

class FakeRemoteConfig {
  Map<String, dynamic>? _config;
  RemoteConfig _remoteConfig = RemoteConfig.instance;
  Future<void> fetchAndActivate() => NewPlatform.isWeb
      ? firebaseDatabase.reference().child('config').once().then(
            (snapshot) => _config = snapshot.value as Map<String, dynamic>,
          )
      : _remoteConfig.fetchAndActivate();

  String getString(String key) => NewPlatform.isWeb
      ? json.decode(
          json.encode(
            _config?[key]['defaultValue']['value']?.replaceAll("/", ""),
          ),
        )
      : _remoteConfig.getString(key);
}
