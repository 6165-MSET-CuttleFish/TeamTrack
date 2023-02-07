import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/views/auth/SignUpScreen.dart';
import 'package:teamtrack/providers/Auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auth_buttons/auth_buttons.dart';
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
OutlinedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                            Theme.of(context).platform == TargetPlatform.iOS? Theme.of(context).colorScheme.primary?.withOpacity(1):Theme.of(context).colorScheme.primary?.withOpacity(.6),
                          ),
                          foregroundColor: MaterialStateProperty.all(
                              Theme.of(context).textTheme.bodyText2?.color),
                          side: MaterialStateProperty.all(
                            BorderSide(color: Theme.of(context).colorScheme.primary ),
                          ),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius:Theme.of(context).platform == TargetPlatform.iOS? BorderRadius.all(
                                Radius.elliptical(10, 10),
                              ):BorderRadius.all(
                                Radius.elliptical(50 , 50),
                              ),
                            ),
                          ),
                        ),
                    onPressed: () async {
                      await showModalBottomSheet(
                        context: context,
                        builder: (context) => SignUpScreen(),
                        isScrollControlled: true,
                      );
                      if (widget.returnBack ?? false)
                        Navigator.of(context).pop();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.person), Text('Sign Up')],
                    ),
                  ),
                  OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        Theme.of(context).platform == TargetPlatform.iOS? Colors.purple?.withOpacity(1):Colors.purple?.withOpacity(0.6),
                      ),
                      foregroundColor: MaterialStateProperty.all(
                          Theme.of(context).textTheme.bodyText2?.color),
                      side: MaterialStateProperty.all(
                        BorderSide(color: Colors.purple ?? Colors.transparent),
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius:Theme.of(context).platform == TargetPlatform.iOS? BorderRadius.all(
                            Radius.elliptical(10, 10),
                          ):BorderRadius.all(
                            Radius.elliptical(50 , 50),
                          ),
                        ),
                      ),
                    ),
                    child: Text(
                      "Forgot Password",
                      style: TextStyle(fontSize: 14),
                    ),
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

  Widget signInList() => Column(
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
            color: Theme.of(context).colorScheme.primary,
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                builder: (context) => SignUpScreen(),
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
              width: size.width - 80,
            ),
          ),
          if (NewPlatform.isIOS)
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
