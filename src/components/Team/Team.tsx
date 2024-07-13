tsx
import React, { useState, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Alert, Platform } from 'react-native';
import { LineChart, LineChartConfig } from 'react-native-charts-wrapper';
import { OpModeType, Dice, EventType, Team, Event, StatConfig, Score, ScoringElement, DiceExtension, opModeExt } from '../../models';
import { getStatistic, removeOutliers, spots } from '../../functions/Statistics';
import { getLessIsBetter, getName } from '../../functions/Extensions';
import { CheckList } from '../misc/CheckList';
import { EmptyList } from '../misc/EmptyList';
import { ScoreCard } from '../scores/ScoreCard';
import { MatchList } from '../match/MatchList';
import { MatchView } from '../match/MatchView';
import { AutonDrawer } from './AutonDrawer';
import { PlatformGraphics } from '../misc/PlatformGraphics';
import { Collapsible } from '../misc/Collapsible';
import { v4 as uuidv4 } from 'uuid';
import { useDatabase } from '../../firebase';
import { useStorage } from '../../firebase';

interface Props {
  team: Team;
  event: Event;
  isSoleWindow?: boolean;
}

const Team: React.FC<Props> = ({ team, event, isSoleWindow = true }) => {
  const [dice, setDice] = useState<Dice>(Dice.none);
  const [selections, setSelections] = useState<{ [key: string]: boolean }>({
    null: true,
    [OpModeType.auto]: false,
    [OpModeType.tele]: false,
    [OpModeType.endgame]: false,
    [OpModeType.penalty]: false,
  });
  const [showCycles, setShowCycles] = useState(false);
  const [maxScore, setMaxScore] = useState<Score | null>(null);
  const [teamMaxScore, setTeamMaxScore] = useState<Score | null>(null);
  const [autonPainter, setAutonPainter] = useState<any>(null);

  const db = useDatabase();
  const storage = useStorage();

  const scopeMarks = ['', 'Both_Side', 'Red_Side', 'Blue_Side'];
  const [dropdownScope, setDropdownScope] = useState(scopeMarks[0]);

  useEffect(() => {
    const _maxScore = new Score('', Dice.none, event.gameName);
    _maxScore?.getElements().forEach((element) => {
      element.normalCount = event.teams.values
        .map((team) =>
          !element.isBool
            ? team.scores.values
                .map((score) =>
                  score
                    .getElements()
                    .find((e) => e.key === element.key)
                    ?.countFactoringAttempted()
                )
                .filter((e) => typeof e === 'number')
                .reduce((a, b) => a + b) /
                team.scores.values.length
            : team.scores.values
                .map((score) =>
                  score
                    .getElements()
                    .find((e) => e.key === element.key)
                    ?.countFactoringAttempted()
                )
                .filter((e) => typeof e === 'number')
                .reduce((a, b) => a + b) /
                team.scores.values.length
        )
        .reduce((a, b) => Math.max(a, b)) || 0;
    });
    setMaxScore(_maxScore);

    const _autonPainter = new AutonPainter(team: team, event: event);
    setAutonPainter(_autonPainter);

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const unsubscribe = db.ref(`events/${event.key}/teams/${team.number}`).on('value', (snapshot) => {
      const data = snapshot.val();
      if (data) {
        event.updateLocal(data, null);
        const _team = event.teams[team.number];
        if (_team) {
          const _teamMaxScore = new Score('', Dice.none, event.gameName);
          _teamMaxScore?.getElements().forEach((element) => {
            element.normalCount = !element.isBool
              ? _team.scores.values
                  .map((score) =>
                    score
                      .getElements()
                      .find((e) => e.key === element.key)
                      ?.countFactoringAttempted()
                  )
                  .filter((e) => typeof e === 'number')
                  .reduce((a, b) => a + b) /
                  _team.scores.values.length
              : _team.scores.values
                  .map((score) =>
                    score
                      .getElements()
                      .find((e) => e.key === element.key)
                      ?.countFactoringAttempted()
                  )
                  .filter((e) => typeof e === 'number')
                  .reduce((a, b) => a + b) /
                  _team.scores.values.length;
          });
          setTeamMaxScore(_teamMaxScore);
        }
      }
    });

    return () => unsubscribe();
  }, [db, team, event]);

  const getSelection = (opModeType: OpModeType) => selections[opModeType] || false;

  const updateSelections = (opModeType: OpModeType) => {
    setSelections({
      ...selections,
      [opModeType]: !selections[opModeType],
    });
  };

  const handleDiceChange = (newValue: Dice) => {
    setDice(newValue);
  };

  const handleScopeChange = (newValue: string) => {
    setDropdownScope(newValue);
  };

  const handleShowCyclesChange = () => {
    setShowCycles(!showCycles);
  };

  const handleConfigurePress = () => {
    Alert.alert(
      'Configure',
      'Configure statistics and other settings.',
      [
        {
          text: 'Cancel',
          style: 'cancel',
        },
        {
          text: 'OK',
          onPress: () => {
            // Show the CheckList modal
            // ...
          },
        },
      ]
    );
  };

  const _lineChart = () => {
    const data = team.scores.diceScores(dice).length > 1 ? (
      <LineChart
        style={styles.chart}
        config={{
          ...LineChartConfig.defaultConfig(),
          xAxis: {
            enabled: true,
            drawGridLines: false,
            valueFormatter: (value) => (value === Math.floor(value) ? (value + 1).toString() : ''),
            textColor: 'black',
            textSize: 10,
            drawAxisLine: true,
            axisMinimum: 0,
            axisMaximum: team.scores.diceScores(dice).length,
          },
          yAxis: {
            enabled: true,
            drawGridLines: true,
            valueFormatter: (value) => value.toString(),
            textColor: 'black',
            textSize: 10,
            drawAxisLine: true,
            axisMinimum: 0,
            axisMaximum: [
              event.statConfig.allianceTotal
                ? event.matches.values.reduce((a, b) => Math.max(a.alliance(team)?.combinedScore() || 0, b.alliance(team)?.combinedScore() || 0))
                : event.teams.reduce((a, b) => Math.max(a.maxScore(dice, event.statConfig.removeOutliers, null) || 0, b.maxScore(dice, event.statConfig.removeOutliers, null) || 0)),
              team.targetScore?.total() || 0,
            ].reduce((a, b) => Math.max(a, b)),
          },
          legend: {
            enabled: false,
          },
          data: {
            dataSets: [
              ...opModeExt.getAll().map((opModeType) => ({
                label: opModeType.getName(),
                config: {
                  drawCircles: true,
                  lineWidth: 2,
                  drawFilled: false,
                  mode: 'CUBIC_BEZIER',
                  color: opModeType.getColor(),
                  drawValues: false,
                  data: event.statConfig.allianceTotal
                    ? event.getSortedMatches(true)
                        .filter((e) => e.dice === dice || dice === Dice.none)
                        .map((e) => ({
                          x: e.matchNumber,
                          y: e.alliance(team)?.combinedScore() || 0,
                        }))
                        .map((e) => ({
                          ...e,
                          y: Math.floor(e.y)
                        }))
                        .filter((e) => e.y > 0)
                    : team.scores.diceScores(dice)
                        .map((e) => ({
                          x: e.matchNumber,
                          y: e.getScoreDivision(opModeType),
                        }))
                        .map((e) => ({
                          ...e,
                          y: Math.floor(e.y)
                        }))
                        .filter((e) => e.y > 0),
                },
              })),
            ],
          },
        }}
      />
    ) : (
      <Text style={styles.noData}>No data available</Text>
    );

    return (
      <View style={styles.chartContainer}>
        {data}
      </View>
    );
  };

  const handleMatchListPress = async () => {
    const { event, team } = this.props;
    const result = await PlatformGraphics.showModal(
      Platform.OS === 'ios'
        ? MatchList
        : MatchView,
      {
        event,
        team,
      }
    );
    if (result) {
      // Update the state after the modal closes
    }
  };

  const handleTargetPress = async () => {
    const { event, team } = this.props;
    if (team.targetScore === null) {
      team.targetScore = new Score(
        uuidv4(),
        Dice.none,
        event.gameName
      );
      await db
        .ref(`events/${event.key}/teams/${team.number}`)
        .set({
          ...team.toJson(),
          targetScore: team.targetScore?.toJson(),
        });
    }
    const result = await PlatformGraphics.showModal(
      MatchView,
      {
        event,
        team,
      }
    );
    if (result) {
      // Update the state after the modal closes
    }
  };

  const handleAutonPress = async () => {
    const { event, team } = this.props;
    const result = await PlatformGraphics.showModal(
      AutonDrawer,
      {
        event,
        team,
      }
    );
    if (result) {
      // Update the state after the modal closes
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.teamInfo}>
          <Text style={styles.teamName}>{team.name}</Text>
          <Text style={styles.teamNumber}>{team.number}</Text>
        </View>
        <View style={styles.headerActions}>
          <TouchableOpacity
            style={styles.settingsButton}
            onPress={handleConfigurePress}
          >
            <Text style={styles.settingsButtonText}>Configure</Text>
          </TouchableOpacity>
          {event.type === EventType.remote && (
            <TouchableOpacity
              style={styles.settingsButton}
              onPress={() => {
                // Navigate to Robot Iterations screen
                // ...
              }}
            >
              <Text style={styles.settingsButtonText}>Robot Iterations</Text>
            </TouchableOpacity>
          )}
        </View>
      </View>
      <View style={styles.diceContainer}>
        <Text style={styles.diceLabel}>Dice:</Text>
        <TouchableOpacity style={styles.diceDropdown} onPress={() => {}}>
          <Text style={styles.diceDropdownText}>{dice?.toVal(event.gameName) || 'All Cases'}</Text>
        </TouchableOpacity>
      </View>
      <View style={styles.selectionContainer}>
        {opModeExt.getAll().map((opModeType) => (
          <TouchableOpacity
            key={opModeType}
            style={[styles.selectionButton, { backgroundColor: getSelection(opModeType) ? opModeType.getColor() : null }]}
            onPress={() => updateSelections(opModeType)}
          >
            <Text style={styles.selectionButtonText}>{opModeType.getName()}</Text>
          </TouchableOpacity>
        ))}
      </View>
      <Collapsible
        isCollapsed={team.scores.diceScores(dice).length <= 1}
        style={styles.collapsible}
      >
        {showCycles ? (
          <View style={styles.cyclesContainer}>
            <Text style={styles.cyclesLabel}>Cycles:</Text>
            <TouchableOpacity style={styles.cyclesDropdown} onPress={() => {}}>
              <Text style={styles.cyclesDropdownText}>{dropdownScope}</Text>
            </TouchableOpacity>
          </View>
        ) : (
          _lineChart()
        )}
      </Collapsible>
      <View style={styles.buttonContainer}>
        {isSoleWindow && (
          <TouchableOpacity
            style={styles.button}
            onPress={handleMatchListPress}
          >
            <Text style={styles.buttonText}>Matches</Text>
          </TouchableOpacity>
        )}
        {isSoleWindow && (
          <TouchableOpacity
            style={styles.button}
            onPress={handleTargetPress}
          >
            <Text style={styles.buttonText}>Target</Text>
          </TouchableOpacity>
        )}
        {isSoleWindow && (
          <TouchableOpacity
            style={styles.button}
            onPress={handleAutonPress}
          >
            <Text style={styles.buttonText}>Auton</Text>
          </TouchableOpacity>
        )}
      </View>
      {opModeExt.getAll().map((opModeType) => (
        <ScoreCard
          key={opModeType}
          allianceTotal={event.statConfig.allianceTotal}
          team={team}
          event={event}
          targetScore={team.targetScore?.getScoreDivision(opModeType)}
          scoreDivisions={team.scores.sortedScores().map((e) => e.getScoreDivision(opModeType))}
          dice={dice}
          removeOutliers={event.statConfig.removeOutliers}
          matches={event.getSortedMatches(true)}
          title={opModeType.getName()}
          type={opModeType}
        />
      ))}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
  },
  teamInfo: {
    flexDirection: 'column',
  },
  teamName: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  teamNumber: {
    fontSize: 16,
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  settingsButton: {
    padding: 8,
    marginRight: 16,
    borderRadius: 4,
    backgroundColor: '#eee',
  },
  settingsButtonText: {
    fontSize: 14,
  },
  diceContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
  },
  diceLabel: {
    fontSize: 16,
    marginRight: 8,
  },
  diceDropdown: {
    padding: 8,
    borderRadius: 4,
    backgroundColor: '#eee',
  },
  diceDropdownText: {
    fontSize: 14,
  },
  selectionContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-around',
    padding: 16,
  },
  selectionButton: {
    padding: 8,
    margin: 4,
    borderRadius: 4,
  },
  selectionButtonText: {
    fontSize: 14,
  },
  chartContainer: {
    padding: 16,
  },
  chart: {
    height: 200,
  },
  noData: {
    fontSize: 16,
    textAlign: 'center',
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: 16,
  },
  button: {
    padding: 12,
    borderRadius: 4,
    backgroundColor: '#007bff',
  },
  buttonText: {
    fontSize: 16,
    color: '#fff',
  },
  collapsible: {
    padding: 16,
  },
  cyclesContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
  },
  cyclesLabel: {
    fontSize: 16,
    marginRight: 8,
  },
  cyclesDropdown: {
    padding: 8,
    borderRadius: 4,
    backgroundColor: '#eee',
  },
  cyclesDropdownText: {
    fontSize: 14,
  },
});

export default Team;