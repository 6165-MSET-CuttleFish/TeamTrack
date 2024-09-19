import 'package:flutter/material.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/providers/Auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordConfirmController = TextEditingController();
  TextEditingController displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool readPrivacyPolicy = false;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: 30),
        child: Container(
          color: Theme.of(context).canvasColor,
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
                    return null;
                  },
                  placeholder: "Name",
                  keyboardType: TextInputType.name,
                ),
                PlatformFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  placeholder: "Email",
                  validator: (val) {
                    if (val?.trim().isEmpty ?? true) {
                      return "Please enter your email";
                    }
                    return null;
                  },
                ),
                PlatformFormField(
                  controller: passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  placeholder: "Password",
                  validator: (val) {
                    if (val?.trim().isEmpty ?? true) {
                      return "Please enter your password";
                    }
                    return null;
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
                    return null;
                  },
                  placeholder: "Confirm password",
                  obscureText: true,
                ),
                Row(
                  children: [
                    Text('I have read and agree to the '),
                    TextButton(
                        onPressed: () => launch(
                            "https://msetcuttlefish.weebly.com/privacy-policy-scouting-app.html"),
                        child: Text('terms of service')),
                    Spacer(),
                    PlatformSwitch(
                        value: readPrivacyPolicy,
                        onChanged: (val) {
                          setState(() => readPrivacyPolicy = val);
                        }),
                  ],
                ),
                PlatformButton(
                  child: Text("Sign Up"),
                  color: Colors.green,
                  onPressed: () async {
                    if (!readPrivacyPolicy) {
                      showPlatformDialog(
                        context: context,
                        builder: (context) => PlatformAlert(
                          title: Text("Terms of Service"),
                          content: Text(
                              "You must read and agree to the terms of service before you can sign up."),
                          actions: [
                            PlatformDialogAction(
                              child: Text("Okay"),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    }
                    if ((_formKey.currentState?.validate() ?? false) &&
                        readPrivacyPolicy) {
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
                              style: Theme.of(context).textTheme.bodyLarge,
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
