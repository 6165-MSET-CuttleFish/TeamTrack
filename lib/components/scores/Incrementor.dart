import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/statistics/BarGraph.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';

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
    this.mutableIncrement,
    this.mutableDecrement,
    this.path,
    this.max = 0,
  }) : super(key: key);
  final ScoringElement element;
  final void Function() onPressed;
  final void Function(ScoringElement)? onIncrement, onDecrement;
  final void Function(Object?, ScoringElement)? mutableIncrement,
      mutableDecrement;
  final Color? backgroundColor;
  final Event? event;
  final Score? score;
  final String? path;
  final double max;
  @override
  State<StatefulWidget> createState() => _Incrementor();
}

class _Incrementor extends State<Incrementor> {
  CupertinoSegmentedControl buildPicker() => CupertinoSegmentedControl<int>(
        groupValue: widget.element.didAttempt() ? widget.element.count : null,
        children: widget.element.nestedElements?.asMap().map(
                  (key, value) => MapEntry(
                    key,
                    Text(
                      value.name,
                      style: TextStyle(
                        color: value.misses != 0 ? Colors.red : null,
                      ),
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
              widget.element.nestedElements?[i].misses = 0;
            }
            widget.element.nestedElements?[val].count = 1;
            if (widget.element.count != 0) {
              widget.element.nestedElements?[widget.element.count].misses = 1;
            }
          }
          widget.onPressed();
          if (widget.path != null)
            await widget.event
                ?.getRef()
                ?.child(widget.path!)
                .runTransaction((mutableData) {
              for (int i = 1;
                  i < (widget.element.nestedElements?.length ?? 0);
                  i++) {
                var ref = (mutableData
                    as Map?)?[widget.element.nestedElements?[i].key];
                if (ref is Map) {
                  mutableData?[widget.element.nestedElements?[i].key] = {
                    'count': 0,
                    'misses': 0,
                  };
                } else {
                  mutableData?[widget.element.nestedElements?[i].key] = 0;
                }
              }
              if (widget.element.count != 0) {
                var ref = (mutableData as Map?)?[
                    widget.element.nestedElements?[widget.element.count].key];
                if (ref is Map) {
                  mutableData?[widget.element
                      .nestedElements?[widget.element.count].key]['misses'] = 1;
                }
              }
              if (val != 0) {
                var ref = (mutableData
                    as Map?)?[widget.element.nestedElements?[val].key];
                if (ref is Map) {
                  mutableData?[widget.element.nestedElements?[val].key]
                      ['count'] = 1;
                } else {
                  mutableData?[widget.element.nestedElements?[val].key] = 1;
                }
              }
              return Transaction.success(mutableData);
            });
        },
      );
  PlatformSwitch buildSwitch() => PlatformSwitch(
        value: widget.element.asBool(),
        onChanged: widget.event?.role != Role.viewer
            ? (val) async {
                if (!(widget.event?.shared ?? false)) {
                  if (val && widget.element.count < widget.element.max!()) {
                    widget.element.count = 1;
                    widget.element.misses = 0;
                  } else {
                    widget.element.count = 0;
                    widget.element.misses = 1;
                  }
                }
                widget.onPressed();
                if (widget.path != null)
                  await widget.event
                      ?.getRef()
                      ?.child(widget.path!)
                      .runTransaction((mutableData) {
                    var ref = (mutableData as Map?)?[widget.element.key];
                    if (ref is Map) {
                      mutableData?[widget.element.key]['count'] = val
                          ? (widget.element.count < widget.element.max!()
                              ? 1
                              : 0)
                          : 0;
                      mutableData?[widget.element.key]['misses'] =
                          mutableData[widget.element.key]['count'] ==
                                  widget.element.min!()
                              ? 1
                              : 0;
                    } else {
                      mutableData?[widget.element.key] = val
                          ? (widget.element.count < widget.element.max!()
                              ? 1
                              : 0)
                          : 0;
                    }
                    return Transaction.success(mutableData);
                  });
              }
            : null,
      );
  Row buildIncrementor() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RawMaterialButton(
            onLongPress: widget.event?.role != Role.viewer
                ? (widget.element.count > widget.element.min!()
                    ? () async {
                        if (!(widget.event?.shared ?? false)) {
                          widget.element.misses--;
                          setState(widget.element.decrement);
                          if (widget.onDecrement != null)
                            widget.onDecrement!(widget.element);
                        }
                        widget.onPressed();
                        if (widget.path != null)
                          await widget.event
                              ?.getRef()
                              ?.child(widget.path!)
                              .runTransaction(
                            (mutableData) {
                              if (widget.mutableDecrement != null) {
                                widget.mutableDecrement!(
                                    mutableData, widget.element);
                              }
                              var ref =
                                  (mutableData as Map?)?[widget.element.key];
                              if (ref is Map) {
                                if (ref['count'] > widget.element.min!())
                                  mutableData?[widget.element.key]['count'] =
                                      ref['count'] -
                                          widget.element.decrementValue;
                              } else {
                                if (ref > widget.element.min!())
                                  mutableData?[widget.element.key] =
                                      ref - widget.element.decrementValue;
                              }
                              return Transaction.success(mutableData);
                            },
                          );
                      }
                    : null)
                : null,
            onPressed: widget.event?.role != Role.viewer
                ? (widget.element.count > widget.element.min!()
                    ? () async {
                        if (!(widget.event?.shared ?? false)) {
                          setState(widget.element.decrement);
                          if (widget.onDecrement != null)
                            widget.onDecrement!(widget.element);
                        }
                        widget.onPressed();
                        if (widget.path != null)
                          await widget.event
                              ?.getRef()
                              ?.child(widget.path!)
                              .runTransaction(
                            (mutableData) {
                              if (widget.mutableDecrement != null) {
                                widget.mutableDecrement!(
                                    mutableData, widget.element);
                              }
                              var ref =
                                  (mutableData as Map?)?[widget.element.key];
                              if (ref is Map) {
                                if (ref['count'] > widget.element.min!()) {
                                  mutableData?[widget.element.key]['count'] =
                                      ref['count'] -
                                          widget.element.decrementValue;
                                  mutableData?[widget.element.key]['misses'] =
                                      ref['misses'] + 1;
                                }
                              } else {
                                if (ref > widget.element.min!()) {
                                  mutableData?[widget.element.key] =
                                      ref - widget.element.decrementValue;
                                }
                              }
                              return Transaction.success(mutableData);
                            },
                          );
                      }
                    : null)
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
            onPressed: widget.event?.role != Role.viewer
                ? (widget.element.count < widget.element.max!()
                    ? () async {
                        if (!(widget.event?.shared ?? false)) {
                          widget.element.increment();
                          if (widget.onIncrement != null)
                            widget.onIncrement!(widget.element);
                        }
                        widget.onPressed();
                        if (widget.path != null)
                          await widget.event
                              ?.getRef()
                              ?.child(widget.path!)
                              .runTransaction(
                            (mutableData) {
                              if (widget.mutableIncrement != null) {
                                widget.mutableIncrement!(
                                    mutableData, widget.element);
                              }
                              var ref =
                                  (mutableData as Map?)?[widget.element.key];
                              if (ref is Map) {
                                if (ref['count'] < widget.element.max!())
                                  mutableData?[widget.element.key]['count'] =
                                      ref['count'] +
                                          widget.element.incrementValue;
                              } else {
                                if (ref < widget.element.max!())
                                  mutableData?[widget.element.key] =
                                      ref + widget.element.incrementValue;
                              }
                              return Transaction.success(mutableData);
                            },
                          );
                      }
                    : null)
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
    return RawMaterialButton(
      onLongPress: widget.event?.role != Role.viewer &&
              (widget.element.count > widget.element.min!() ||
                  widget.element.misses > 0)
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
                          setState(() {
                            widget.element.count = widget.element.min!();
                            widget.element.misses = 0;
                          });
                          if (widget.onDecrement != null)
                            widget.onDecrement!(widget.element);
                        }
                        widget.onPressed();
                        if (widget.path != null)
                          await widget.event
                              ?.getRef()
                              ?.child(widget.path!)
                              .runTransaction(
                            (mutableData) {
                              if (widget.element.isBool &&
                                  widget.element.nestedElements != null) {
                                for (final nestedElement
                                    in widget.element.nestedElements!) {
                                  if (nestedElement.key != null) {
                                    final ref = (mutableData
                                        as Map?)?[nestedElement.key];
                                    if (ref is Map) {
                                      mutableData?[nestedElement.key]
                                          ['misses'] = 0;
                                      mutableData?[nestedElement.key]['count'] =
                                          0;
                                    } else {
                                      mutableData?[nestedElement.key] = 0;
                                    }
                                  }
                                }
                                return Transaction.success(mutableData);
                              }
                              final ref =
                                  (mutableData as Map?)?[widget.element.key];
                              if (ref is Map) {
                                mutableData?[widget.element.key] = {
                                  'count': widget.element.min!(),
                                  'misses': 0,
                                };
                              } else {
                                mutableData?[widget.element.key] =
                                    widget.element.min!();
                              }
                              return Transaction.success(mutableData);
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
      onPressed: widget.event?.role != Role.viewer
          ? (widget.element.misses > 0
              ? () => showPlatformDialog(
                    context: context,
                    builder: (_) => PlatformAlert(
                      title: Text('Reset Misses'),
                      content: Text('Are you sure?'),
                      actions: [
                        PlatformDialogAction(
                          child: Text('Cancel'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        PlatformDialogAction(
                          child: Text('Confirm'),
                          isDestructive: true,
                          onPressed: () async {
                            if (!(widget.event?.shared ?? false)) {
                              setState(() => widget.element.misses = 0);
                            }
                            widget.onPressed();
                            if (widget.path != null)
                              await widget.event
                                  ?.getRef()
                                  ?.child(widget.path!)
                                  .runTransaction((mutableData) {
                                if (widget.element.isBool &&
                                    widget.element.nestedElements != null) {
                                  for (final nestedElement
                                      in widget.element.nestedElements!) {
                                    if (nestedElement.key != null) {
                                      final ref = (mutableData
                                          as Map?)?[nestedElement.key];
                                      if (ref is Map) {
                                        mutableData?[nestedElement.key]
                                            ['misses'] = 0;
                                      }
                                    }
                                  }
                                  return Transaction.success(mutableData);
                                }
                                final ref =
                                    (mutableData as Map?)?[widget.element.key];
                                if (ref is Map) {
                                  mutableData?[widget.element.key]['misses'] =
                                      0;
                                }
                                return Transaction.success(mutableData);
                              });
                            Navigator.pop(context);
                          },
                        )
                      ],
                    ),
                  )
              : null)
          : null,
      child: Container(
        color: widget.element.nestedElements != null && !widget.element.isBool
            ? null
            : widget.backgroundColor == null
                ? widget.element.didAttempt()
                    ? CupertinoColors.activeOrange.withOpacity(0.3)
                    : null
                : widget.backgroundColor,
        child: Column(
          children: [
            if (!widget.element.isBool &&
                widget.element.id != null &&
                widget.element.nestedElements != null)
              ExpansionTile(
                title: Text(widget.element.name),
                initiallyExpanded: true,
                children: [
                  BarGraph(
                    val: widget.element.scoreValue().toDouble(),
                    max: widget.max,
                    vertical: false,
                    height: MediaQuery.of(context).size.width,
                    width: 4,
                    compressed: true,
                    showPercentage: false,
                  ),
                  ...widget.element.nestedElements!
                      .map(
                        (e) => Incrementor(
                          element: e,
                          onPressed: widget.onPressed,
                          path: widget.path,
                          event: widget.event,
                          onDecrement: widget.onDecrement,
                          onIncrement: widget.onIncrement,
                          mutableDecrement: widget.mutableDecrement,
                          mutableIncrement: widget.mutableIncrement,
                        ),
                      )
                      .toList()
                ],
              )
            else
              widget.element.nestedElements == null ||
                      (widget.element.nestedElements?.length ?? 0) == 0
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.element.name),
                                  if (widget.backgroundColor == null)
                                    Text(
                                      "Missed: ${widget.element.misses}",
                                      style:
                                          Theme.of(context).textTheme.caption,
                                    ),
                                ],
                              ),
                            ),
                            Spacer(),
                            if (!widget.element.isBool)
                              buildIncrementor()
                            else
                              buildSwitch()
                          ],
                        ),
                        if (widget.max != 0 && !widget.element.isBool)
                          BarGraph(
                            val: widget.element.scoreValue().toDouble(),
                            max: widget.max,
                            vertical: false,
                            height: MediaQuery.of(context).size.width,
                            width: 4,
                            compressed: true,
                            showPercentage: false,
                          ),
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
            Divider(
              height: 3,
              thickness: 2,
            ),
          ],
        ),
      ),
    );
  }
}
