import 'package:TeamTrack/Graphic%20Assets/Collapsible.dart';
import 'package:TeamTrack/backend.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CardView extends StatefulWidget {
  CardView({Key key, this.child, this.collapsed}) : super(key: key);
  final Widget child;
  final Widget collapsed;
  @override
  State<StatefulWidget> createState() => _CardView();
}

class _CardView extends State<CardView> {
  bool _genBool = false;
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _genBool = toggle(_genBool);
          });
        },
        onTapDown: (TapDownDetails details) {
          setState(() {
            _isPressed = true;
          });
        },
        onTapUp: (TapUpDetails details) {
          setState(() {
            _isPressed = false;
          });
        },
        onTapCancel: () {
          setState(() {
            _isPressed = false;
          });
        },
        child: Card(
          color: CupertinoColors.darkBackgroundGray,
          elevation: 3,
          shadowColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15))),
          child: Column(children: [
            AnimatedContainer(
                curve: Curves.fastLinearToSlowEaseIn,
                duration: Duration(milliseconds: 800),
                width: getWidth(),
                height: getHeight(),
                child: widget.child),
            Collapsible(
              isCollapsed: _genBool,
              child: widget.collapsed,
            )
          ]),
        ),
      ),
    );
  }

  double getWidth() {
    double val = !_genBool
        ? MediaQuery.of(context).size.width
        : MediaQuery.of(context).size.width - 50;
    if (_isPressed) {
      val /= 1.2;
    }
    return val;
  }

  double getHeight() {
    double val = _genBool ? 250 : 200;
    if (_isPressed && _genBool) {
      val /= 1.2;
    }
    return val;
  }
}
