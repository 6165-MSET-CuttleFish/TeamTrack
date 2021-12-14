import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
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
  }) : super(key: key);
  final ScoringElement element;
  final void Function() onPressed;
  final void Function()? onIncrement, onDecrement;
  final Transaction Function(Object?)? mutableIncrement,
      mutableDecrement;
  final Color? backgroundColor;
  final Event? event;
  final Score? score;
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
                    PlatformText(
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
              for (int i = 1;
                  i < (widget.element.nestedElements?.length ?? 0);
                  i++) {
                (mutableData as Map?)?[widget.element.nestedElements?[i].key] = 0;
              }
              if (val != 0)
                (mutableData as Map?)?[widget.element.nestedElements?[val].key] = 1;
              return Transaction.success(mutableData);
            });
        },
      );
  PlatformSwitch buildSwitch() => PlatformSwitch(
        value: widget.element.asBool(),
        onChanged: widget.event?.role != Role.viewer ? (val) async {
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
              (mutableData as Map?)?[widget.element.key] = val
                  ? (widget.element.count < widget.element.max!() ? 1 : 0)
                  : 0;
              return Transaction.success(mutableData);
            });
        } : null,
      );
  Row buildIncrementor() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RawMaterialButton(
            onLongPress: widget.event?.role != Role.viewer
                ? (widget.element.count > widget.element.min!()
                    ? () {
                        showPlatformDialog(
                          context: context,
                          builder: (context) => PlatformAlert(
                            title: PlatformText("Reset Field"),
                            content: PlatformText("Are you sure?"),
                            actions: [
                              PlatformDialogAction(
                                child: PlatformText("Cancel"),
                                onPressed: () => Navigator.pop(context),
                              ),
                              PlatformDialogAction(
                                child: PlatformText("Confirm"),
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
                                        (mutableData as Map?)?[widget.element.key] =
                                            widget.element.min!();
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
                    : null)
                : null,
            onPressed: widget.event?.role != Role.viewer
                ? (widget.element.count > widget.element.min!()
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
                              var ref = (mutableData as Map?)?[widget.element.key];
                              if (ref > widget.element.min!())
                                mutableData?[widget.element.key] =
                                    (ref ?? 0) - widget.element.decrementValue;
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
            child: PlatformText(
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
                              var ref = (mutableData as Map?)?[widget.element.key];
                              if (ref < widget.element.max!())
                                mutableData?[widget.element.key] =
                                    (ref ?? 0) + widget.element.incrementValue;
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
    return Container(
      color: widget.backgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: widget.element.id == null
                ? Row(
                    children: [
                      PlatformText(widget.element.name),
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
                          child: PlatformText(widget.element.name),
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
