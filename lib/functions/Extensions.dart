import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/ScoreModel.dart';

extension ObjectExt<T> on T {
  R let<R>(R Function(T that) op) => op(this);
}

extension RoleExtension on Role {
  // getter for showing to the user
  String name() {
    switch (this) {
      case Role.viewer:
        return 'Viewer';
      case Role.editor:
        return 'Editor';
      case Role.admin:
        return 'Admin';
    }
  }

  // for firebase
  String toRep() {
    switch (this) {
      case Role.viewer:
        return 'viewer';
      case Role.editor:
        return 'editor';
      case Role.admin:
        return 'admin';
    }
  }

  // icon for showing to the user
  Icon getIcon({Color? color, double? size = 14}) {
    switch (this) {
      case Role.viewer:
        return Icon(
          Icons.visibility,
          color: color,
          size: size,
        );
      case Role.editor:
        return Icon(
          Icons.edit,
          color: color,
          size: size,
        );
      default:
        return Icon(
          Icons.admin_panel_settings,
          color: color,
          size: size,
        );
    }
  }
}

extension ExTeam on Team? {
  bool equals(Team? other) => this?.number == other?.number;
}

extension MergeExt on List<ScoringElement> {
  List<ScoringElement> parse({bool putNone = true}) {
    List<ScoringElement> newList = [];
    Map<String, ScoringElement> conglomerates = {};
    for (ScoringElement element in this) {
      if (element.id == null) {
        newList.add(element);
      } else {
        conglomerates.putIfAbsent(
          element.id!,
          () => ScoringElement(
            id: element.id,
            value: 0,
            key: element.id,
            name: element.id ?? "",
            nestedElements: [
              if (putNone)
                ScoringElement(
                  name: "None",
                  value: 0,
                ),
            ],
          ),
        );
        final bigElement = conglomerates[element.id!];
        bigElement?.nestedElements?.add(element);
        bigElement?.normalCount += element.normalCount;
        bigElement?.normalMisses += element.normalMisses;
        bigElement?.isBool = element.isBool;
        bigElement?.totalValue =
            (bigElement.totalValue ?? 0) + element.scoreValue();
      }
    }
    for (ScoringElement element in conglomerates.values) {
      for (int i = 0; i < (element.nestedElements?.length ?? 0); i++) {
        if (element.nestedElements?[i].normalMisses == 1 && element.isBool) {
          element.normalMisses = 1;
        }
        if (element.nestedElements?[i].normalCount == 1 && element.isBool) {
          element.normalCount = i;
        } else if (!(conglomerates[element.id!]?.isBool ?? true)) {
          conglomerates[element.id!]
              ?.nestedElements
              ?.removeWhere((element) => element.id == null);
        }
      }
      newList.add(element);
    }
    return newList;
  }
}

extension TimestampExt on Timestamp {
  Map<String, dynamic> toJson() {
    return {
      'seconds': this.seconds,
      'nanoseconds': this.nanoseconds,
    };
  }
}

extension opModeExt on OpModeType? {
  Color getColor() {
    switch (this) {
      case OpModeType.auto:
        return Colors.green;
      case OpModeType.tele:
        return Colors.blue;
      case OpModeType.endgame:
        return Colors.orange;
      case OpModeType.penalty:
        return Colors.red;
      default:
        return Color.fromRGBO(230, 30, 213, 1);
    }
  }

  String getName({bool shortened = false}) {
    if (shortened) {
      switch (this) {
        case OpModeType.auto:
          return 'Auto';
        case OpModeType.tele:
          return 'Tele';
        case OpModeType.endgame:
          return 'End';
        case OpModeType.penalty:
          return 'Pen';
        default:
          return 'Total';
      }
    }
    switch (this) {
      case OpModeType.auto:
        return 'Autonomous';
      case OpModeType.tele:
        return 'Tele-Op';
      case OpModeType.endgame:
        return 'Endgame';
      case OpModeType.penalty:
        return 'Penalty';
      default:
        return 'Total';
    }
  }

  static List<OpModeType?> getAll() => [null, ...OpModeType.values];

  static List<OpModeType> getMain() =>
      [OpModeType.auto, OpModeType.tele, OpModeType.endgame];

  bool getLessIsBetter() => this == OpModeType.penalty ? true : false;
}

extension eventTypeExt on EventType {
  Icon getIcon({bool filled = true}) => this == EventType.local
      ? Icon(filled ? CupertinoIcons.person_3_fill : CupertinoIcons.person_3)
      : Icon(filled
          ? CupertinoIcons.rectangle_stack_person_crop_fill
          : CupertinoIcons.rectangle_stack_person_crop);

  String getName({bool filled = true}) =>
      this == EventType.local ? 'In-Person Event' : 'Remote Event';
}

extension StrExt on String {
  // return new string with spaces added before capital letters
  String spaceBeforeCapital() {
    var returnString = "";
    for (var i = 0; i < this.length; i++) {
      var currentChar = this[i];
      if (currentChar.toUpperCase() == currentChar && i != 0) {
        returnString += " ";
      }
      returnString += currentChar;
    }
    return returnString;
  }
}

extension extOp on OpModeType {
  String toRep() {
    switch (this) {
      case OpModeType.auto:
        return 'AutoScore';
      case OpModeType.tele:
        return 'TeleScore';
      case OpModeType.endgame:
        return 'EndgameScore';
      default:
        return 'Penalty';
    }
  }

  String toVal() {
    switch (this) {
      case OpModeType.auto:
        return 'Autonomous';
      case OpModeType.tele:
        return 'Tele-Op';
      case OpModeType.endgame:
        return 'Endgame';
      default:
        return 'Penalty';
    }
  }
}

extension DiceExtension on Dice {
  String toVal(String gameName) {
    final skeleton = json.decode(
      remoteConfig.getString(
        gameName,
      ),
    );
    var dice = skeleton["Dice"];
    switch (this) {
      case Dice.one:
        return dice['1'];
      case Dice.two:
        return dice['2'];
      case Dice.three:
        return dice['3'];
      default:
        return 'All Cases';
    }
  }
}
