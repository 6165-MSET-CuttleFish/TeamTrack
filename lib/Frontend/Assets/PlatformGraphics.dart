import 'dart:math';
import 'package:firebase_database/firebase_database.dart' as Db;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:teamtrack/score.dart';
import 'package:teamtrack/backend.dart';
import 'package:teamtrack/Frontend/Assets/BarGraph.dart';
import 'package:teamtrack/Frontend/Assets/CardView.dart';
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

void showPlatformDialog({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
}) {
  if (NewPlatform.isIOS()) {
    showCupertinoDialog(
        context: context, builder: builder, barrierDismissible: false);
  } else {
    showDialog(context: context, builder: builder, barrierDismissible: false);
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

class PlatformProgressIndicator extends PlatformWidget<
    CupertinoActivityIndicator, CircularProgressIndicator> {
  @override
  CupertinoActivityIndicator buildCupertinoWidget(BuildContext context) =>
      CupertinoActivityIndicator();

  @override
  CircularProgressIndicator buildMaterialWidget(BuildContext context) =>
      CircularProgressIndicator();
}

class PlatformDatePicker
    extends PlatformWidget<CupertinoDatePicker, CalendarDatePicker> {
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
    this.team,
    this.event,
    this.score,
    this.opModeType,
    this.isTargetScore = false,
  }) : super(key: key);
  final ScoringElement element;
  final void Function() onPressed;
  final void Function()? onIncrement;
  final void Function()? onDecrement;
  final Color? backgroundColor;
  final Team? team;
  final Event? event;
  final Score? score;
  final OpModeType? opModeType;
  final bool isTargetScore;
  @override
  State<StatefulWidget> createState() => _Incrementor();
}

class _Incrementor extends State<Incrementor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Column(
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
                        ? () async {
                            if (!(widget.event?.shared ?? false))
                              setState(widget.element.decrement);
                            widget.onPressed();
                            await widget.event
                                ?.getRef()
                                ?.runTransaction((mutableData) async {
                              var teamIndex;
                              try {
                                mutableData.value['teams'] as Map;
                                teamIndex = widget.team?.number;
                              } catch (e) {
                                teamIndex =
                                    int.parse(widget.team?.number ?? '');
                              }
                              if (widget.isTargetScore) {
                                var ref = mutableData.value['teams'][teamIndex]
                                            ['targetScore']
                                        [widget.opModeType?.toRep()]
                                    [widget.element.key];
                                if (ref > widget.element.min!())
                                  mutableData.value['teams'][teamIndex]
                                                  ['targetScore']
                                              [widget.opModeType?.toRep()]
                                          [widget.element.key] =
                                      (ref ?? 0) -
                                          widget.element.decrementValue;
                                return mutableData;
                              }
                              final scoreIndex = widget.score?.id;
                              var ref = mutableData.value['teams'][teamIndex]
                                          ['scores'][scoreIndex]
                                      [widget.opModeType?.toRep()]
                                  [widget.element.key];
                              if (ref > widget.element.min!())
                                mutableData.value['teams'][teamIndex]['scores']
                                                [scoreIndex]
                                            [widget.opModeType?.toRep()]
                                        [widget.element.key] =
                                    (ref ?? 0) - widget.element.decrementValue;
                              return mutableData;
                            });
                            if (widget.onDecrement != null)
                              widget.onDecrement!();
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
                        ? () async {
                            widget.onPressed();
                            await widget.event
                                ?.getRef()
                                ?.runTransaction((mutableData) async {
                              var teamIndex;
                              try {
                                mutableData.value['teams'] as Map;
                                teamIndex = widget.team?.number;
                              } catch (e) {
                                teamIndex =
                                    int.parse(widget.team?.number ?? '');
                              }
                              if (widget.isTargetScore) {
                                var ref = mutableData.value['teams'][teamIndex]
                                            ['targetScore']
                                        [widget.opModeType?.toRep()]
                                    [widget.element.key];
                                if (ref < widget.element.max!())
                                  mutableData.value['teams'][teamIndex]
                                                  ['targetScore']
                                              [widget.opModeType?.toRep()]
                                          [widget.element.key] =
                                      (ref ?? 0) +
                                          widget.element.incrementValue;
                                return mutableData;
                              }
                              final scoreIndex = widget.score?.id;
                              var ref = mutableData.value['teams'][teamIndex]
                                          ['scores'][scoreIndex]
                                      [widget.opModeType?.toRep()]
                                  [widget.element.key];
                              if (ref < widget.element.max!())
                                mutableData.value['teams'][teamIndex]['scores']
                                                [scoreIndex]
                                            [widget.opModeType?.toRep()]
                                        [widget.element.key] =
                                    (ref ?? 0) + widget.element.incrementValue;
                              return mutableData;
                            });
                            if (!(widget.event?.shared ?? false))
                              widget.element.increment();
                            if (widget.onIncrement != null)
                              widget.onIncrement!();
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
                    onChanged: (val) async {
                      if (!(widget.event?.shared ?? false)) {
                        if (val)
                          widget.element.count = 1;
                        else
                          widget.element.count = 0;
                      }
                      widget.onPressed();
                      await widget.event
                          ?.getRef()
                          ?.runTransaction((mutableData) async {
                        var teamIndex;
                        try {
                          mutableData.value['teams'] as Map;
                          teamIndex = widget.team?.number;
                        } catch (e) {
                          teamIndex = int.parse(widget.team?.number ?? '');
                        }
                        if (widget.isTargetScore &&
                            (mutableData.value['teams'] as Map)
                                .containsKey(widget.team?.number)) {
                          mutableData.value['teams'][teamIndex]['targetScore']
                                  [widget.opModeType?.toRep()]
                              [widget.element.key] = val ? 1 : 0;
                          return mutableData;
                        }
                        final scoreIndex = widget.score?.id;
                        mutableData.value['teams'][teamIndex]['scores']
                                [scoreIndex][widget.opModeType?.toRep()]
                            [widget.element.key] = val ? 1 : 0;
                        return mutableData;
                      });
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
      ),
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
    this.type,
    required this.removeOutliers,
    this.matches,
  }) : super(key: key) {
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
  final OpModeType? type;
  ScoreDivision? targetScore;
  final bool removeOutliers;
  final List<Match>? matches;
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
              max: event.teams.maxScore(dice, removeOutliers, type),
              title: 'Average',
            ),
            BarGraph(
                val: scoreDivisions.maxScore(dice, removeOutliers),
                max: event.teams.maxScore(dice, removeOutliers, type),
                title: 'Best Score'),
            BarGraph(
              val: scoreDivisions.standardDeviationScore(dice, removeOutliers),
              max: event.teams
                  .lowestStandardDeviationScore(dice, removeOutliers, type),
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
                            spots: matches!
                                .where(
                                    (e) => e.dice == dice || dice == Dice.none)
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
