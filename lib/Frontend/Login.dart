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
  Size size;
  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
        body: Stack(alignment: Alignment.bottomCenter, children: [
      Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
              Color.fromRGBO(25, 25, 112, 1),
              Color.fromRGBO(25, 25, 112, 1),
              Color.fromRGBO(25, 25, 112, 1),
              Colors.grey,
              Colors.grey,
              Colors.black,
              Colors.black,
              Colors.black
            ])),
      ),
      Column(children: [Image.asset("LoadingScreen2.png"), Spacer()]),

      //Image.asset("LoadingScreen2.png"),
      SafeArea(
        child: Card(
          color: Colors.transparent,
          child: Container(
            width: size.width - 20,
            height: 190,
            child: PageView(
              controller: _controller,
              children: <Widget>[
                signInList(),
                emailPassword(),
              ],
            ),
          ),
          semanticContainer: true,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          elevation: 1,
          margin: EdgeInsets.all(10),
        ),
      )
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
            Padding(padding: EdgeInsets.all(10)),
            PlatformTextField(
              keyboardType: TextInputType.visiblePassword,
              placeholder: "Password",
              obscureText: true,
            ),
            Padding(padding: EdgeInsets.all(5)),
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
    return ListView(
      children: [
        GithubAuthButton(
            onPressed: () {},
            style: AuthButtonStyle(
                iconSize: 20,
                textStyle: TextStyle(fontSize: 14),
                width: size.width - 80)),
        GoogleAuthButton(
          onPressed: () {},
          darkMode: true,
          style: AuthButtonStyle(
              iconSize: 20,
              textStyle: TextStyle(fontSize: 14, color: Colors.white),
              width: size.width - 80),
        ),
        FacebookAuthButton(
          onPressed: () {},
          style: AuthButtonStyle(
              iconSize: 20,
              textStyle: TextStyle(fontSize: 14, color: Colors.white),
              width: size.width - 80),
        ),
        EmailAuthButton(
          onPressed: () {
            setState(() {
              _controller.nextPage(
                  duration: Duration(milliseconds: 500), curve: Curves.linear);
            });
          },
          style: AuthButtonStyle(
              iconSize: 20,
              textStyle: TextStyle(fontSize: 14),
              width: size.width - 80),
        ),
      ],
    );
  }
}
