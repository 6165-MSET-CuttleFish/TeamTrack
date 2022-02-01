import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/providers/PushNotifications.dart';
import 'package:teamtrack/views/LandingPage.dart';
import 'Verify.dart';
import 'Login.dart';

class AuthenticationWrapper extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AuthenticationWrapper();
}

class _AuthenticationWrapper extends State<AuthenticationWrapper> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    return FutureBuilder(
      future: loadApp(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: PlatformProgressIndicator());
        if (firebaseUser == null) {
          return LoginView();
        } else if (!firebaseUser.emailVerified && !firebaseUser.isAnonymous) {
          return Verify();
        } else {
          return LandingPage();
        }
      },
    );
  }

  Future<String> loadApp() async {
    await remoteConfig.fetchAndActivate();
    Statics.gameName = remoteConfig.getString("gameName");
    await dataModel.restoreEvents();
    if (!NewPlatform.isWeb) {
      final notification = PushNotifications();
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      await notification.initialize();
      String? token = await notification.getToken();
      if (token != "") {
        dataModel.token = token;
      }
    }
    return "Success";
  }
}
