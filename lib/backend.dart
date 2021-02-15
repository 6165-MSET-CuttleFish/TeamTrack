import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'score.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';

read(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return json.decode(prefs.getString(key));
}

save(String key, value) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString(key, json.encode(value));
}

DataModel dataModel;

class DataModel {
  final List<String> keys = ['localEvents', 'remoteEvents', 'liveEvents'];
  DataModel() {
    try {
      events.add(read(keys[0]) as Event);
      events.add(read(keys[1]) as Event);
    } catch (Exception) {
      print('No events');
    }
    dataModel = this;
  }
  List<Event> events = [];

  List<Event> localEvents() {
    return events.where((e) => e.type == EventType.local).toList();
  }

  List<Event> remoteEvents() {
    return events.where((e) => e.type == EventType.remote).toList();
  }

  List<Event> liveEvents() {
    return events.where((e) => e.type == EventType.live).toList();
  }

  void saveEvents() async {
    await save(keys[0], localEvents());
    await save(keys[1], remoteEvents());
  }
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

  Event.fromJSON(Map<String, dynamic> json)
      : name = json['name'],
        teams = json['teams'],
        matches = json['matches'],
        type = json['type'];
  Map<String, dynamic> toJson() => {
        'name': name,
        'teams': teams,
        'matches': matches,
        'type': type,
      };
}

class Alliance {
  Team item1;
  Team item2;
  Alliance(Team item1, Team item2) {
    this.item1 = item1;
    this.item2 = item2;
  }
  int allianceTotal(Uuid id) {
    return 0 +
        item1?.scores?.firstWhere((e) => e.id == id)?.total() +
        item2?.scores?.firstWhere((e) => e.id == id)?.total();
  }

  Alliance.fromJSON(Map<String, dynamic> json)
      : item1 = json['team1'],
        item2 = json['team2'];
  Map<String, dynamic> toJson() => {
        'team1': item1.toJson(),
        'team2': item2.toJson(),
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

  Team.fromJSON(Map<String, dynamic> json)
      : number = json['number'],
        name = json['name'],
        scores = json['scores'];
  Map<String, dynamic> toJson() => {
        'name': name,
        'number': number,
        'scores': scores,
      };
}

class Match {
  EventType type = EventType.live;
  Dice dice = Dice.one;
  Alliance red;
  Alliance blue;
  Uuid id;
  Match(Alliance red, Alliance blue, EventType type) {
    this.type = type;
    this.red = red;
    this.blue = blue;
    id = Uuid();
    red?.item1?.scores?.addScore(Score(id, dice));
    red?.item2?.scores?.addScore(Score(id, dice));
    blue?.item1?.scores?.addScore(Score(id, dice));
    blue?.item2?.scores?.addScore(Score(id, dice));
  }
  static Match defaultMatch(EventType type) {
    return Match(Alliance(Team('1', 'Alpha'), Team('2', 'Beta')),
        Alliance(Team('3', 'Charlie'), Team('4', 'Delta')), type);
  }

  Alliance alliance(Team team) {
    if (!red.item2.equals(Team.nullTeam())) {
      if (red.item1.equals(team) || red.item2.equals(team)) {
        return red;
      } else if (blue.item1.equals(team) || blue.item2.equals(team)) {
        return blue;
      } else {
        return null;
      }
    } else {
      if (red.item1.equals(team)) {
        return red;
      } else {
        return null;
      }
    }
  }

  void setDice(Dice dice) {
    this.dice = dice;
    red.item1.scores.firstWhere((e) => e.id == id).dice = dice;
    red.item2.scores.firstWhere((e) => e.id == id).dice = dice;
    blue.item1.scores.firstWhere((e) => e.id == id).dice = dice;
    blue.item2.scores.firstWhere((e) => e.id == id).dice = dice;
  }

  String score() {
    if (type == EventType.remote) {
      return red.item1.scores.firstWhere((e) => e.id == id).total().toString();
    }
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

  Match.fromJSON(Map<String, dynamic> json)
      : red = json['red'],
        blue = json['blue'];
  Map<String, dynamic> toJson() => {
        'red': red,
        'blue': blue,
      };
}

enum EventType { live, local, remote }
enum Dice { one, two, three, none }

extension DiceExtension on Dice {
  String stackHeight() {
    switch (this) {
      case Dice.one:
        return '0';
      case Dice.two:
        return '1';
      case Dice.three:
        return '4';
      default:
        return 'All Cases';
    }
  }
}

extension IterableExtensions on Iterable<int> {
  List<FlSpot> spots() {
    List<FlSpot> val = [];
    for (int i = 0; i < this.length; i++) {
      val.add(FlSpot(i.toDouble(), this.toList()[i].toDouble()));
    }
    return val;
  }

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
    return this.map((e) => (e - mean).abs().toInt()).mean();
  }
}

extension MatchExtensions on List<Match> {
  List<FlSpot> spots(Team team, Dice dice) {
    List<FlSpot> val = [];
    final arr =
        (dice != Dice.none ? this.where((e) => e.dice == dice) : this).toList();
    for (int i = 0; i < arr.length; i++) {
      final alliance = arr[i].alliance(team);
      if (alliance != null) {
        final allianceTotal = alliance.allianceTotal(arr[i].id);
        val.add(FlSpot(i.toDouble(), allianceTotal.toDouble()));
      }
    }
    return val;
  }

  int maxAllianceScore(Team team) {
    List<int> val = [];
    for (int i = 0; i < this.length; i++) {
      final alliance = this[i].alliance(team);
      if (alliance != null) {
        final allianceTotal = alliance.allianceTotal(this[i].id);
        val.add(allianceTotal);
      }
    }
    return val.reduce(max);
  }
}

extension TeamsExtension on List<Team> {
  Team findAdd(String number, String name) {
    bool found = false;
    for (Team team in this) {
      if (team.number ==
          number
              .replaceAll(new RegExp(r' -,[^\w\s]+'), '')
              .replaceAll(' ', '')) {
        found = true;
      }
    }
    if (found) {
      var team = this.firstWhere((e) =>
          e.number ==
          number
              .replaceAll(new RegExp(r' -,[^\w\s]+'), '')
              .replaceAll(' ', ''));
      team.name = name;
      return team;
    } else {
      var newTeam = Team(
          number.replaceAll(new RegExp(r' -,[^\w\s]+'), '').replaceAll(' ', ''),
          name);
      this.add(newTeam);
      this.sortTeams();
      return newTeam;
    }
  }

  void sortTeams() {
    this.sort((a, b) => int.parse(a.number).compareTo(int.parse(b.number)));
  }

  double maxScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.maxScore(dice)).reduce(max);
  }

  double lowestMadScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.madScore(dice)).reduce(min);
  }

  double maxAutoScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.autoMaxScore(dice)).reduce(max);
  }

  double lowestAutoMadScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.autoMADScore(dice)).reduce(min);
  }

  double maxTeleScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.teleMaxScore(dice)).reduce(max);
  }

  double lowestTeleMadScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.teleMADScore(dice)).reduce(min);
  }

  double maxEndScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.endMaxScore(dice)).reduce(max);
  }

  double lowestEndMadScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.endMADScore(dice)).reduce(min);
  }
}

extension ScoresExtension on List<Score> {
  List<FlSpot> spots() {
    final list = this.map((e) => e.total()).toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }

  List<FlSpot> teleSpots() {
    final list = this.map((e) => e.teleScore.total()).toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }

  List<FlSpot> autoSpots() {
    final list = this.map((e) => e.autoScore.total()).toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }

  List<FlSpot> endSpots() {
    final list = this.map((e) => e.endgameScore.total()).toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }

  double maxScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.total()).reduce(max).toDouble();
  }

  double minScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.total()).reduce(min).toDouble();
  }

  double meanScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.total()).mean();
  }

  double madScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.total()).mad();
  }

  double teleMaxScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.teleScore.total()).reduce(max).toDouble();
  }

  double teleMinScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.teleScore.total()).reduce(min).toDouble();
  }

  double teleMeanScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.teleScore.total()).mean();
  }

  double teleMADScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.teleScore.total()).mad();
  }

  double autoMaxScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0)
      return 0;
    else
      return arr.map((e) => e.autoScore.total()).reduce(max).toDouble();
  }

  double autoMinScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0)
      return 0;
    else
      return arr.map((e) => e.autoScore.total()).reduce(min).toDouble();
  }

  double autoMeanScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0)
      return 0;
    else
      return arr.map((e) => e.autoScore.total()).mean();
  }

  double autoMADScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0)
      return 0;
    else
      return arr.map((e) => e.autoScore.total()).mad();
  }

  double endMaxScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.endgameScore.total()).reduce(max).toDouble();
  }

  double endMinScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.endgameScore.total()).reduce(min).toDouble();
  }

  double endMeanScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.endgameScore.total()).mean();
  }

  double endMADScore(Dice dice) {
    final arr = this.diceScores(dice);
    if (arr.length == 0) return 0;
    return arr.map((e) => e.endgameScore.total()).mad();
  }

  List<Score> diceScores(Dice dice) {
    return (dice != Dice.none ? this.where((e) => e.dice == dice) : this)
        .toList();
  }
}

bool toggle(bool init) {
  return !init;
}
