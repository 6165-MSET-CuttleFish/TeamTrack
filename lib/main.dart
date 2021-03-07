import 'package:teamtrack/Frontend/EventsList.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class TeamTrack extends StatefulWidget {
  @override
  _TeamTrack createState() => _TeamTrack();
}

class _TeamTrack extends State<TeamTrack> {
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
          home: EventsList(
            dataModel: dataModel,
          ));
    }));
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
    return TeamTrack();
  }
}
