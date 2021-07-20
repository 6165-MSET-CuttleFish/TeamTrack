import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  LoginView({Key? key, this.returnBack}) : super(key: key);
  final bool? returnBack;
  @override
  _LoginView createState() => _LoginView();
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
              Spacer(),
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
  Widget signInSheet() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Spacer(),
                PlatformButton(
                  child: Text(
                    "Forgot Password",
                    style: TextStyle(fontSize: 14),
                  ),
                  color: Colors.purple,
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
              ],
            ),
          ),
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
          ),
        ],
      ),
    );
  }

  Widget signInList() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (context.read<User?>()?.isAnonymous ?? false)
          PlatformButton(
            color: CupertinoColors.systemBlue,
            onPressed: () => Navigator.of(context).pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.arrow_back_ios_new_sharp), Text('Back')],
            ),
          ),
        PlatformButton(
          color: Theme.of(context).accentColor,
          onPressed: () async {
            await showModalBottomSheet(
              context: context,
              builder: (context) => signUpSheet(),
              isScrollControlled: true,
            );
            if (widget.returnBack ?? false) Navigator.of(context).pop();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(Icons.person), Text('Sign Up')],
          ),
        ),
        if (!(context.read<User?>()?.isAnonymous ?? false))
          PlatformButton(
            color: CupertinoColors.systemBlue,
            onPressed: () async => await context
                .read<AuthenticationService>()
                .signInWithAnonymous(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility_off),
                Text('Sign In Anonymously')
              ],
            ),
          ),
        GoogleAuthButton(
          onPressed: () async {
            await context.read<AuthenticationService>().signInWithGoogle();
            if (widget.returnBack ?? false) Navigator.of(context).pop();
          },
          darkMode: true,
          style: AuthButtonStyle(
              iconSize: 20,
              textStyle: TextStyle(fontSize: 14, color: Colors.white),
              width: size.width - 80),
        ),
        if (!(context.read<User?>()?.isAnonymous ?? false))
          EmailAuthButton(
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
            style: AuthButtonStyle(
              iconSize: 20,
              textStyle: TextStyle(fontSize: 14),
              width: size.width - 80,
            ),
          ),
      ],
    );
  }

  final _formKey = GlobalKey<FormState>();
  Widget signUpSheet() {
    return Padding(
      padding: EdgeInsets.only(top: 30),
      child: Container(
        color: Colors.black,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Spacer(),
                  RawMaterialButton(
                    onPressed: () {
                      emailController.clear();
                      passwordController.clear();
                      passwordConfirmController.clear();
                      displayNameController.clear();
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.cancel,
                      size: 30,
                    ),
                    shape: CircleBorder(),
                  ),
                ],
              ),
              PlatformFormField(
                controller: displayNameController,
                validator: (val) {
                  if (val?.trim().isEmpty ?? true) {
                    return "Please enter your name";
                  }
                },
                placeholder: "Enter name",
                keyboardType: TextInputType.name,
              ),
              PlatformFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                placeholder: "Enter email",
                validator: (val) {
                  if (val?.trim().isEmpty ?? true) {
                    return "Please enter your email";
                  }
                },
              ),
              PlatformFormField(
                controller: passwordController,
                keyboardType: TextInputType.visiblePassword,
                placeholder: "Enter password",
                validator: (val) {
                  if (val?.trim().isEmpty ?? true) {
                    return "Please enter your password";
                  }
                },
                obscureText: true,
              ),
              PlatformFormField(
                controller: passwordConfirmController,
                keyboardType: TextInputType.visiblePassword,
                validator: (val) {
                  if (val?.trim().isEmpty ?? true) {
                    return "Please confirm your password";
                  } else if (val != passwordController.text) {
                    return "Passwords don't match";
                  }
                },
                placeholder: "Confirm password",
                obscureText: true,
              ),
              PlatformButton(
                child: Text("Sign Up"),
                color: Colors.green,
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    String? s =
                        await context.read<AuthenticationService>().signUp(
                              email: emailController.text.trim(),
                              password: passwordController.text,
                              displayName: displayNameController.text.trim(),
                            );
                    if (s == "Signed up") {
                      emailController.clear();
                      passwordController.clear();
                      displayNameController.clear();
                      Navigator.of(context).pop();
                      await context.read<AuthenticationService>().signIn(
                            email: emailController.text.trim(),
                            password: passwordController.text,
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
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
