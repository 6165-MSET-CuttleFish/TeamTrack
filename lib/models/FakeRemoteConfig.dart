import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';

class FakeRemoteConfig {
  Map<String, dynamic>? _config;
  RemoteConfig _remoteConfig = RemoteConfig.instance;

  Future<void> fetchAndActivate() {
    if (NewPlatform.isWeb())
      return firebaseDatabase
          .reference()
          .child('config')
          .once()
          .then((snapshot) {
        _config = snapshot.value as Map<String, dynamic>;
      });
    else
      return _remoteConfig.fetchAndActivate();
  }

  String getString(String key) {
    if (NewPlatform.isWeb()) {
      final returnVal = _config?[key]['defaultValue']['value'];
      final x = json.decode(json.encode(returnVal?.replaceAll("/", "")));
      return x;
    } else {
      final x = _remoteConfig.getString(key);
      return x;
    }
  }
}
