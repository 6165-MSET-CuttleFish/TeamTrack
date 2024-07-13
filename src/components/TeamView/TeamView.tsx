tsx
import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import { LineChart, LineChartConfig } from 'react-native-chart-kit';
import { useNavigation } from '@react-navigation/native';
import { Dice, OpModeType, EventType, StatConfig, Team, Event, Score, ScoringElement } from '../../models/GameModel';
import ScoreCard from '../scores/ScoreCard';
import AutonDrawer from './AutonDrawer';
import MatchList from '../match/MatchList';
import MatchView from '../match/MatchView';
import ChangeList from '../change/ChangeList';
import { useAppModel } from '../../models/AppModel';
import { getStatistic, spots, removeOutliers, maxValue } from '../../functions/Statistics';
import { getAll as getAllOpModes, getName as getOpModeName, getColor as getOpModeColor } from '../../functions/Extensions';
import { v4 as uuidv4 } from 'uuid';
import { useDatabase } from '../../database/DatabaseContext';

const scopeMarks = ['', 'Both_Side', 'Red_Side', 'Blue_Side'];
const initialDropdownScope = scopeMarks[0];

interface TeamViewState {
  dice: Dice;
  selections: { [key: string]: boolean };
  showCycles: boolean;
  maxScore: Score | null;
  teamMaxScore: Score | null;
  painter: any;
}

const TeamView: React.FC<{ team: Team; event: Event; isSoleWindow: boolean }> = ({ team, event, isSoleWindow }) => {
  const navigation = useNavigation();
  const { saveEvents, dataModel } = useAppModel();
  const { database } = useDatabase();
  const [state, setState] = useState<TeamViewState>({
    dice: Dice.none,
    selections: {
      null: true,
      [OpModeType.auto]: false,
      [OpModeType.tele]: false,
      [OpModeType.endgame]: false,
      [OpModeType.penalty]: false,
    },
    showCycles: false,
    maxScore: null,
    teamMaxScore: null,
    painter: null,
  });
  const [teamData, setTeamData] = useState<Team>(team);

  useEffect(() => {
    const unsubscribe = database.ref(`events/${event.key}`).on('value', (snapshot) => {
      const eventData = snapshot.val();
      if (eventData) {
        const updatedEvent = new Event(eventData, event.key);
        const updatedTeam = updatedEvent.teams[team.number] || Team.nullTeam();
        setTeamData(updatedTeam);
        const maxScore = new Score('', Dice.none, updatedEvent.gameName);
        maxScore?.getElements().forEach((element) => {
          element.normalCount = updatedEvent.teams.values.map((t) => {
            if (!element.isBool) {
              return t.scores.values
                .map((score) => {
                  return score
                    .getElements()
                    .find((e) => e.key === element.key)
                    ?.countFactoringAttempted();
                })
                .filter(Boolean)
                .reduce((a, b) => a + b);
            } else {
              return t.scores.values
                .map((score) => {
                  return score
                    .getElements()
                    .find((e) => e.key === element.key)
                    ?.countFactoringAttempted();
                })
                .filter(Boolean)
                .reduce((a, b) => a + b);
            }
          }).reduce((a, b) => Math.max(a, b));
        });
        setState((prevState) => ({ ...prevState, maxScore }));
        const teamMaxScore = new Score('', Dice.none, updatedEvent.gameName);
        teamMaxScore?.getElements().forEach((element) => {
          element.normalCount = !element.isBool
            ? updatedTeam.scores.values
                .map((score) => {
                  return score
                    .getElements()
                    .find((e) => e.key === element.key)
                    ?.countFactoringAttempted();
                })
                .filter(Boolean)
                .reduce((a, b) => a + b)
            : updatedTeam.scores.values
                .map((score) => {
                  return score
                    .getElements()
                    .find((e) => e.key === element.key)
                    ?.countFactoringAttempted();
                })
                .filter(Boolean)
                .reduce((a, b) => a + b);
        });
        setState((prevState) => ({ ...prevState, teamMaxScore }));
      }
    });
    return () => unsubscribe();
  }, [database, event.key, team.number]);

  useEffect(() => {
    const painter = new AutonPainter({ team: teamData, event: event });
    setState((prevState) => ({ ...prevState, painter }));
  }, [teamData, event]);

  const getSelection = (opModeType: OpModeType) => state.selections[opModeType] ?? false;

  const handleDiceChange = (dice: Dice) => {
    setState({ ...state, dice });
  };

  const handleOpModeSelection = (opModeType: OpModeType) => {
    setState((prevState) => ({
      ...prevState,
      selections: { ...prevState.selections, [opModeType]: !prevState.selections[opModeType] },
    }));
  };

  const handleShowCycles = () => {
    setState((prevState) => ({ ...prevState, showCycles: !prevState.showCycles }));
  };

  const navigateToMatchList = async () => {
    navigation.navigate('MatchList', { event, team, ascending: false });
  };

  const navigateToMatchView = async () => {
    if (!teamData.targetScore) {
      teamData.targetScore = new Score(uuidv4(), Dice.none, event.gameName);
      await database.ref(`events/${event.key}/teams/${team.number}`).update({
        targetScore: teamData.targetScore.toJson(),
      });
      saveEvents();
    }
    navigation.navigate('MatchView', { event, team: teamData });
  };

  const navigateToAutonDrawer = () => {
    navigation.navigate('AutonDrawer', { event, team: teamData });
  };

  const handleDeleteTeam = () => {
    Alert.alert(
      'Delete Team',
      'Are you sure you want to delete this team?',
      [
        {
          text: 'Cancel',
          style: 'cancel',
        },
        {
          text: 'Confirm',
          style: 'destructive',
          onPress: async () => {
            const deletionResult = event.deleteTeam(teamData);
            if (deletionResult) {
              Alert.alert(
                'Error',
                'Team is present in matches',
                [{ text: 'Okay', onPress: () => navigation.goBack() }],
              );
            } else {
              saveEvents();
              navigation.goBack();
            }
          },
        },
      ],
    );
  };

  const handleConfigure = () => {
    Alert.alert(
      'Configure',
      'Coming Soon!',
      [{ text: 'Okay', onPress: () => navigation.goBack() }],
    );
  };

  const _lineChart = () => {
    if (teamData.scores.diceScores(state.dice).length > 1) {
      const lineChartConfig: LineChartConfig = {
        bezier: false,
        backgroundGradientFrom: { color: '#ffffff' },
        backgroundGradientTo: { color: '#ffffff' },
        decimalPlaces: 0,
        showGrid: true,
        showXAxis: true,
        showYAxis: true,
        withDots: true,
        xLabelsFormat: (value) => (value + 1).toString(),
        yLabelsFormat: (value) => value.toString(),
        yLabelsAlign: 'left',
        yAxisInterval: 1,
        xLabelsAlign: 'center',
        xAxisInterval: 1,
        yAxisSuffix: ' points',
        data: {
          datasets: getAllOpModes().map((opModeType) => {
            const spotsData = event.statConfig.allianceTotal
              ? event.getSortedMatches(true)
                  .filter((e) => e.dice === state.dice || state.dice === Dice.none)
                  .map((match) => {
                    return spots(teamData, state.dice, false, opModeType, match);
                  })
                  .filter((spot) => spot.y !== undefined && spot.y !== null)
                  .map((spot) => ({ x: spot.x, y: spot.y }))
                  .filter((spot) => spot.y !== undefined && spot.y !== null)
              : teamData.scores
                  .diceScores(state.dice)
                  .spots(opModeType)
                  .filter((spot) => spot.y !== undefined && spot.y !== null)
                  .map((spot) => ({ x: spot.x, y: spot.y }));
            return {
              data: spotsData,
              color: getOpModeColor(opModeType),
              strokeWidth: 2,
              withDots: true,
              withLines: true,
              withShadow: true,
            };
          }),
        },
      };
      return (
        <View style={styles.chartContainer}>
          <LineChart
            config={lineChartConfig}
            width={350}
            height={220}
            style={{
              borderRadius: 10,
            }}
          />
        </View>
      );
    } else {
      return null;
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <View style={styles.teamInfo}>
          <Text style={styles.teamName}>{teamData.name}</Text>
          <Text style={styles.teamNumber}>{teamData.number}</Text>
        </View>
        <View style={styles.actions}>
          <TouchableOpacity onPress={handleConfigure} style={styles.actionButton}>
            <Text style={styles.actionButtonText}>Configure</Text>
          </TouchableOpacity>
          {isSoleWindow && (
            <TouchableOpacity onPress={handleDeleteTeam} style={styles.actionButton}>
              <Text style={styles.actionButtonText}>Delete</Text>
            </TouchableOpacity>
          )}
          {isSoleWindow && (
            <TouchableOpacity onPress={handleShowCycles} style={styles.actionButton}>
              <Text style={styles.actionButtonText}>
                {state.showCycles ? 'Hide Cycles' : 'Show Cycles'}
              </Text>
            </TouchableOpacity>
          )}
        </View>
      </View>
      <View style={styles.diceContainer}>
        <Text style={styles.diceLabel}>Dice:</Text>
        <View style={styles.diceDropdown}>
          {DiceExtension.getAll().map((value) => (
            <TouchableOpacity
              key={value?.toVal(event.gameName)}
              style={styles.diceOption}
              onPress={() => handleDiceChange(value)}
            >
              <Text style={[styles.diceOptionText, value === state.dice && styles.selectedDiceOptionText]}>
                {value?.toVal(event.gameName) || 'All Cases'}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>
      <View style={styles.opModeContainer}>
        {getAllOpModes().map((opModeType) => (
          <TouchableOpacity
            key={getOpModeName(opModeType)}
            style={[styles.opModeButton, getSelection(opModeType) && styles.selectedOpModeButton]}
            onPress={() => handleOpModeSelection(opModeType)}
          >
            <Text style={styles.opModeButtonText}>{getOpModeName(opModeType)}</Text>
          </TouchableOpacity>
        ))}
      </View>
      {_lineChart()}
      {isSoleWindow && (
        <View style={styles.buttonContainer}>
          <TouchableOpacity onPress={navigateToMatchList} style={styles.button}>
            <Text style={styles.buttonText}>Matches</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={navigateToMatchView} style={styles.button}>
            <Text style={styles.buttonText}>Target</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={navigateToAutonDrawer} style={styles.button}>
            <Text style={styles.buttonText}>Auton</Text>
          </TouchableOpacity>
        </View>
      )}
      {getAllOpModes().map((opModeType) => (
        <View key={getOpModeName(opModeType)} style={styles.scoreCardContainer}>
          <ScoreCard
            allianceTotal={event.statConfig.allianceTotal}
            team={teamData}
            event={event}
            targetScore={teamData.targetScore?.getScoreDivision(opModeType)}
            scoreDivisions={teamData.scores
              .sortedScores()
              .map((e) => e.getScoreDivision(opModeType))
              .filter(Boolean) as Score[]}
            dice={state.dice}
            removeOutliers={event.statConfig.removeOutliers}
            matches={event.getSortedMatches(true)}
            title={getOpModeName(opModeType)}
            type={opModeType}
          />
        </View>
      ))}
      {isSoleWindow && event.type === EventType.remote && (
        <View style={styles.buttonContainer}>
          <TouchableOpacity onPress={() => navigation.navigate('ChangeList', { team: teamData, event })} style={styles.button}>
            <Text style={styles.buttonText}>Robot Iterations</Text>
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 15,
    backgroundColor: '#f0f0f0',
  },
  teamInfo: {
    alignItems: 'flex-start',
  },
  teamName: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  teamNumber: {
    fontSize: 16,
  },
  actions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  actionButton: {
    padding: 10,
    margin: 5,
    backgroundColor: '#4CAF50',
    borderRadius: 5,
  },
  actionButtonText: {
    color: '#fff',
    fontSize: 16,
  },
  diceContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 15,
  },
  diceLabel: {
    fontSize: 18,
    marginRight: 10,
  },
  diceDropdown: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  diceOption: {
    padding: 10,
    margin: 5,
    backgroundColor: '#e0e0e0',
    borderRadius: 5,
  },
  diceOptionText: {
    fontSize: 16,
  },
  selectedDiceOptionText: {
    fontWeight: 'bold',
  },
  opModeContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-around',
    padding: 15,
  },
  opModeButton: {
    padding: 10,
    margin: 5,
    backgroundColor: '#e0e0e0',
    borderRadius: 5,
    width: '45%',
  },
  selectedOpModeButton: {
    backgroundColor: '#4CAF50',
  },
  opModeButtonText: {
    fontSize: 16,
    color: '#fff',
    textAlign: 'center',
  },
  chartContainer: {
    alignItems: 'center',
    padding: 15,
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: 15,
  },
  button: {
    padding: 10,
    backgroundColor: '#4CAF50',
    borderRadius: 5,
    width: '30%',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    textAlign: 'center',
  },
  scoreCardContainer: {
    marginBottom: 10,
  },
});

export default TeamView;