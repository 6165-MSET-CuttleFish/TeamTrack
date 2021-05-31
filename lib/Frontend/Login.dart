import 'package:teamtrack/Frontend/Assets/PlatformGraphics.dart';
import 'package:teamtrack/Frontend/EventsList.dart';
import 'package:teamtrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auth_buttons/auth_buttons.dart';

class LoginView extends StatefulWidget {
  LoginView({Key key, this.dataModel}) : super(key: key);
  final DataModel dataModel;

  @override
  _LoginView createState() => _LoginView();
}

class _LoginView extends State<LoginView> {
  PageController _controller = PageController(initialPage: 0);
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        body: Stack(alignment: Alignment.center, children: [
      Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.cyan, Colors.deepPurple])),
      ),
      SafeArea(
          child: ListView(
        children: [
          Image.asset("loadingscreen.png"),
          Card(
            color: Colors.transparent,
            child: Container(
              width: size.width - 60,
              height: 200,
              child: PageView(
                controller: _controller,
                children: <Widget>[
                  signInList(),
                  emailPassword(),
                ],
              ),
            ),
            semanticContainer: true,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            elevation: 1,
            margin: EdgeInsets.all(10),
          ),
          // GoogleAuthButton(
          //   onPressed: () {},
          //   darkMode: false,
          //   style: AuthButtonStyle(
          //       borderRadius: 8,
          //       iconSize: 20,
          //       shadowColor: Colors.transparent,
          //       textStyle: TextStyle(fontSize: 12)),
          // )
        ],
      )),
    ]));
  }

  Widget emailPassword() {
    return Padding(
        padding: EdgeInsets.all(5),
        child: Column(
          children: [
            PlatformTextField(
              keyboardType: TextInputType.emailAddress,
              placeholder: "Email",
            ),
            PlatformTextField(
              keyboardType: TextInputType.visiblePassword,
              placeholder: "Password",
              obscureText: true,
            ),
            PlatformButton(
              child: Text("Login"),
              color: Colors.green,
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EventsList(
                              dataModel: dataModel,
                            )));
              },
            ),
          ],
        ));
  }

  Widget signInList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GoogleAuthButton(
          onPressed: () {},
          style:
              AuthButtonStyle(iconSize: 20, textStyle: TextStyle(fontSize: 14)),
        ),
        FacebookAuthButton(
          onPressed: () {},
          style:
              AuthButtonStyle(iconSize: 20, textStyle: TextStyle(fontSize: 14)),
        ),
        EmailAuthButton(
          onPressed: () {
            setState(() {
              _controller.nextPage(
                  duration: Duration(milliseconds: 500), curve: Curves.linear);
            });
          },
          style:
              AuthButtonStyle(iconSize: 20, textStyle: TextStyle(fontSize: 14)),
        ),
        GithubAuthButton(
            onPressed: () {},
            style: AuthButtonStyle(
                iconSize: 20, textStyle: TextStyle(fontSize: 14)))
      ],
    );
  }
}
