import 'dart:html';
import 'dart:math';
import 'score.dart';
import 'package:uuid/uuid.dart';
import 'package:tuple/tuple.dart';

class DataModel {}

class Event {
  List<Team> teams;
  List<Match> matches;
  double maxScore() {
    return teams.map((e) => e.scores.maxScore()).reduce(max);
  }

  double lowestMadScore() {
    return teams.map((e) => e.scores.madScore()).reduce(min);
  }
}

class Team {
  String name;
  String number;
  List<Score> scores;
  Team(String number, String name) {
    this.name = name;
    this.number = number;
    scores = List();
  }
  static Team nullTeam() {
    return Team("?", "?");
  }

  bool equals(Team other) {
    return this.number == other.number;
  }
}

class Match {
  EventType type = EventType.live;
  Dice dice = Dice.one;
  Tuple2<Team, Team> red;
  Tuple2<Team, Team> blue;
  Match() {}
}

enum EventType { live, local, remote }
enum Dice { one, two, three }

extension DiceExtension on Dice {
  int stackHeight() {
    switch (this) {
      case Dice.one:
        return 0;
      case Dice.two:
        return 1;
      default:
        return 4;
    }
  }
}

extension IterableExtensions on Iterable {
  double mean() {
    return this.reduce((value, element) => value += element) / this.length;
  }

  double mad() {
    final mean = this.mean();
    return this.map((e) => (e - mean).abs()).mean();
  }
}

extension TeamsExtension on List<Team> {}

extension ScoresExtension on List<Score> {
  double maxScore() {
    return this.map((e) => e.total()).reduce(max).toDouble();
  }

  double avgScore() {
    return this.map((e) => e.total()).mean();
  }

  double madScore() {
    return this.map((e) => e.total()).mad();
  }

  double teleMaxScore() {
    return this.map((e) => e.teleScore.total()).reduce(max).toDouble();
  }

  double teleMeanScore() {
    return this.map((e) => e.teleScore.total()).mean();
  }

  double teleMADScore() {
    return this.map((e) => e.teleScore.total()).mad();
  }

  double autoMaxScore() {
    return this.map((e) => e.autoScore.total()).reduce(max).toDouble();
  }

  double autoMeanScore() {
    return this.map((e) => e.autoScore.total()).mean();
  }

  double autoMADScore() {
    return this.map((e) => e.autoScore.total()).mad();
  }

  double endMaxScore() {
    return this.map((e) => e.endgameScore.total()).reduce(max).toDouble();
  }

  double endMeanScore() {
    return this.map((e) => e.endgameScore.total()).mean();
  }

  double endMADScore() {
    return this.map((e) => e.endgameScore.total()).mad();
  }
}
