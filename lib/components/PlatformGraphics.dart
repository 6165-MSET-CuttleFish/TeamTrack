import 'dart:math';
import 'package:firebase_database/firebase_database.dart' as Db;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/components/BarGraph.dart';
import 'package:teamtrack/components/CardView.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'dart:io' show Platform;

class NewPlatform {
  static bool isIOS() {
    try {
      return Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  static bool isAndroid() {
    try {
      return Platform.isAndroid;
    } catch (e) {
      return true;
    }
  }

  static bool isWeb() {
    try {
      var temp = Platform.isAndroid;
      print(temp);
    } catch (e) {
      return true;
    }
    return false;
  }
}

void showPlatformDialog({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
}) {
  if (NewPlatform.isIOS()) {
    showCupertinoDialog(
        context: context, builder: builder, barrierDismissible: false);
  } else {
    showDialog(context: context, builder: builder, barrierDismissible: true);
  }
}

PageRoute platformPageRoute(Widget Function(BuildContext) builder) {
  if (NewPlatform.isIOS()) {
    return CupertinoPageRoute(builder: builder);
  }
  return MaterialPageRoute(builder: builder);
}

abstract class PlatformWidget<C extends Widget, M extends Widget,
    W extends Widget?> extends StatelessWidget {
  PlatformWidget({Key? key}) : super(key: key);

  C buildCupertinoWidget(BuildContext context);
  M buildMaterialWidget(BuildContext context);
  W? buildWebWidget(BuildContext context) {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (NewPlatform.isIOS()) {
        return buildCupertinoWidget(context);
      } else {
        return buildMaterialWidget(context);
      }
    } catch (e) {
      return buildWebWidget(context) ?? buildMaterialWidget(context);
    }
  }
}

class PlatformSwitch extends PlatformWidget<CupertinoSwitch, Switch, Null> {
  PlatformSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.highlightColor,
  }) : super(key: key);
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? highlightColor;
  @override
  CupertinoSwitch buildCupertinoWidget(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: highlightColor ?? Theme.of(context).colorScheme.primary,
    );
  }

  @override
  Switch buildMaterialWidget(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: highlightColor ?? Theme.of(context).colorScheme.primary,
    );
  }
}

class PlatformText extends PlatformWidget<Text, Text, SelectableText> {
  PlatformText(
    this.text, {
    Key? key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
  }) : super(key: key);
  final String text;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  @override
  Text buildCupertinoWidget(BuildContext context) => Text(
        text,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaleFactor: textScaleFactor,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      );

  @override
  Text buildMaterialWidget(BuildContext context) =>
      buildCupertinoWidget(context);

  @override
  SelectableText buildWebWidget(BuildContext context) => SelectableText(
        text,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        textScaleFactor: textScaleFactor,
        maxLines: maxLines,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      );
}

class PlatformAlert
    extends PlatformWidget<CupertinoAlertDialog, AlertDialog, Null> {
  PlatformAlert({
    Key? key,
    this.title,
    this.content,
    this.actions,
  }) : super(key: key);
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  @override
  CupertinoAlertDialog buildCupertinoWidget(BuildContext context) {
    return CupertinoAlertDialog(
      title: Padding(
        child: title,
        padding: EdgeInsets.only(bottom: 10),
      ),
      content: content,
      actions: actions!,
    );
  }

  @override
  AlertDialog buildMaterialWidget(BuildContext context) {
    return AlertDialog(
      elevation: 0,
      title: title,
      content: content,
      actions: actions,
    );
  }
}

class PlatformTextField
    extends PlatformWidget<CupertinoTextField, TextFormField, Null> {
  PlatformTextField({
    Key? key,
    this.onChanged,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.placeholder,
    this.obscureText = false,
    this.controller,
    this.autoCorrect = true,
  }) : super(key: key);
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? placeholder;
  final bool obscureText;
  final TextEditingController? controller;
  final bool autoCorrect;
  @override
  CupertinoTextField buildCupertinoWidget(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      style: TextStyle(color: Theme.of(context).textTheme.bodyText2!.color),
      onChanged: onChanged,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      placeholder: placeholder,
      obscureText: obscureText,
      autocorrect: autoCorrect,
    );
  }

  @override
  TextFormField buildMaterialWidget(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Theme.of(context).textTheme.bodyText2!.color),
      onChanged: onChanged,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(labelText: placeholder),
      obscureText: obscureText,
      autocorrect: autoCorrect,
    );
  }
}

class PlatformDialogAction
    extends PlatformWidget<CupertinoDialogAction, TextButton, Null> {
  PlatformDialogAction({
    Key? key,
    this.child,
    this.isDefaultAction = false,
    this.onPressed,
    this.isDestructive = false,
  }) : super(key: key);
  final Widget? child;
  final bool isDefaultAction;
  final void Function()? onPressed;
  final bool isDestructive;
  @override
  CupertinoDialogAction buildCupertinoWidget(BuildContext context) {
    return CupertinoDialogAction(
      isDefaultAction: isDefaultAction,
      child: child!,
      onPressed: onPressed,
      isDestructiveAction: isDestructive,
    );
  }

  @override
  TextButton buildMaterialWidget(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: child!,
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(
          isDestructive
              ? Colors.red
              : Theme.of(context).textTheme.bodyText2?.color,
        ),
      ),
    );
  }
}

class PlatformButton
    extends PlatformWidget<CupertinoButton, OutlinedButton, Null> {
  PlatformButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.disabledColor = Colors.transparent,
    this.color,
  }) : super(key: key);
  final Widget child;
  final void Function()? onPressed;
  final Color? color;
  final Color disabledColor;
  @override
  CupertinoButton buildCupertinoWidget(BuildContext context) {
    return CupertinoButton(
      borderRadius: BorderRadius.all(Radius.circular(50)),
      child: child,
      onPressed: onPressed,
      color: color,
      disabledColor: disabledColor,
    );
  }

  @override
  OutlinedButton buildMaterialWidget(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: child,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(
          color?.withOpacity(0.6),
        ),
        foregroundColor: MaterialStateProperty.all(
            Theme.of(context).textTheme.bodyText2?.color),
        side: MaterialStateProperty.all(
          BorderSide(color: color ?? Colors.transparent),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.elliptical(100, 100),
            ),
          ),
        ),
      ),
    );
  }
}

class PlatformProgressIndicator extends PlatformWidget<
    CupertinoActivityIndicator, CircularProgressIndicator, Null> {
  @override
  CupertinoActivityIndicator buildCupertinoWidget(BuildContext context) =>
      CupertinoActivityIndicator();

  @override
  CircularProgressIndicator buildMaterialWidget(BuildContext context) =>
      CircularProgressIndicator();
}

class PlatformPicker<T>
    extends PlatformWidget<CupertinoPicker, DropdownButton, Null> {
  PlatformPicker({
    Key? key,
    required this.items,
    this.onSelectedItemChanged,
    required this.value,
    required this.arr,
  }) : super(key: key) {
    for (int i = 0; i < arr.length; i++) {
      dropdownItems.add(DropdownMenuItem<T>(
        child: items[i],
        value: arr[i],
      ));
    }
  }
  final void Function(dynamic)? onSelectedItemChanged;
  final List<Widget> items;
  final List<T> arr;
  final T value;
  final List<DropdownMenuItem<T>> dropdownItems = [];

  @override
  CupertinoPicker buildCupertinoWidget(BuildContext context) {
    return CupertinoPicker(
      itemExtent: 50,
      onSelectedItemChanged: onSelectedItemChanged,
      children: items,
    );
  }

  @override
  DropdownButton buildMaterialWidget(BuildContext context) {
    return DropdownButton<T>(
      items: dropdownItems,
      onChanged: onSelectedItemChanged,
      value: value,
    );
  }
}

class PlatformForm extends PlatformWidget<CupertinoFormSection, Form, Null> {
  PlatformForm({
    Key? key,
    required this.children,
    this.header,
  }) : super(key: key);
  final List<Widget> children;
  final Widget? header;
  @override
  CupertinoFormSection buildCupertinoWidget(BuildContext context) {
    return CupertinoFormSection(
      children: children,
      key: key,
      header: header,
    );
  }

  @override
  Form buildMaterialWidget(BuildContext context) {
    return Form(
      key: key,
      child: Column(
        children: [if (header != null) header!, ...children],
      ),
    );
  }
}

class PlatformFormField
    extends PlatformWidget<CupertinoTextFormFieldRow, TextFormField, Null> {
  PlatformFormField(
      {Key? key,
      required this.controller,
      this.validator,
      this.placeholder,
      this.keyboardType,
      this.prefix,
      this.obscureText = false})
      : super(key: key);
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? placeholder;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final bool obscureText;
  @override
  CupertinoTextFormFieldRow buildCupertinoWidget(BuildContext context) {
    return CupertinoTextFormFieldRow(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).textTheme.bodyText2?.color ??
                Colors.deepPurple,
            width: 1,
          ),
        ),
        controller: controller,
        validator: validator,
        placeholder: placeholder,
        keyboardType: keyboardType,
        prefix: prefix,
        obscureText: obscureText,
        style: TextStyle(color: Theme.of(context).textTheme.bodyText2?.color));
  }

  @override
  TextFormField buildMaterialWidget(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(labelText: placeholder),
      keyboardType: keyboardType,
      obscureText: obscureText,
    );
  }
}

class PlatformDatePicker
    extends PlatformWidget<CupertinoDatePicker, CalendarDatePicker, Null> {
  PlatformDatePicker(
      {Key? key,
      required this.minimumDate,
      required this.maximumDate,
      required this.onDateChanged})
      : super(key: key);
  final DateTime maximumDate, minimumDate;
  final void Function(DateTime) onDateChanged;
  @override
  CupertinoDatePicker buildCupertinoWidget(BuildContext context) =>
      CupertinoDatePicker(
        onDateTimeChanged: onDateChanged,
        minimumDate: minimumDate,
        maximumDate: maximumDate,
      );

  @override
  CalendarDatePicker buildMaterialWidget(BuildContext context) =>
      CalendarDatePicker(
          initialDate: maximumDate,
          firstDate: minimumDate,
          lastDate: maximumDate,
          onDateChanged: onDateChanged);
}

class Incrementor extends StatefulWidget {
  Incrementor({
    Key? key,
    required this.element,
    required this.onPressed,
    this.onIncrement,
    this.onDecrement,
    this.backgroundColor,
    this.event,
    this.score,
    this.opModeType,
    this.isTargetScore = false,
    this.mutableIncrement,
    this.mutableDecrement,
    this.path,
  }) : super(key: key);
  final ScoringElement element;
  final void Function() onPressed;
  final void Function()? onIncrement, onDecrement;
  final Db.MutableData Function(Db.MutableData)? mutableIncrement,
      mutableDecrement;
  final Color? backgroundColor;
  final Event? event;
  final Score? score;
  final OpModeType? opModeType;
  final bool isTargetScore;
  final String? path;
  @override
  State<StatefulWidget> createState() => _Incrementor();
}

class _Incrementor extends State<Incrementor> {
  CupertinoSegmentedControl buildPicker() => CupertinoSegmentedControl<int>(
        groupValue: widget.element.count,
        children: widget.element.nestedElements?.asMap().map(
                  (key, value) => MapEntry(
                    key,
                    Text(
                      value.name,
                    ),
                  ),
                ) ??
            {},
        onValueChanged: (val) async {
          if (!(widget.event?.shared ?? false)) {
            for (int i = 0;
                i < (widget.element.nestedElements?.length ?? 0);
                i++) {
              widget.element.nestedElements?[i].count = 0;
            }
            widget.element.nestedElements?[val].count = 1;
          }
          widget.onPressed();
          if (widget.path != null)
            await widget.event
                ?.getRef()
                ?.child(widget.path!)
                .runTransaction((mutableData) {
              if (widget.isTargetScore) {
                for (int i = 0;
                    i < (widget.element.nestedElements?.length ?? 0);
                    i++) {
                  mutableData.value['targetScore'][widget.opModeType?.toRep()]
                      [widget.element.nestedElements?[i].key] = 0;
                }
                mutableData.value['targetScore'][widget.opModeType?.toRep()]
                    [widget.element.nestedElements?[val].key] = 1;
                return mutableData;
              }
              final scoreIndex = widget.score?.id;
              for (int i = 1;
                  i < (widget.element.nestedElements?.length ?? 0);
                  i++) {
                mutableData.value['scores'][scoreIndex]
                        [widget.opModeType?.toRep()]
                    [widget.element.nestedElements?[i].key] = 0;
              }
              if (val != 0)
                mutableData.value['scores'][scoreIndex]
                        [widget.opModeType?.toRep()]
                    [widget.element.nestedElements?[val].key] = 1;
              return mutableData;
            });
        },
      );
  PlatformSwitch buildSwitch() => PlatformSwitch(
        value: widget.element.asBool(),
        onChanged: (val) async {
          if (!(widget.event?.shared ?? false)) {
            if (val && widget.element.count < widget.element.max!())
              widget.element.count = 1;
            else
              widget.element.count = 0;
          }
          widget.onPressed();
          if (widget.path != null)
            await widget.event
                ?.getRef()
                ?.child(widget.path!)
                .runTransaction((mutableData) {
              if (widget.isTargetScore) {
                mutableData.value['targetScore'][widget.opModeType?.toRep()]
                        [widget.element.key] =
                    val
                        ? (widget.element.count < widget.element.max!() ? 1 : 0)
                        : 0;
                return mutableData;
              }
              final scoreIndex = widget.score?.id;
              mutableData.value['scores'][scoreIndex]
                      [widget.opModeType?.toRep()][widget.element.key] =
                  val
                      ? (widget.element.count < widget.element.max!() ? 1 : 0)
                      : 0;
              return mutableData;
            });
        },
      );
  Row buildIncrementor() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RawMaterialButton(
            onLongPress: widget.element.count > widget.element.min!()
                ? () {
                    showPlatformDialog(
                      context: context,
                      builder: (context) => PlatformAlert(
                        title: Text("Reset Field"),
                        content: Text("Are you sure?"),
                        actions: [
                          PlatformDialogAction(
                            child: Text("Cancel"),
                            onPressed: () => Navigator.pop(context),
                          ),
                          PlatformDialogAction(
                            child: Text("Confirm"),
                            isDestructive: true,
                            onPressed: () async {
                              if (!(widget.event?.shared ?? false)) {
                                setState(() => widget.element.count =
                                    widget.element.min!());
                                if (widget.onDecrement != null)
                                  widget.onDecrement!();
                              }
                              widget.onPressed();
                              if (widget.path != null)
                                await widget.event
                                    ?.getRef()
                                    ?.child(widget.path!)
                                    .runTransaction(
                                  (mutableData) {
                                    if (widget.mutableDecrement != null) {
                                      return widget
                                          .mutableDecrement!(mutableData);
                                    }
                                    if (widget.isTargetScore) {
                                      mutableData.value['targetScore']
                                                  [widget.opModeType?.toRep()]
                                              [widget.element.key] =
                                          widget.element.min!();
                                      return mutableData;
                                    }
                                    final scoreIndex = widget.score?.id;
                                    mutableData.value['scores'][scoreIndex]
                                                [widget.opModeType?.toRep()]
                                            [widget.element.key] =
                                        widget.element.min!();
                                    return mutableData;
                                  },
                                );
                              Navigator.pop(context);
                            },
                          )
                        ],
                      ),
                    );
                  }
                : null,
            onPressed: widget.element.count > widget.element.min!()
                ? () async {
                    if (!(widget.event?.shared ?? false)) {
                      setState(widget.element.decrement);
                      if (widget.onDecrement != null) widget.onDecrement!();
                    }
                    widget.onPressed();
                    if (widget.path != null)
                      await widget.event
                          ?.getRef()
                          ?.child(widget.path!)
                          .runTransaction(
                        (mutableData) {
                          if (widget.mutableDecrement != null) {
                            return widget.mutableDecrement!(mutableData);
                          }
                          if (widget.isTargetScore) {
                            var ref = mutableData.value['targetScore']
                                    [widget.opModeType?.toRep()]
                                [widget.element.key];
                            if (ref > widget.element.min!())
                              mutableData.value['targetScore']
                                          [widget.opModeType?.toRep()]
                                      [widget.element.key] =
                                  (ref ?? 0) - widget.element.decrementValue;
                            return mutableData;
                          }
                          final scoreIndex = widget.score?.id;
                          var ref = mutableData.value['scores'][scoreIndex]
                              [widget.opModeType?.toRep()][widget.element.key];
                          if (ref > widget.element.min!())
                            mutableData.value['scores'][scoreIndex]
                                        [widget.opModeType?.toRep()]
                                    [widget.element.key] =
                                (ref ?? 0) - widget.element.decrementValue;
                          return mutableData;
                        },
                      );
                  }
                : null,
            elevation: 2.0,
            fillColor: Theme.of(context).canvasColor,
            splashColor: Colors.red,
            child: Icon(Icons.remove_circle_outline_rounded),
            shape: CircleBorder(),
          ),
          SizedBox(
            width: 20,
            child: Text(
              widget.element.count.toString(),
              textAlign: TextAlign.center,
            ),
          ),
          RawMaterialButton(
            onPressed: widget.element.count < widget.element.max!()
                ? () async {
                    if (!(widget.event?.shared ?? false)) {
                      widget.element.increment();
                      if (widget.onIncrement != null) widget.onIncrement!();
                    }
                    widget.onPressed();
                    if (widget.path != null)
                      await widget.event
                          ?.getRef()
                          ?.child(widget.path!)
                          .runTransaction(
                        (mutableData) {
                          if (widget.mutableIncrement != null) {
                            return widget.mutableIncrement!(mutableData);
                          }
                          if (widget.isTargetScore) {
                            var ref = mutableData.value['targetScore']
                                    [widget.opModeType?.toRep()]
                                [widget.element.key];
                            if (ref < widget.element.max!())
                              mutableData.value['targetScore']
                                          [widget.opModeType?.toRep()]
                                      [widget.element.key] =
                                  (ref ?? 0) + widget.element.incrementValue;
                            return mutableData;
                          }
                          final scoreIndex = widget.score?.id;
                          var ref = mutableData.value['scores'][scoreIndex]
                              [widget.opModeType?.toRep()][widget.element.key];
                          if (ref < widget.element.max!())
                            mutableData.value['scores'][scoreIndex]
                                        [widget.opModeType?.toRep()]
                                    [widget.element.key] =
                                (ref ?? 0) + widget.element.incrementValue;
                          return mutableData;
                        },
                      );
                  }
                : null,
            elevation: 2.0,
            fillColor: Theme.of(context).canvasColor,
            splashColor: Colors.green,
            child: Icon(Icons.add_circle_outline_rounded),
            shape: CircleBorder(),
          ),
        ],
      );
  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: widget.element.id == null
                ? Row(
                    children: [
                      Text(widget.element.name),
                      Spacer(),
                      if (!widget.element.isBool)
                        buildIncrementor()
                      else
                        buildSwitch()
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(widget.element.name),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: buildPicker(),
                        )
                      ],
                    ),
                  ),
          ),
          Divider(
            height: 3,
            thickness: 2,
          ),
        ],
      ),
    );
  }
}

class ScoreCard extends StatelessWidget {
  ScoreCard(
      {Key? key,
      required this.scoreDivisions,
      required this.dice,
      required this.team,
      required this.event,
      this.type,
      required this.removeOutliers,
      this.matches,
      required this.matchTotal})
      : super(key: key) {
    switch (type) {
      case OpModeType.auto:
        targetScore = team.targetScore?.autoScore;
        break;
      case OpModeType.tele:
        targetScore = team.targetScore?.teleScore;
        break;
      case OpModeType.endgame:
        targetScore = team.targetScore?.endgameScore;
        break;
      default:
        targetScore = team.targetScore;
        break;
    }
  }
  final List<ScoreDivision> scoreDivisions;
  final Dice dice;
  final Team team;
  final Event event;
  final bool matchTotal;
  final OpModeType? type;
  ScoreDivision? targetScore;
  final bool removeOutliers;
  final List<Match>? matches;
  @override
  Widget build(BuildContext context) {
    final allianceTotals = matches
        ?.where(
          (match) => match.dice == dice || dice == Dice.none,
        )
        .toList()
        .spots(team, dice, false, type: type)
        .removeOutliers(removeOutliers)
        .map((spot) => spot.y);
    final diceMatches = matches?.where(
          (match) => match.dice == dice || dice == Dice.none,
        ) ??
        [];
    final redAlliances =
        diceMatches.map((match) => match.red).whereType<Alliance>();
    final blueAlliances = diceMatches.map((e) => e.blue).whereType<Alliance>();
    final allAlliances = redAlliances;
    allAlliances.toList().addAll(blueAlliances);
    final allAllianceTotals = allAlliances
        .map((alliance) => alliance.allianceTotal(false, type: type).toDouble())
        .toList();
    return CardView(
      isActive: scoreDivisions.diceScores(dice).length >= 1,
      child: Padding(
        padding: EdgeInsets.only(left: 5, right: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BarGraph(
              val: !matchTotal
                  ? scoreDivisions.meanScore(dice, removeOutliers)
                  : allianceTotals?.mean() ?? 0,
              max: !matchTotal
                  ? event.teams.maxMeanScore(dice, removeOutliers, type)
                  : allAllianceTotals.mean(),
              title: 'Mean',
            ),
            BarGraph(
              val: !matchTotal
                  ? scoreDivisions.medianScore(dice, removeOutliers)
                  : allianceTotals?.median() ?? 0,
              max: !matchTotal
                  ? event.teams.maxMedianScore(dice, removeOutliers, type)
                  : allAllianceTotals.median(),
              title: 'Median',
            ),
            BarGraph(
              val: !matchTotal
                  ? scoreDivisions.maxScore(dice, removeOutliers)
                  : allianceTotals?.maxValue() ?? 0,
              max: !matchTotal
                  ? event.teams.maxScore(dice, removeOutliers, type)
                  : allAllianceTotals.maxValue(),
              title: 'Best',
            ),
            BarGraph(
              val: !matchTotal
                  ? scoreDivisions.standardDeviationScore(dice, removeOutliers)
                  : allianceTotals?.standardDeviation() ?? 0,
              max: !matchTotal
                  ? event.teams
                      .lowestStandardDeviationScore(dice, removeOutliers, type)
                  : event
                      .getMatchLists()
                      .map(
                        (matches) => matches.item2
                            .where(
                              (match) =>
                                  match.dice == dice || dice == Dice.none,
                            )
                            .toList()
                            .spots(matches.item1, dice, false, type: type)
                            .removeOutliers(removeOutliers)
                            .map((spot) => spot.y)
                            .standardDeviation(),
                      )
                      .minValue(),
              inverted: true,
              title: 'Deviation',
            ),
          ],
        ),
      ),
      collapsed: scoreDivisions
                  .diceScores(dice)
                  .map((score) => score.total())
                  .removeOutliers(removeOutliers)
                  .length >=
              1
          ? AspectRatio(
              aspectRatio: 2,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(18),
                  ),
                  color: Color(0xff232d37),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      right: 50.0, left: 12.0, top: 24, bottom: 12),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: value % 10 == 0
                                ? Color(0xff37434d)
                                : Colors.transparent,
                            strokeWidth: value % 10 == 0 ? 1 : 0,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: const Color(0xff37434d),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTextStyles: (value) => const TextStyle(
                              color: Color(0xff68737d), fontSize: 10),
                          getTitles: (value) {
                            return (value + 1).toInt().toString();
                          },
                          margin: 8,
                        ),
                        leftTitles: SideTitles(
                          showTitles: true,
                          getTextStyles: (value) => const TextStyle(
                            color: Color(0xff67727d),
                            fontSize: 15,
                          ),
                          getTitles: (value) {
                            if (value % 30 == 0) {
                              return value.toInt().toString();
                            }
                            return '';
                          },
                          reservedSize: 28,
                          margin: 12,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                            color: const Color(0xff37434d), width: 1),
                      ),

                      // minX: 0,
                      // maxX: team.scores
                      //         .where((e) =>
                      //             dice != Dice.none ? e.dice == dice : true)
                      //         .length
                      //         .toDouble() -
                      //     1,
                      minY: [
                        scoreDivisions.minScore(dice, removeOutliers),
                        targetScore?.total().toDouble() ?? 0.0
                      ].reduce(min),
                      // maxY: [
                      //   scoreDivisions.maxScore(dice, removeOutliers),
                      //   targetScore?.total().toDouble() ?? 0.0
                      // ].reduce(max),
                      lineBarsData: [
                        if (matches != null)
                          LineChartBarData(
                            belowBarData: team.targetScore != null
                                ? BarAreaData(
                                    show: true,
                                    colors: [
                                      Colors.lightGreenAccent.withOpacity(0.5)
                                    ],
                                    cutOffY: targetScore?.total().toDouble(),
                                    applyCutOffY: true,
                                  )
                                : null,
                            aboveBarData: team.targetScore != null
                                ? BarAreaData(
                                    show: true,
                                    colors: [Colors.redAccent.withOpacity(0.5)],
                                    cutOffY: targetScore?.total().toDouble(),
                                    applyCutOffY: true,
                                  )
                                : null,
                            spots: matches
                                ?.where(
                                  (e) => e.dice == dice || dice == Dice.none,
                                )
                                .toList()
                                .spots(team, dice, false, type: type)
                                .removeOutliers(removeOutliers),
                            colors: [
                              Color.fromRGBO(255, 166, 0, 1),
                            ],
                            isCurved: true,
                            preventCurveOverShooting: true,
                            barWidth: 5,
                          ),
                        LineChartBarData(
                          belowBarData: team.targetScore != null
                              ? BarAreaData(
                                  show: true,
                                  colors: [
                                    Colors.lightGreenAccent.withOpacity(0.5)
                                  ],
                                  cutOffY: targetScore?.total().toDouble(),
                                  applyCutOffY: true,
                                )
                              : null,
                          aboveBarData: team.targetScore != null
                              ? BarAreaData(
                                  show: true,
                                  colors: [Colors.redAccent.withOpacity(0.5)],
                                  cutOffY: targetScore?.total().toDouble(),
                                  applyCutOffY: true,
                                )
                              : null,
                          spots: scoreDivisions
                              .diceScores(dice)
                              .spots()
                              .removeOutliers(removeOutliers),
                          colors: [type.getColor()],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Text(''),
    );
  }
}
