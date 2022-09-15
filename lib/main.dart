import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/providers/Auth.dart';
import 'package:teamtrack/providers/PushNotifications.dart';
import 'package:teamtrack/providers/Theme.dart';
import 'package:teamtrack/views/auth/AuthenticationWrapper.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await remoteConfig.fetchAndActivate();
  Statics.gameName = remoteConfig.getString("gameName");
  // season's game name (to be changed in remote config every season)
  dataModel.restoreEvents(); // restore on-device events from shared preferences
  if (!NewPlatform.isWeb) {
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    ); // ask for permission to receive push notifications
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await PushNotifications.initialize();
      String? token = await PushNotifications.getToken();
      if (token != "") {
        dataModel.token = token; // save token to later be pushed to firestore
      }
    } else {
      print('User declined or has not accepted permission');
    }
  }
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MultiProvider(
      providers: [
        Provider<AuthenticationService>(
          create: (_) => AuthenticationService(firebaseAuth),
        ),
        StreamProvider(
          initialData: null,
          create: (context) =>
              context.read<AuthenticationService>().authStateChanges,
        ),
      ],
      child: TeamTrack(),
    );
  }
}

class TeamTrack extends StatefulWidget {
  @override
  _TeamTrack createState() => _TeamTrack();
}

class _TeamTrack extends State<TeamTrack> {
  final lightTheme = ThemeData(
    splashColor: NewPlatform.isAndroid ? Colors.cyan : Colors.transparent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: TextTheme(
      bodyText1: GoogleFonts.gugi(),
      bodyText2: GoogleFonts.gugi(),
      caption: GoogleFonts.gugi(),
      headline6: GoogleFonts.gugi(),
      headline4: GoogleFonts.gugi(color: Colors.black),
    ),
    colorScheme: ColorScheme.light(
      primary: Colors.deepPurple,
      secondary: Colors.cyan,
    ),
  );

  final darkTheme = ThemeData(
    textTheme: TextTheme(
      bodyText1: GoogleFonts.gugi(color: Colors.white),
      bodyText2: GoogleFonts.gugi(color: Colors.white),
      caption: GoogleFonts.gugi(color: Colors.white),
      headline6: GoogleFonts.gugi(color: Colors.white),
      headline4: GoogleFonts.gugi(color: Colors.white),
    ),
    backgroundColor: Colors.black,
    splashColor: NewPlatform.isAndroid ? Colors.deepPurple : Colors.transparent,
    shadowColor: Colors.white,
    brightness: Brightness.dark,
    canvasColor: Colors.black,
    colorScheme: ColorScheme.dark(
      primary: Colors.cyan,
      primaryVariant: Colors.blue,
      secondary: Colors.deepPurple,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      focusElevation: 0,
      backgroundColor: Colors.cyan,
      elevation: 0,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  void getCurrentAppTheme() async => themeChangeProvider.darkTheme =
      await themeChangeProvider.darkThemePreference.getTheme();

  @override
  initState() {
    super.initState();
    getCurrentAppTheme();
  }

  @override
  build(_) => ChangeNotifierProvider(
        create: (_) => themeChangeProvider,
        child: Consumer<DarkThemeProvider>(
          builder: (context, value, child) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TeamTrack',
            theme: themeChangeProvider.darkTheme ? darkTheme : lightTheme,
            home: AuthenticationWrapper(),
          ),
        ),
      );
}
