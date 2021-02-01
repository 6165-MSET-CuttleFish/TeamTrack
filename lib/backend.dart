import 'dart:math';
import 'score.dart';
import 'package:uuid/uuid.dart';
import 'package:tuple/tuple.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataModel {
  List<Event> localEvents = [];
  List<Event> remoteEvents = [];
  List<Event> liveEvents = [];
}

class Event {
  Event({this.name, this.type});
  EventType type;
  List<Team> teams = [];
  List<Match> matches = [];
  String name;
  void addTeam(Team newTeam) {
    bool isIn = false;
    teams.forEach((element) {
      if (element.equals(newTeam)) isIn = true;
    });
    if (!isIn) teams.add(newTeam);
    teams.sortTeams();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'teams': teams,
        'matches': matches,
        'type': type,
      };
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'number': number,
        'scores': scores,
      };
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
  static Match defaultMatch(EventType type) {
    return Match(Tuple2(Team('1', 'Alpha'), Team('2', 'Beta')),
        Tuple2(Team('3', 'Charlie'), Team('4', 'Delta')), type);
  }

  Tuple2<Team, Team> alliance(Team team) {
    if (red.item1.equals(team) || red.item2.equals(team)) {
      return red;
    } else if (blue.item1.equals(team) || blue.item2.equals(team)) {
      return blue;
    } else {
      return null;
    }
  }

  String score() {
    return redScore() + " - " + blueScore();
  }

  String redScore() {
    final r0 = red.item1.scores.firstWhere((e) => e.id == id).total();
    final r1 = red.item2.scores.firstWhere((e) => e.id == id).total();
    return (r0 + r1).toString();
  }

  String blueScore() {
    final b0 = blue.item1.scores.firstWhere((e) => e.id == id).total();
    final b1 = blue.item2.scores.firstWhere((e) => e.id == id).total();
    return (b0 + b1).toString();
  }

  Map<String, dynamic> toJson() => {
        'red1': red.item1,
        'red2': red.item2,
        'blue1': blue.item1,
        'blue2': blue.item2,
      };
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
    if (this.length == 0) {
      return 0;
    } else {
      return this.reduce((value, element) => value += element) / this.length;
    }
  }

  double mad() {
    if (this.length == 0) {
      return 0;
    }
    final mean = this.mean();
    return this.map((e) => (e - mean).abs()).mean();
  }
}

extension TeamsExtension on List<Team> {
  Team findAdd(String number, String name) {
    bool found = false;
    for (Team team in this) {
      if (team.number ==
          number.replaceAll(new RegExp(r' [^\w\s]+'), '').replaceAll(' ', '')) {
        found = true;
      }
    }
    if (found) {
      var team = this.firstWhere((e) =>
          e.number ==
          number.replaceAll(new RegExp(r' [^\w\s]+'), '').replaceAll(' ', ''));
      team.name = name;
      return team;
    } else {
      var newTeam = Team(
          number.replaceAll(new RegExp(r' [^\w\s]+'), '').replaceAll(' ', ''),
          name);
      this.add(newTeam);
      this.sortTeams();
      return newTeam;
    }
  }

  void sortTeams() {
    this.sort((a, b) => int.parse(a.number).compareTo(int.parse(b.number)));
  }

  double maxScore() {
    return this.map((e) => e.scores.maxScore()).reduce(max);
  }

  double lowestMadScore() {
    return this.map((e) => e.scores.madScore()).reduce(min);
  }

  double maxAutoScore(Dice dice) {
    return this.map((e) => e.scores.autoMaxScore(dice)).reduce(max);
  }

  double lowestAutoMadScore() {
    return this.map((e) => e.scores.autoMADScore()).reduce(min);
  }

  double maxTeleScore() {
    return this.map((e) => e.scores.teleMaxScore()).reduce(max);
  }

  double lowestTeleMadScore() {
    return this.map((e) => e.scores.teleMADScore()).reduce(min);
  }

  double maxEndScore() {
    return this.map((e) => e.scores.endMaxScore()).reduce(max);
  }

  double lowestEndMadScore() {
    return this.map((e) => e.scores.endMADScore()).reduce(min);
  }
}

extension ScoresExtension on List<Score> {
  List<FlSpot> spots() {
    final list = this.map((e) => e.total()).toList();
    List<FlSpot> val;
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }

  double maxScore() {
    return this.map((e) => e.total()).reduce(max).toDouble();
  }

  double minScore() {
    return this.map((e) => e.total()).reduce(min).toDouble();
  }

  double meanScore(Dice dice) {
    if (dice == null) {
      return this.map((e) => e.total()).mean();
    } else {
      return this.where((e) => e.dice == dice).map((e) => e.total()).mean();
    }
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

  double autoMaxScore(Dice dice) {
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

bool toggle(bool init) {
  if (init)
    return false;
  else
    return true;
}
