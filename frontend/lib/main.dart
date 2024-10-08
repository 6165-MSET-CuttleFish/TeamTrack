import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  await remoteConfig.fetchAndActivate();
  // season's game name (to be changed in remote config every season)
  Statics.gameName = remoteConfig.getString("gameName");
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
      bodyLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
      bodySmall: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
      titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
      titleSmall: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w700,color: Colors.black),
    ),
shadowColor:Colors.black,
    colorScheme: ColorScheme.light(
      primary: Color.fromRGBO(80, 64, 153,1),
      secondary: Color.fromRGBO(151, 78, 195,1),
    ),
  );

  final darkTheme = ThemeData(
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w600,color: Colors.white),
      bodyMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w600,color: Colors.white),
      bodySmall: GoogleFonts.montserrat(fontWeight: FontWeight.w500,color: Colors.white),
      titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w700,color: Colors.white),
      titleMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w700,color: Colors.white),
      titleSmall: GoogleFonts.montserrat(fontWeight: FontWeight.w700,color: Colors.white),
      headlineMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w700,color: Colors.white),
    ),
    splashColor: NewPlatform.isAndroid ? Colors.deepPurple : Colors.transparent,
    shadowColor: Colors.white,
    brightness: Brightness.dark,
    canvasColor: Colors.black,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      focusElevation: 0,
      backgroundColor: Colors.cyan,
      elevation: 0,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity, colorScheme: ColorScheme.dark(
      primary: Color.fromRGBO(25, 167, 206,1),
      secondary: Colors.deepPurple,
    ).copyWith(background: Colors.black),
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
