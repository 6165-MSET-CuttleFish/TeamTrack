import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/providers/Auth.dart';
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
                      PlatformText(
                        "A verfication email has been sent,",
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      PlatformText(
                        "Once verified, you will need to sign out and sign back in using these credentials",
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      PlatformButton(
                        color: Colors.blue,
                        child: PlatformText("Send Email Again"),
                        onPressed: () async {
                          await context.read<User?>()?.sendEmailVerification();
                          showPlatformDialog(
                            context: context,
                            builder: (_) => PlatformAlert(
                              title: PlatformText("Verification Email Sent"),
                              actions: [
                                PlatformDialogAction(
                                  child: PlatformText("Okay"),
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
                        child: PlatformText("Sign Out"),
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
