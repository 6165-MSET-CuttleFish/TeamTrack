import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/views/LandingPage.dart';
import 'Verify.dart';
import 'Login.dart';

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    if (firebaseUser == null) {
      return LoginView();
    } else if (!firebaseUser.emailVerified && !firebaseUser.isAnonymous) {
      return Verify();
    } else {
      return LandingPage();
    }
  }
}
