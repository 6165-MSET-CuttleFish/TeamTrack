import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:TeamTrack/backend.dart';
import 'package:TeamTrack/score.dart';
import 'package:tuple/tuple.dart';
import 'dart:io' show Platform;
abstract class PlatformWidget<C extends Widget, M extends Widget> extends StatelessWidget{
  PlatformWidget({Key key}) : super(key: key);

  C buildCupertinoWidget(BuildContext context);
  M buildMaterialWidget(BuildContext context);
  @override
  Widget build(BuildContext context){
    if(Platform.isIOS){
      return buildCupertinoWidget(context);
    } else {
      return buildMaterialWidget(context);
    }
  }
}
class PlatformSwitch extends PlatformWidget<CupertinoSwitch, Switch> {
  PlatformSwitch({Key key, this.value, this.onChanged}) : super(key: key);
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  CupertinoSwitch buildCupertinoWidget(BuildContext context) {
    return CupertinoSwitch(value: value, onChanged: onChanged,);
  }

  @override
  Switch buildMaterialWidget(BuildContext context) {
    return Switch(value: value, onChanged: onChanged);
  }
}
class PlatformAlert extends PlatformWidget<CupertinoAlertDialog, AlertDialog> {
  PlatformAlert({Key key, this.title, this.content, this.actions}) : super(key: key);
  final Widget title;
  final Widget content;
  final List<Widget> actions;
  @override
  CupertinoAlertDialog buildCupertinoWidget(BuildContext context) {
    return CupertinoAlertDialog(
      title: title,
      content: content,
      actions: actions,
    );
  }

  @override
  AlertDialog buildMaterialWidget(BuildContext context) {
    return AlertDialog(
      title: title,
      content: content,
      actions: actions,
    );
  }
}
class PlatformButton extends PlatformWidget<CupertinoButton, MaterialButton> {
  PlatformButton({Key key, this.child, this.onPressed, this.disabledColor = Colors.transparent, this.color = null}) : super(key: key);
  final Widget child;
  final Function onPressed;
  final Color color;
  final Color disabledColor;
  @override
  CupertinoButton buildCupertinoWidget(BuildContext context) {
    return CupertinoButton(child: child, onPressed : onPressed, color: color, disabledColor: disabledColor,);
  }

  @override
  MaterialButton buildMaterialWidget(BuildContext context) {
    return MaterialButton(child: child, onPressed : onPressed, color: color, disabledColor: disabledColor,);
  }
}
class PlatformScaffold extends PlatformWidget<CupertinoPageScaffold, Scaffold>{
  PlatformScaffold({Key key, this.child, this.backgroundColor = null, this.resizeToAvoidBottomInset = true}) : super(key: key);
  final Widget child;
  final Color backgroundColor;
  final bool resizeToAvoidBottomInset;
  @override
  CupertinoPageScaffold buildCupertinoWidget(BuildContext context) {
    return CupertinoPageScaffold(child: null, backgroundColor: backgroundColor, resizeToAvoidBottomInset: resizeToAvoidBottomInset);
  }

  @override
  Scaffold buildMaterialWidget(BuildContext context) {
    return Scaffold(body: null, backgroundColor: backgroundColor, resizeToAvoidBottomInset: resizeToAvoidBottomInset);
  }
}