import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teamtrack/functions/Functions.dart';
import 'package:teamtrack/functions/Extensions.dart';

import '../functions/Statistics.dart';
import 'GameModel.dart';
import 'ScoreModel.dart';
import 'StatConfig.dart';

class GPTModel {

  GPTModel({
    required this.event,
    required this.sortMode,
    required this.elementSort,
    required this.statConfig,
    required this.statistic,
    required this.selectorTeam
  });

  final Team selectorTeam;
  final Event event;
  final OpModeType? sortMode;
  final ScoringElement? elementSort;
  final StatConfig statConfig;
  final Statistics statistic;

  String returnModelFeedback() {

    if (existsPartner (event.userTeam) || selectorTeam.number == event.userTeam.number) {
      return returnBestAlliance();
    } else if (selectorTeam.number != event.userTeam.number && exists(event.userTeam)) {
      return "";
    } else if (event.currentTurn > findTurn(event.userTeam) && event.currentPartner == 2) {
      return "";
    }
    else {
      if (!event.d) {

        return acceptOrDecline(selectorTeam);
      }
     return "";
    }
  }

  bool exists(Team team) {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 3; j++) {
        if (team.number == event.alliances[i][j].number) {
          return true;
        }
      }
    }
    return false;
  }

  int findTurn(Team team) {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 3; j++) {
        if (team.number == event.alliances[i][j].number) {
          return j;
        }
      }
    }
    return 2;
  }

  bool existsPartner (Team team) {
    for (int i = 0; i < 3; i++) {
      if (team.number == event.alliances[i][0].number) {
        return true;
      }
    }
    return false;
  }

  int returnUserTeamIndex() {
    List<Team> rankedList = returnRankedList();
    for (int i = 0; i < rankedList.length; i++) {
      if (rankedList[i].number == event.userTeam.number) {
        return i + 1;
      }
    }
    return -1; // Return -1 if userTeam is not found
  }

  int returnTeamIndex(Team team) {
    List<Team> rankedList = returnRankedList();
    for (int i = 0; i < rankedList.length; i++) {

      if (rankedList[i].name == team.name) {


        return i + 1;
      }
    }
    return -1; // Return -1 if userTeam is not found
  }

  List<Team> returnRankedList() {
    final teams = statConfig.sorted
        ? event.teams.sortedTeams(
      sortMode,
      elementSort,
      statConfig,
      event.matches.values.toList(),
      statistic,
    )
        : event.teams.orderedTeams();

    teams.sort((team1, team2) {
      int wins1 = int.parse(team1.getWLT(event)!.substring(0, 1));
      int wins2 = int.parse(team2.getWLT(event)!.substring(0, 1));
      int auton1 = team1.getSpecificScore(event, OpModeType.auto);
      int auton2 = team2.getSpecificScore(event, OpModeType.auto);
      int tele1 = team1.getSpecificScore(event, OpModeType.tele);
      int tele2 = team2.getSpecificScore(event, OpModeType.tele);
      int endgame1 = team1.getSpecificScore(event, OpModeType.endgame);
      int endgame2 = team2.getSpecificScore(event, OpModeType.endgame);

      if (wins1 != wins2) {
        return wins2.compareTo(wins1);
      } else if (auton1 != auton2) {
        return auton2.compareTo(auton1);
      } else if (endgame1 != endgame2) {
        return endgame2.compareTo(endgame1);
      } else {
        return tele2.compareTo(tele1);
      }
    });
    return teams;
  }

  bool searchInAlliances(Team team) {
    for (int i = 0; i < event.alliances.length; i++) {
      for (int j = 0; j < event.alliances[i].length; j++) { // Added 'int' before j


        if (team.number == event.alliances[i][j].number) {

          return true;
        }
      }
    }

    return false;
  }

  String returnBestAlliance() {

    int i = event.rankedTeams.length - 1;
    for (int m = 0; m < event.rankedTeams.length; m++) {
      if (event.rankedTeams[m].number == event.userTeam.number) {
        i = m;
        break;
      }
    }

    int index = event.rankedTeams.length - 1;
    for (int k = i + 1; k < event.rankedTeams.length; k++) {
      if (event.rankedTeams[k].getAllianceScore(event) > event.rankedTeams[index].getAllianceScore(event)) {
        if (!searchInAlliances(event.rankedTeams[k])) {
          index = k;
        }
      }
    }

    return "Select ${event.rankedTeams[index].name} to be your alliance partner!";
  }

  String acceptOrDecline(Team selectorTeam) {

    // GOT REALLY LUCKY WE DON'T PROBABLY HAVE TO TAKE TURN INTO ACCOUNT FOR NOW..., but we will need to.
    int i = returnTeamIndex(selectorTeam);
    int j = returnUserTeamIndex();


    Team selectedTeam = event.userTeam;

    double twentyPercentMultiplier = 0.8;
    double sixtyPercentMultiplier = 0.95;
    double eightyPercentMultiplier = 1.05;
    double ninetyFivePercentMultiplier = 1.2;

    String num = selectorTeam.number;
    String name = selectorTeam.name;

    String answerViaInspire =
        "Your robot is strong enough to be an alliance captain!"
        "However, take into account the inspire chances of $num $name before declining a potential offer.";
    String mustAccept = "Try to alliance with $num $name to guarantee a chance of appearing in elimination rounds!";
    String shouldAccept = "You have a great chance to advance working with $num $name!";
    String youAreBetter = "You may have a better chance to qualify in another alliance!";

    if (i == 1) { // has to be first

      if (j == 2) {
        if (selectorTeam.getAllianceScore(event) * sixtyPercentMultiplier < selectedTeam.getAllianceScore(event)) {
          return answerViaInspire;
        } else {
          return shouldAccept;
        }
      }
      else if (j == 3) {
        if (selectorTeam.getAllianceScore(event) * eightyPercentMultiplier < selectedTeam.getAllianceScore(event)) {
          return answerViaInspire;
        } else {
          return shouldAccept;
        }
      }
      else if (j == 4) {
        if (selectorTeam.getAllianceScore(event) * ninetyFivePercentMultiplier < selectedTeam.getAllianceScore(event)) {
          return answerViaInspire;
        } else {
          return shouldAccept;
        }
      }
    }
    else if (i == 2) { // has to be second
      if (j == 3) {
        if (selectorTeam.getAllianceScore(event) * sixtyPercentMultiplier < selectedTeam.getAllianceScore(event)) {
          return answerViaInspire;
        } else {
          return shouldAccept;
        }
      }
      else if (j == 4) {
        if (selectorTeam.getAllianceScore(event) * sixtyPercentMultiplier < selectedTeam.getAllianceScore(event)) {
          return answerViaInspire;
        } else {
          return shouldAccept;
        }
      }
      else {
        return mustAccept;
      }
    }
    else if (i == 3 && event.currentTurn == 2) {
      if (j == 4) {
        if (selectorTeam.getAllianceScore(event) * twentyPercentMultiplier < selectedTeam.getAllianceScore(event)) {
          return youAreBetter;
        } else {
          return shouldAccept;
        }
      }
      else if (j == 5) {
        // instead check 3rd alliance vs 4th alliance, and also check if you are good enough or you got lucky to get picked by 4th
        if (selectorTeam.getAllianceScore(event) * eightyPercentMultiplier < selectedTeam.getAllianceScore(event)) {
          return answerViaInspire;
        } else {
          return shouldAccept;
        }
      }
    }
    else if (i == 3 && event.currentTurn == 3) {
      if (j == 4) {
        if (selectorTeam.getAllianceScore(event) * twentyPercentMultiplier < selectedTeam.getAllianceScore(event)) {
          return youAreBetter;
        } else {
          return shouldAccept;
        }
      }
    }
    else if (i == 4 && event.currentTurn == 3) {
      if (j == 5) {
        if (selectorTeam.getAllianceScore(event) * twentyPercentMultiplier < selectedTeam.getAllianceScore(event) && event.currentTurn <= 3) {
          return youAreBetter;
        } else {
          return shouldAccept;
        }
      }
    }

    return mustAccept;

  }
}






