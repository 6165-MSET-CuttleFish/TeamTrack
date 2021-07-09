import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Verify extends StatefulWidget {
  Verify({Key? key}) : super(key: key);
  @override
  _Verify createState() => _Verify();
}

class _Verify extends State<Verify> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            "LoadingScreen2.png",
          ),
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Please verify your email address.",
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    PlatformButton(
                      color: CupertinoColors.systemRed,
                      child: Text("Sign Out"),
                      onPressed: () =>
                          {context.read<AuthenticationService>().signOut()},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
