import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:teamtrack/score.dart';
import 'package:teamtrack/backend.dart';
import 'package:teamtrack/Frontend/Assets/BarGraph.dart';
import 'package:teamtrack/Frontend/Assets/CardView.dart';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
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

void showPlatformDialog(
    {BuildContext? context, Widget Function(BuildContext)? builder}) {
  if (NewPlatform.isIOS()) {
    showCupertinoDialog(
        context: context!, builder: builder!, barrierDismissible: false);
  } else {
    showDialog(context: context!, builder: builder!, barrierDismissible: false);
  }
}

PageRoute platformPageRoute(Widget Function(BuildContext) builder) {
  if (NewPlatform.isIOS()) {
    return CupertinoPageRoute(builder: builder);
  }
  return MaterialPageRoute(builder: builder);
}

abstract class PlatformWidget<C extends Widget, M extends Widget>
    extends StatelessWidget {
  PlatformWidget({Key? key}) : super(key: key);

  C buildCupertinoWidget(BuildContext context);
  M buildMaterialWidget(BuildContext context);
  @override
  Widget build(BuildContext context) {
    try {
      if (NewPlatform.isIOS()) {
        return buildCupertinoWidget(context);
      } else {
        return buildMaterialWidget(context);
      }
    } catch (e) {
      return buildMaterialWidget(context);
    }
  }
}

class PlatformSwitch extends PlatformWidget<CupertinoSwitch, Switch> {
  PlatformSwitch(
      {Key? key,
      required this.value,
      required this.onChanged,
      this.highlightColor})
      : super(key: key);
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? highlightColor;
  @override
  CupertinoSwitch buildCupertinoWidget(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: highlightColor ?? Theme.of(context).accentColor,
    );
  }

  @override
  Switch buildMaterialWidget(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: highlightColor ?? Theme.of(context).accentColor,
    );
  }
}

class PlatformAlert extends PlatformWidget<CupertinoAlertDialog, AlertDialog> {
  PlatformAlert({Key? key, this.title, this.content, this.actions})
      : super(key: key);
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
    extends PlatformWidget<CupertinoTextField, TextFormField> {
  PlatformTextField(
      {Key? key,
      this.onChanged,
      this.keyboardType,
      this.textCapitalization = TextCapitalization.none,
      this.placeholder,
      this.obscureText = false,
      this.controller})
      : super(key: key);
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? placeholder;
  final bool obscureText;
  final TextEditingController? controller;
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
    );
  }
}

class PlatformDialogAction
    extends PlatformWidget<CupertinoDialogAction, TextButton> {
  PlatformDialogAction(
      {Key? key,
      this.child,
      this.isDefaultAction = false,
      this.onPressed,
      this.isDestructive = false})
      : super(key: key);
  final Widget? child;
  final bool isDefaultAction;
  final void Function()? onPressed;
  final bool isDestructive;
  @override
  CupertinoDialogAction buildCupertinoWidget(BuildContext context) {
    return CupertinoDialogAction(
      //textStyle: TextStyle(color: Theme.of(context).textTheme.bodyText2.color),
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

class PlatformButton extends PlatformWidget<CupertinoButton, OutlinedButton> {
  PlatformButton(
      {Key? key,
      required this.child,
      this.onPressed,
      this.disabledColor = Colors.transparent,
      this.color})
      : super(key: key);
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

class Incrementor extends StatefulWidget {
  Incrementor({Key? key, required this.element, required this.onPressed})
      : super(key: key);
  final ScoringElement element;
  final Function onPressed;
  @override
  State<StatefulWidget> createState() => _Incrementor();
}

class _Incrementor extends State<Incrementor> {
  _Incrementor();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Row(
            children: [
              Text(widget.element.name),
              Spacer(),
              if (!widget.element.isBool)
                RawMaterialButton(
                  onPressed: widget.element.count > widget.element.min!()
                      ? () {
                          setState(widget.element.decrement);
                          widget.onPressed();
                        }
                      : null,
                  elevation: 2.0,
                  fillColor: Theme.of(context).canvasColor,
                  splashColor: Colors.red,
                  child: Icon(Icons.remove_circle_outline_rounded),
                  shape: CircleBorder(),
                ),
              if (!widget.element.isBool)
                SizedBox(
                  width: 20,
                  child: Text(
                    widget.element.count.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!widget.element.isBool)
                RawMaterialButton(
                  onPressed: widget.element.count < widget.element.max!()
                      ? () {
                          setState(widget.element.increment);
                          widget.onPressed();
                        }
                      : null,
                  elevation: 2.0,
                  fillColor: Theme.of(context).canvasColor,
                  splashColor: Colors.green,
                  child: Icon(Icons.add_circle_outline_rounded),
                  shape: CircleBorder(),
                )
              else
                PlatformSwitch(
                  value: widget.element.asBool(),
                  onChanged: (val) {
                    if (val)
                      widget.element.count = 1;
                    else
                      widget.element.count = 0;
                    widget.onPressed();
                  },
                )
            ],
          ),
        ),
        Divider(
          height: 3,
          thickness: 2,
        ),
      ],
    );
  }
}

class ScoreCard extends StatelessWidget {
  ScoreCard({
    Key? key,
    required this.scoreDivisions,
    required this.dice,
    required this.team,
    required this.event,
    required this.type,
    required this.removeOutliers,
  }) : super(key: key) {
    if (type == "auto") {
      targetScore = team.targetScore!.autoScore;
    } else if (type == "tele") {
      targetScore = team.targetScore!.teleScore;
    } else if (type == "endgame") {
      targetScore = team.targetScore!.endgameScore;
    } else {
      targetScore = team.targetScore;
    }
  }
  final List<ScoreDivision> scoreDivisions;
  final Dice dice;
  final Team team;
  final Event event;
  final String type;
  ScoreDivision? targetScore;
  final bool removeOutliers;
  @override
  Widget build(BuildContext context) {
    return CardView(
      isActive: scoreDivisions.diceScores(dice).length >= 1,
      child: Padding(
        padding: EdgeInsets.only(left: 5, right: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BarGraph(
              val: scoreDivisions.meanScore(dice, removeOutliers),
              max: event.teams.maxScoreVar(dice, type, removeOutliers),
              title: 'Average',
            ),
            BarGraph(
                val: scoreDivisions.maxScore(dice, removeOutliers),
                max: event.teams.maxScoreVar(dice, type, removeOutliers),
                title: 'Best Score'),
            BarGraph(
              val: scoreDivisions.standardDeviationScore(dice, removeOutliers),
              max: event.teams
                  .lowestStandardDeviationVar(dice, type, removeOutliers),
              inverted: true,
              title: 'Deviation',
            ),
          ],
        ),
      ),
      collapsed: scoreDivisions
                  .diceScores(dice)
                  .map((e) => e.total())
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
                      minX: 0,
                      maxX: team.scores
                              .where((e) =>
                                  dice != Dice.none ? e.dice == dice : true)
                              .length
                              .toDouble() -
                          1,
                      minY: [
                        scoreDivisions.minScore(dice, removeOutliers),
                        targetScore!.total().toDouble()
                      ].reduce(min),
                      maxY: [
                        scoreDivisions.maxScore(dice, removeOutliers),
                        team.targetScore != null
                            ? targetScore!.total().toDouble()
                            : 0.0
                      ].reduce(max),
                      lineBarsData: [
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
                          colors: [Colors.orange],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                          shadow: Shadow(color: Colors.green, blurRadius: 5),
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
