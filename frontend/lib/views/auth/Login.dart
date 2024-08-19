import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/views/auth/SignUpScreen.dart';
import 'package:teamtrack/providers/Auth.dart';
import 'package:flutter/material.dart';

import 'package:auth_buttons/src/shared/auth_icons.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  LoginView({super.key, this.returnBack});
  final bool? returnBack;
  @override
  State<LoginView> createState() => _LoginView();
}

class _LoginView extends State<LoginView> {
  PageController _controller = PageController(initialPage: 0);
  late Size size;
  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            decoration: BoxDecoration(),
          ),
          Column(
            children: [
              Image.asset(
                "assets/images/LoadingScreen.png",
                height: MediaQuery.of(context).size.height,
              ),
              Spacer(),
            ],
          ),
          SafeArea(
            child: Card(
              color: Theme.of(context).cardColor.withOpacity(0.7),
              child: Container(
                width: size.width - 20,
                height: context.read<User?>()?.isAnonymous ?? false
                    ? size.height * .35
                    : size.height * .45,
                child: PageView(
                  controller: _controller,
                  children: <Widget>[
                    signInList(),
                    if (!(context.read<User?>()?.isAnonymous ?? false))
                      signInSheet()
                  ],
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
  TextEditingController passwordConfirmController = TextEditingController();
  TextEditingController displayNameController = TextEditingController();

  Widget signInSheet() => Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _controller.previousPage(
                      duration: Duration(milliseconds: 200),
                      curve: Curves.linear,
                    ),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                    ),
                  ),
                  Spacer(),
                ],
              ),
            ),
            PlatformTextField(
              textInputAction: TextInputAction.next,
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              placeholder: "Email",
            ),
            Padding(
              padding: EdgeInsets.all(10),
            ),
            PlatformTextField(
              textInputAction: TextInputAction.next,
              controller: passwordController,
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              placeholder: "Password",
            ),
            Padding(
              padding: EdgeInsets.all(0),
            ),
            Row(children: [
              TextButton(
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    builder: (context) => SignUpScreen(),
                    isScrollControlled: true,
                  );
                  if (widget.returnBack ?? false) Navigator.of(context).pop();
                },
                child: Text('Sign Up',
                    style: Theme.of(context).textTheme.bodyMedium?.apply(
                        color: Colors.blue,
                        decoration: TextDecoration.underline)),
              ),
              TextButton(
                child: Text("Forgot Password?",
                    style: Theme.of(context).textTheme.bodyMedium?.apply(
                        color: Colors.blue,
                        decoration: TextDecoration.underline)),
                onPressed: () async {
                  String? s = await context
                      .read<AuthenticationService>()
                      .forgotPassword(email: emailController.text.trim());
                  emailController.clear();
                  passwordController.clear();
                  if (s != "sent") {
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
                  } else {
                    showPlatformDialog(
                      context: context,
                      builder: (BuildContext context) => PlatformAlert(
                        title: Text('Success'),
                        content: Text(
                          'Reset email sent',
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
            ]),
            Padding(padding: EdgeInsets.all(10)),
            OutlinedButton(
                onPressed: () async {
                  String? s =
                      await context.read<AuthenticationService>().signIn(
                            email: emailController.text.trim(),
                            password: passwordController.text,
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
                child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Sign In",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ]))),
          ],
        ),
      );

  Widget signInList() => Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (!(context.read<User?>()?.isAnonymous ?? false))
            Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Log in",
                  style: Theme.of(context).textTheme.titleLarge,
                  textScaleFactor: 1.5,
                )),
          OutlinedButton(
              onPressed: () async {
                await context.read<AuthenticationService>().signInWithGoogle();
                if (widget.returnBack ?? false) Navigator.of(context).pop();
              },
              child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image(
                            height: 20,
                            image: ExactAssetImage(AuthIcons.google[0])),
                        SizedBox(width: 25),
                        Text(
                          "Continue with Google",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(width: 25),
                      ]))),
          if (!(context.read<User?>()?.isAnonymous ?? false))
            OutlinedButton(
                onPressed: () {
                  setState(
                    () {
                      _controller.nextPage(
                        duration: Duration(milliseconds: 200),
                        curve: Curves.linear,
                      );
                    },
                  );
                },
                child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.email_outlined,
                              size: 20, color: Colors.white),
                          SizedBox(width: 40),
                          Text(
                            "Sign in with Email",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(width: 40),
                        ]))),
          Text("Or", style: Theme.of(context).textTheme.titleMedium),
          OutlinedButton(
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  builder: (context) => SignUpScreen(),
                  isScrollControlled: true,
                );
                if (widget.returnBack ?? false) Navigator.of(context).pop();
              },
              child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 50,
                        ),
                        Text(
                          "Create an Account",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(
                          width: 50,
                        ),
                      ]))),
          if (!(context.read<User?>()?.isAnonymous ?? false))
            TextButton(
                onPressed: () => showPlatformDialog(
                      context: context,
                      builder: (context) => PlatformAlert(
                        title: Text('Anonymously Sign In?'),
                        content: Text('This has limited functionality'),
                        actions: [
                          PlatformDialogAction(
                            isDefaultAction: true,
                            child: Text('No'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          PlatformDialogAction(
                            isDestructive: true,
                            child: Text('Yes'),
                            onPressed: () async {
                              await context
                                  .read<AuthenticationService>()
                                  .signInWithAnonymous();
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                child: Text("Continue without an account",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.apply(decoration: TextDecoration.underline)))

          /*if (NewPlatform.isIOS)
        AppleAuthButton(
          onPressed: () async {
            await context.read<AuthenticationService>().signInWithApple();
            if (widget.returnBack ?? false) Navigator.of(context).pop();
          },
          darkMode: true,
          style: AuthButtonStyle(
            iconSize: 20,
            width: size.width - 80,
          ),
        ),*/
          ,
          if (context.read<User?>()?.isAnonymous ?? false)
            OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Go Back",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ])))
        ],
      );
}
