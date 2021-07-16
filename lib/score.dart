import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teamtrack/backend.dart';

class Score extends ScoreDivision implements Comparable<Score> {
  TeleScore teleScore = TeleScore({});
  AutoScore autoScore = AutoScore({});
  EndgameScore endgameScore = EndgameScore({});
  Penalty penalties = Penalty();
  String id = '';
  late Dice dice;
  Score(this.id, this.dice, String gameName) {
    var ref = json.decode(remoteConfig.getValue(gameName).asString());
    teleScore = TeleScore(ref['TeleScore']);
    autoScore = AutoScore(ref['AutoScore']);
    endgameScore = EndgameScore(ref['EndgameScore']);
    penalties = Penalty();
    setDice(dice, Timestamp.now());
  }
  List<ScoringElement> getElements({bool? showPenalties}) => [
        ...teleScore.getElements(),
        ...autoScore.getElements(),
        ...endgameScore.getElements(),
        ...((showPenalties ?? false) ? penalties.getElements() : [])
      ];
  @override
  int total({bool? showPenalties}) => getElements(showPenalties: showPenalties)
      .map((e) => e.scoreValue())
      .reduce((value, element) => value + element)
      .clamp(0, 999);
  ScoreDivision getScoreDivision(OpModeType? type) {
    switch (type) {
      case OpModeType.auto:
        return autoScore;
      case OpModeType.tele:
        return teleScore;
      case OpModeType.endgame:
        return endgameScore;
      default:
        return this;
    }
  }

  @override
  Dice getDice() => dice;
  void setDice(Dice value, Timestamp time) {
    dice = value;
    autoScore.dice = value;
    teleScore.dice = value;
    endgameScore.dice = value;
    penalties.dice = value;
    timeStamp = time;
    autoScore.timeStamp = time;
    teleScore.timeStamp = time;
    endgameScore.timeStamp = time;
    penalties.timeStamp = time;
  }

  Score.fromJson(Map<String, dynamic> map, String gameName) {
    var ref = json.decode(remoteConfig.getValue(gameName).asString());
    autoScore = AutoScore.fromJson(map['AutoScore'], ref['AutoScore']);
    teleScore = TeleScore.fromJson(map['TeleScore'], ref['TeleScore']);
    endgameScore =
        EndgameScore.fromJson(map['EndgameScore'], ref['EndgameScore']);
    penalties = Penalty.fromJson(map['Penalty']);
    id = map['id'];
  }
  Map<String, dynamic> toJson() => {
        'AutoScore': autoScore.toJson(),
        'TeleScore': teleScore.toJson(),
        'EndgameScore': endgameScore.toJson(),
        'Penalty': penalties.toJson(),
        'id': id.toString(),
      };
  Score operator +(Score other) {
    var score = Score('', dice, Statics.gameName);
    score.autoScore = autoScore + other.autoScore;
    score.teleScore = teleScore + other.teleScore;
    score.endgameScore = endgameScore + other.endgameScore;
    score.penalties = penalties + other.penalties;
    return score;
  }

  @override
  int compareTo(Score other) => total().compareTo(other.total());
}

Dice getDiceFromString(String statusAsString) {
  for (Dice element in Dice.values) {
    if (element.toString() == statusAsString) {
      return element;
    }
  }
  return Dice.none;
}

EventType getTypeFromString(String statusAsString) {
  for (EventType element in EventType.values)
    if (element.toString() == statusAsString) return element;
  return EventType.remote;
}

extension scoreList on Map<String, Score> {
  void addScore(Score value) {
    this[value.id] = value;
  }
}

class AutoScore extends ScoreDivision {
  late Dice dice;
  Set keys = {};
  Map<String, ScoringElement> elements = Map();
  void setCount(String key, int n) {
    elements[key]?.count = n;
  }

  Map<String, dynamic> ref;
  List<ScoringElement> getElements() => elements.values.toList();
  Dice getDice() => dice;
  AutoScore(this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          min: () => ref[e]['min'] ?? 0,
          value: ref[e]['value'] ?? 1,
          isBool: ref[e]['isBool'] ?? false,
          key: e,
        );
      },
    );
    maxSet();
  }

  void maxSet() {
    ref.keys.forEach(
      (e) {
        if (ref[e]['maxIsReference'] ?? false) {
          int ceil = ref[e]['max']['total'];
          elements[e]?.max = () =>
              (ceil - (elements[ref[e]['max']['reference']]?.count ?? 0))
                  .toInt();
        } else {
          elements[e]?.max = () => ref[e]['max'];
        }
      },
    );
  }

  AutoScore operator +(AutoScore other) {
    var autoScore = AutoScore(ref);
    autoScore.elements.keys.forEach(
      (key) {
        autoScore.elements[key] = (elements[key] ?? ScoringElement()) +
            (other.elements[key] ?? ScoringElement());
      },
    );
    return autoScore;
  }

  AutoScore.fromJson(Map<String, dynamic> map, this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          count: map[e] ?? 0,
          min: () => ref[e]['min'] ?? 0,
          value: ref[e]['value'] ?? 1,
          isBool: ref[e]['isBool'] ?? false,
          key: e,
        );
      },
    );
    maxSet();
  }
  Map<String, dynamic> toJson() =>
      elements.map((key, value) => MapEntry(key, value.count));
}

class TeleScore extends ScoreDivision {
  late Dice dice;
  Map<String, ScoringElement> elements = Map();
  List<ScoringElement> getElements() => elements.values.toList();
  List<double> cycleTimes = [];
  int teleCycles = 0;
  int endgameCycles = 0;
  ScoringElement misses =
      ScoringElement(name: "Misses", value: 1, key: 'Misses');
  Dice getDice() => dice;
  Map<String, dynamic> ref;
  TeleScore(this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          min: () => ref[e]['min'] ?? 0,
          value: ref[e]['value'] ?? 1,
          isBool: ref[e]['isBool'] ?? false,
          key: e,
        );
      },
    );
    maxSet();
  }

  void maxSet() {
    ref.keys.forEach(
      (e) {
        if (ref[e]['maxIsReference'] ?? false) {
          int ceil = ref[e]['max']['total'];
          elements[e]?.max = () =>
              (ceil - (elements[ref[e]['max']['reference']]?.count ?? 0))
                  .toInt();
        } else {
          elements[e]?.max = () => ref[e]['max'];
        }
      },
    );
  }

  TeleScore operator +(TeleScore other) {
    var teleScore = TeleScore(ref);
    teleScore.dice = dice;
    teleScore.elements.keys.forEach(
      (key) {
        teleScore.elements[key] = (elements[key] ?? ScoringElement()) +
            (other.elements[key] ?? ScoringElement());
      },
    );
    return teleScore;
  }

  TeleScore.fromJson(Map<String, dynamic> map, this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          count: map[e] ?? 0,
          min: () => ref[e]['min'] ?? 0,
          value: ref[e]['value'] ?? 1,
          isBool: ref[e]['isBool'] ?? false,
          key: e,
        );
      },
    );
    try {
      cycleTimes = List<num>.from(json.decode(map['CycleTimes'].toString()))
          .map((e) => e.toDouble())
          .toList();
    } catch (e) {
      cycleTimes = [];
    }
    teleCycles = map['TeleCycles'] ?? 0;
    endgameCycles = map['EndgameCycles'] ?? 0;
    misses = ScoringElement(
        name: 'Misses', count: map['Misses'] ?? 0, key: 'Misses', value: 1);

    maxSet();
  }
  Map<String, dynamic> toJson() => {
        ...elements.map((key, value) => MapEntry(key, value.count)),
        'Misses': misses.count,
        'CycleTimes': json.encode(cycleTimes),
        'TeleCycles': teleCycles,
        'EndgameCycles': endgameCycles,
      };
}

class EndgameScore extends ScoreDivision {
  late Dice dice;
  Map<String, ScoringElement> elements = Map();
  List<ScoringElement> getElements() => elements.values.toList();
  Map<String, dynamic> ref;
  Dice getDice() => dice;
  EndgameScore(this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          min: () => ref[e]['min'] ?? 0,
          value: ref[e]['value'] ?? 1,
          isBool: ref[e]['isBool'] ?? false,
          key: e,
        );
      },
    );
    maxSet();
  }

  void maxSet() {
    ref.keys.forEach(
      (e) {
        if (ref[e]['maxIsReference'] ?? false) {
          int ceil = ref[e]['max']['total'];
          elements[e]?.max = () =>
              (ceil - (elements[ref[e]['max']['reference']]?.count ?? 0))
                  .toInt();
        } else {
          elements[e]?.max = () => ref[e]['max'];
        }
      },
    );
  }

  EndgameScore operator +(EndgameScore other) {
    var endgameScore = EndgameScore(ref);
    endgameScore.dice = dice;
    endgameScore.elements.keys.forEach(
      (key) {
        endgameScore.elements[key] = (elements[key] ?? ScoringElement()) +
            (other.elements[key] ?? ScoringElement());
      },
    );
    return endgameScore;
  }

  EndgameScore.fromJson(Map<String, dynamic> json, this.ref) {
    ref.keys.forEach(
      (e) {
        elements[e] = ScoringElement(
          name: ref[e]['name'] ?? e,
          count: json[e] ?? 0,
          min: () => ref[e]['min'] ?? 0,
          value: ref[e]['value'] ?? 1,
          isBool: ref[e]['isBool'] ?? false,
          key: e,
        );
      },
    );
    maxSet();
  }
  Map<String, dynamic> toJson() =>
      elements.map((key, value) => MapEntry(key, value.count));
}

class Penalty extends ScoreDivision {
  late ScoringElement majorPenalty;
  late ScoringElement minorPenalty;
  late Dice dice;
  Penalty() {
    majorPenalty =
        ScoringElement(name: 'Major Penalty', value: -30, key: 'major');
    minorPenalty =
        ScoringElement(name: 'Minor Penalty', value: -10, key: 'minor');
  }

  @override
  Dice getDice() => dice;

  @override
  List<ScoringElement> getElements() => [majorPenalty, minorPenalty];

  @override
  int total({bool? showPenalties}) => getElements()
      .map((e) => e.scoreValue())
      .reduce((value, element) => value + element);

  Penalty operator +(Penalty other) {
    var penalty = Penalty();
    penalty.dice = dice;
    penalty.majorPenalty = other.majorPenalty + majorPenalty;
    penalty.minorPenalty = other.minorPenalty + minorPenalty;
    return penalty;
  }

  Penalty.fromJson(Map<String, dynamic> json)
      : majorPenalty = ScoringElement(
          name: 'Major Penalty',
          value: -30,
          count: json['major'],
          key: 'major',
        ),
        minorPenalty = ScoringElement(
          name: 'Minor Penalty',
          value: -10,
          count: json['minor'],
          key: 'minor',
        );
  Map<String, dynamic> toJson() => {
        'major': majorPenalty.count,
        'minor': minorPenalty.count,
      };
}

class Change {
  String title;
  String? description;
  Timestamp startDate;
  Timestamp? endDate;
  String id;
  Change({
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.id,
  });
  Change.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        description = json['description'],
        startDate = Timestamp(json['startSeconds'], json['startNanoSeconds']),
        endDate = Timestamp(json['endSeconds'], json['endNanoSeconds']),
        id = json['id'];
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'startSeconds': startDate.seconds,
        'startNanoSeconds': startDate.nanoseconds,
        'endSeconds': endDate?.seconds,
        'endNanoSeconds': endDate?.nanoseconds,
        'id': id,
      };
}

class ScoringElement {
  ScoringElement(
      {this.name = '',
      this.count = 0,
      this.value = 1,
      this.min,
      this.max,
      this.isBool = false,
      this.key}) {
    setStuff();
  }
  String name;
  String? key;
  int count;
  int value;
  bool isBool;
  late int Function()? min = () => 0;
  late int Function()? max = () => 999;
  int incrementValue = 1;
  int decrementValue = 1;

  bool asBool() => count == 0 ? false : true;

  void setStuff() {
    if (min == null) min = () => 0;
    if (max == null) max = () => 999;
  }

  int scoreValue() => count * value;

  void increment() {
    if (count < max!()) {
      count += incrementValue;
      count = count.clamp(min!(), max!());
    }
  }

  void decrement() {
    if (count > min!()) {
      count -= decrementValue;
      count = count.clamp(min!(), max!());
    }
  }

  ScoringElement operator +(ScoringElement other) {
    return ScoringElement(
        count: other.count + count,
        value: value,
        key: other.key,
        name: name,
        isBool: isBool,
        min: min,
        max: max);
  }
}

abstract class ScoreDivision {
  int total({bool? showPenalties}) => getElements()
      .map((e) => e.scoreValue())
      .reduce((value, element) => value + element)
      .clamp(0, 999);
  Dice getDice();
  List<ScoringElement> getElements();
  late Timestamp timeStamp;
}
