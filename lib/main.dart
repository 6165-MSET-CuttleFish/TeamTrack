import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:teamtrack/Frontend/EventsList.dart';
import 'package:teamtrack/Frontend/Login.dart';
import 'package:teamtrack/Frontend/Verify.dart';
import 'package:teamtrack/PushNotifications.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await remoteConfig.fetchAndActivate();
  Statics.gameName = remoteConfig.getString("gameName");
  await dataModel.restoreEvents();
  var notification = PushNotifications();
  NotificationSettings settings = await messaging.requestPermission(
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
  runApp(MyApp());
}

class TeamTrack extends StatefulWidget {
  @override
  _TeamTrack createState() => _TeamTrack();
}

class _TeamTrack extends State<TeamTrack> {
  final lightTheme = ThemeData(
    primarySwatch: Colors.deepPurple,
    splashColor: NewPlatform.isAndroid() ? Colors.cyan : Colors.transparent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  final darkTheme = ThemeData(
    textTheme: TextTheme(
      bodyText2: TextStyle(color: Colors.white),
    ),
    backgroundColor: Colors.black,
    splashColor:
        NewPlatform.isAndroid() ? Colors.deepPurple : Colors.transparent,
    shadowColor: Colors.white,
    brightness: Brightness.dark,
    canvasColor: Colors.black,
    buttonColor: Colors.grey,
    accentColor: Colors.cyan,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      focusElevation: 0,
      backgroundColor: Colors.cyan,
      elevation: 0,
    ),
    primarySwatch: Colors.cyan,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
        await themeChangeProvider.darkThemePreference.getTheme();
  }

  @override
  void initState() {
    super.initState();
    getCurrentAppTheme();
  }

  @override
  Widget build(context) => ChangeNotifierProvider(
        create: (_) => themeChangeProvider,
        child: Consumer<DarkThemeProvider>(
          builder: (BuildContext context, value, Widget? child) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TeamTrack',
            theme: themeChangeProvider.darkTheme ? darkTheme : lightTheme,
            darkTheme: darkTheme,
            home: AuthenticationWrapper(),
          ),
        ),
      );
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    if (firebaseUser == null) {
      return LoginView();
    } else if (!firebaseUser.emailVerified && !firebaseUser.isAnonymous) {
      return Verify();
    } else {
      return EventsList();
    }
  }
}

class MyApp extends StatelessWidget {
  final lightTheme = ThemeData(
    primarySwatch: Colors.deepPurple,
    splashColor: Colors.cyan,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  final darkTheme = ThemeData(
    backgroundColor: Colors.black,
    splashColor: Colors.deepPurple,
    shadowColor: Colors.white,
    brightness: Brightness.dark,
    canvasColor: Colors.black,
    buttonColor: Colors.grey,
    accentColor: Colors.cyan,
    primarySwatch: Colors.cyan,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    firebaseDatabase.setPersistenceEnabled(true);
    return MultiProvider(
      providers: [
        Provider<AuthenticationService>(
          create: (_) => AuthenticationService(FirebaseAuth.instance),
        ),
        StreamProvider(
            initialData: null,
            create: (context) =>
                context.read<AuthenticationService>().authStateChanges),
      ],
      child: TeamTrack(),
    );
  }
}
