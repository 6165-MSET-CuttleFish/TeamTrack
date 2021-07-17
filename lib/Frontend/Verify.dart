import 'package:firebase_auth/firebase_auth.dart';
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
                      "A verfication email has been sent,",
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    PlatformButton(
                      color: Colors.blue,
                      child: Text("Send Email Again"),
                      onPressed: () async {
                        await context.read<User?>()?.sendEmailVerification();
                        showPlatformDialog(
                          context: context,
                          builder: (_) => PlatformAlert(
                            title: Text("Verification Email Sent"),
                            actions: [
                              PlatformDialogAction(
                                child: Text("Okay"),
                                onPressed: () => Navigator.pop(context),
                                isDefaultAction: true,
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    PlatformButton(
                      color: CupertinoColors.systemRed,
                      child: Text("Sign Out"),
                      onPressed: () =>
                          context.read<AuthenticationService>().signOut(),
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
