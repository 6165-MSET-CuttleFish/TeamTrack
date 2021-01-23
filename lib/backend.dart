import 'dart:math';
import 'score.dart';
import 'package:uuid/uuid.dart';
import 'package:tuple/tuple.dart';
import 'package:fl_chart/fl_chart.dart';

class DataModel {
  List<Event> localEvents = [];
  List<Event> remoteEvents = [];
  List<Event> liveEvents = [];
}

class Event {
  Event({this.name});
  List<Team> teams = [];
  List<Match> matches = [];
  String name;
  double maxScore() {
    return teams.map((e) => e.scores.maxScore()).reduce(max);
  }

  double lowestMadScore() {
    return teams.map((e) => e.scores.madScore()).reduce(min);
  }

  double maxAutoScore() {
    return teams.map((e) => e.scores.autoMaxScore()).reduce(max);
  }

  double lowestAutoMadScore() {
    return teams.map((e) => e.scores.autoMADScore()).reduce(min);
  }

  double maxTeleScore() {
    return teams.map((e) => e.scores.teleMaxScore()).reduce(max);
  }

  double lowestTeleMadScore() {
    return teams.map((e) => e.scores.teleMADScore()).reduce(min);
  }

  double maxEndScore() {
    return teams.map((e) => e.scores.endMaxScore()).reduce(max);
  }

  double lowestEndMadScore() {
    return teams.map((e) => e.scores.endMADScore()).reduce(min);
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
  Uuid id;
  Match(Tuple2<Team, Team> red, Tuple2<Team, Team> blue, EventType type) {
    this.type = type;
    this.red = red;
    this.blue = blue;
    id = Uuid();
    red.item1.scores.addScore(Score(id, dice));
    red.item2.scores.addScore(Score(id, dice));
    blue.item1.scores.addScore(Score(id, dice));
    blue.item2.scores.addScore(Score(id, dice));
  }
  static Match defaultMatch(EventType type){
    return Match(Tuple2(Team('1', 'Alpha'), Team('2', 'Beta')), Tuple2(Team('3', 'Charlie'), Team('4', 'Delta')), type);
  }
  String score() {
    final r0 =
        red.item1.scores.firstWhere((e) => e.id == id).total();
    final r1 =
        red.item2.scores.firstWhere((e) => e.id == id).total();
    final b0 =
        blue.item1.scores.firstWhere((e) => e.id == id).total();
    final b1 =
        blue.item2.scores.firstWhere((e) => e.id == id).total();
    return (r0 + r1).toString() + " - " + (b0 + b1).toString();
  }
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
  List<FlSpot> spots(){
    final list =  this.map((e) => e.total()).toList();
    List<FlSpot> val;
    for(int i = 0; i < list.length; i++){
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }
  double maxScore() {
    return this.map((e) => e.total()).reduce(max).toDouble();
  }
  double minScore(){
    return this.map((e) => e.total()).reduce(min).toDouble();
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
