import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:teamtrack/Frontend/EventsList.dart';
import 'package:teamtrack/Frontend/Provider/google_sign_in.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  LoginView({Key? key}) : super(key: key);

  @override
  _LoginView createState() => _LoginView();
}

class _LoginView extends State<LoginView> {
  PageController _controller = PageController(initialPage: 0);
  late Size size;
  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    // return Scaffold(
    //   body: ChangeNotifierProvider(
    //     create: (context) => GoogleSignInProvider(),
    //     child: StreamBuilder(
    //       stream: FirebaseAuth.instance.authStateChanges(),
    //       builder: (context, snapshot) {
    //         final provider = Provider.of<GoogleSignInProvider>(context);

    //         if (provider.isSigningIn) {
    //           return buildLoading();
    //         } else if (snapshot.hasData) {
    //           return EventsList();
    //         } else {
    //           return signInList();
    //         }
    //       },
    //     ),
    //   ),
    // );
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Color.fromRGBO(25, 25, 112, 1),
                  Colors.black,
                ],
              ),
            ),
          ),
          Column(
            children: [
              Image.asset(
                "LoadingScreen2.png",
              ),
              Spacer()
            ],
          ),
          SafeArea(
            child: Card(
              color: Theme.of(context).cardColor.withOpacity(0.7),
              child: Container(
                width: size.width - 20,
                height: 310,
                child: PageView(
                  controller: _controller,
                  children: <Widget>[signInList(), signInSheet()],
                ),
              ),
              semanticContainer: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 1,
              margin: EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoading() => Center(child: CircularProgressIndicator());

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController displayNameController = TextEditingController();
  Widget signInSheet() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          PlatformTextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            placeholder: "Email",
          ),
          Padding(
            padding: EdgeInsets.all(10),
          ),
          PlatformTextField(
            controller: passwordController,
            keyboardType: TextInputType.visiblePassword,
            placeholder: "Password",
            obscureText: true,
          ),
          Padding(
            padding: EdgeInsets.all(5),
          ),
          PlatformButton(
            child: Text("Sign In"),
            color: Colors.green,
            onPressed: () async {
              String? s = await context.read<AuthenticationService>().signIn(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );
              emailController.clear();
              passwordController.clear();
              if (s != "Signed in") {
                showPlatformDialog(
                  context: context,
                  builder: (BuildContext context) => PlatformAlert(
                    title: Text('Error'),
                    content: Text(
                      s ?? 'Something went wrong',
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                    actions: [
                      PlatformDialogAction(
                        isDefaultAction: true,
                        child: Text('Okay'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget signInList() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        PlatformButton(
          color: Theme.of(context).accentColor,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => signUpSheet(),
              isScrollControlled: true,
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(Icons.person), Text('Sign Up')],
          ),
        ),
        GithubAuthButton(
          onPressed: () {},
          style: AuthButtonStyle(
              iconSize: 20,
              textStyle: TextStyle(fontSize: 14),
              width: size.width - 80),
        ),
        GoogleAuthButton(
          onPressed: () async {
            await context.read<AuthenticationService>().signInWithGoogle();
          },
          darkMode: true,
          style: AuthButtonStyle(
              iconSize: 20,
              textStyle: TextStyle(fontSize: 14, color: Colors.white),
              width: size.width - 80),
        ),
        AppleAuthButton(
          onPressed: () async {
            await context.read<AuthenticationService>().signInWithApple();
          },
          darkMode: true,
          style: AuthButtonStyle(
              iconSize: 20,
              textStyle: TextStyle(fontSize: 14, color: Colors.white),
              width: size.width - 80),
        ),
        EmailAuthButton(
          onPressed: () {
            setState(
              () {
                _controller.nextPage(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.linear);
              },
            );
          },
          style: AuthButtonStyle(
              iconSize: 20,
              textStyle: TextStyle(fontSize: 14),
              width: size.width - 80),
        ),
      ],
    );
  }

  Widget signUpSheet() {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.all(20),
              ),
              PlatformTextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                placeholder: "Email",
              ),
              Padding(
                padding: EdgeInsets.all(5),
              ),
              PlatformTextField(
                controller: displayNameController,
                keyboardType: TextInputType.emailAddress,
                placeholder: "Display Name",
              ),
              Padding(
                padding: EdgeInsets.all(5),
              ),
              PlatformTextField(
                controller: passwordController,
                keyboardType: TextInputType.visiblePassword,
                placeholder: "Password",
                obscureText: true,
              ),
              Padding(
                padding: EdgeInsets.all(5),
              ),
              PlatformButton(
                child: Text("Sign Up"),
                color: Colors.green,
                onPressed: () async {
                  String? s =
                      await context.read<AuthenticationService>().signUp(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                            displayName: displayNameController.text.trim(),
                          );
                  if (s == "Signed up") {
                    emailController.clear();
                    passwordController.clear();
                    displayNameController.clear();
                    Navigator.of(context).pop();
                    await context.read<AuthenticationService>().signIn(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );
                  } else {
                    showPlatformDialog(
                      context: context,
                      builder: (context) => PlatformAlert(
                        title: Text('Error'),
                        content: Text(
                          s ?? 'Something went wrong',
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        actions: [
                          PlatformDialogAction(
                            isDefaultAction: true,
                            child: Text('Okay'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          RawMaterialButton(
            shape: CircleBorder(),
            fillColor: Colors.grey.withOpacity(0.4),
            child: Icon(Icons.clear),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
