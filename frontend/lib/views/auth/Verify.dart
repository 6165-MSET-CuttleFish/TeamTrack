import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/providers/Auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Verify extends StatefulWidget {
  Verify({super.key});
  @override
  State<Verify> createState() => _Verify();
}

class _Verify extends State<Verify> {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            Image.asset(
              "LoadingScreen.png",
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
                      Text(
                        "Once verified, you will need to sign out and sign back in using these credentials",
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
