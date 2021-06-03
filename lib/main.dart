import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:flutter/services.dart';
import 'package:teamtrack/Frontend/EventsList.dart';
import 'package:teamtrack/Frontend/Login.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class TeamTrack extends StatefulWidget {
  @override
  _TeamTrack createState() => _TeamTrack();
}

class _TeamTrack extends State<TeamTrack> {
  final lightTheme = ThemeData(
    primarySwatch: Colors.deepPurple,
    splashColor: Platform.isAndroid ? Colors.cyan : Colors.transparent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  final darkTheme = ThemeData(
    textTheme: TextTheme(bodyText2: TextStyle(color: Colors.white)),
    backgroundColor: Colors.black,
    splashColor: Platform.isAndroid ? Colors.deepPurple : Colors.transparent,
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

  @override
  void initState() {
    super.initState();
    getCurrentAppTheme();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
        await themeChangeProvider.darkThemePreference.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    dataModel = DataModel();
    return ChangeNotifierProvider(create: (_) {
      return themeChangeProvider;
    }, child: Consumer<DarkThemeProvider>(
        builder: (BuildContext context, value, Widget child) {
      return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TeamTrack',
          theme: themeChangeProvider.darkTheme ? darkTheme : lightTheme,
          darkTheme: darkTheme,
          home: AuthenticationWrapper());
    }));
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User>();
    if (firebaseUser == null) {
      return LoginView(dataModel: dataModel);
    } else {
      return EventsList(dataModel: dataModel);
      // return StreamBuilder<Database.Event>(
      //     stream: firebaseDatabase.reference().child('alpha').onValue,
      //     builder: (context, snapshot) {
      //       return Container(
      //         height: MediaQuery.of(context).size.height,
      //         width: MediaQuery.of(context).size.width,
      //         child: Center(
      //           child: Text(snapshot.data.snapshot.value['number']),
      //         ),
      //       );
      //     });
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
    dataModel = DataModel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MultiProvider(
      providers: [
        Provider<AuthenticationService>(
          create: (_) => AuthenticationService(FirebaseAuth.instance),
        ),
        StreamProvider(
            create: (context) =>
                context.read<AuthenticationService>().authStateChanges),
        Provider<DatabaseServices>(
          create: (_) => DatabaseServices(),
        ),
        StreamProvider(
            create: (context) =>
                context.read<DatabaseServices>().getEventChanges),
      ],
      child: TeamTrack(),
    );
  }
}
