typescript
import React, { useState, useEffect } from 'react';
import {
  Platform,
  Alert,
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
  Dimensions,
  FlatList,
  Image,
  ActivityIndicator,
} from 'react-native';
import { useNavigation, useRoute } from '@react-navigation/native';
import { useRecoilValue, useSetRecoilState, useRecoilValueLoadable } from 'recoil';
import {
  eventState,
  dataModelState,
  statConfigState,
  autonDrawingState,
  matchState,
} from '../../atoms';
import { Event, Team, Score, Match, StatConfig, AutonDrawing } from '../../models';
import { OpModeType } from '../../models/ScoreModel';
import {
  getStatistic,
  maxScore,
  spots,
  removeOutliers,
  maxAllianceScore,
  getSortedMatches,
} from '../../functions/Statistics';
import { getAverage } from '../../functions/Extensions';
import { Dice, DiceExtension } from '../../models/GameModel';
import {
  LineChart,
  LineChartData,
  Grid,
  YAxis,
  XAxis,
  LineChartConfig,
} from '@chartiful/react-native-charts';

// Function to get the maximum score for a given opModeType
const getMaxScore = (
  event: Event,
  statConfig: StatConfig,
  dice: Dice,
  opModeType: OpModeType,
  removeOutliers: boolean
) => {
  if (statConfig.allianceTotal) {
    return maxAllianceScore(
      getSortedMatches(event.matches, true, dice),
      dice,
      removeOutliers
    );
  } else {
    return maxScore(
      event.teams.values,
      dice,
      removeOutliers,
      opModeType,
      statConfig,
      null,
      null,
      event.matches.values
    );
  }
};

const useTeams = () => {
  const navigation = useNavigation();
  const route = useRoute();
  const event = useRecoilValue(eventState);
  const dataModel = useRecoilValue(dataModelState);
  const setAutonDrawing = useSetRecoilState(autonDrawingState);
  const statConfig = useRecoilValue(statConfigState);
  const [dice, setDice] = useState<Dice>(Dice.none);
  const [selections, setSelections] = useState<{
    [key in OpModeType | null]: boolean;
  }>({
    null: true,
    OpModeType.auto: false,
    OpModeType.tele: false,
    OpModeType.endgame: false,
    OpModeType.penalty: false,
  });
  const [showCycles, setShowCycles] = useState(false);
  const [team, setTeam] = useState<Team | null>(null);
  const [maxScore, setMaxScore] = useState<Score | null>(null);
  const [teamMaxScore, setTeamMaxScore] = useState<Score | null>(null);
  const [autonDrawing, setAutonDrawing] = useState<AutonDrawing | null>(null);

  useEffect(() => {
    if (event && route.params && route.params.team) {
      setTeam(route.params.team);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [event, route.params]);

  useEffect(() => {
    if (event && team) {
      const newMaxScore = new Score('', Dice.none, event.gameName);
      newMaxScore.getElements().forEach((element) => {
        const maxCount = event.teams.values
          .map((team) => {
            if (!element.isBool) {
              return team.scores.values
                .map((score) =>
                  score.getElements().find(
                    (e) => e.key === element.key,
                    // eslint-disable-next-line @typescript-eslint/no-unused-vars
                    () => new ScoringElement(null, '')
                  )?.countFactoringAttempted()
                )
                .filter((count) => typeof count === 'number')
                .reduce((a, b) => a + b, 0) /
                team.scores.values.length;
            } else {
              return team.scores.values
                .map((score) =>
                  score.getElements().find(
                    (e) => e.key === element.key,
                    // eslint-disable-next-line @typescript-eslint/no-unused-vars
                    () => new ScoringElement(null, '')
                  )?.countFactoringAttempted()
                )
                .filter((count) => typeof count === 'number')
                .reduce((a, b) => a + b, 0) /
                team.scores.values.length;
            }
          })
          .reduce((a, b) => Math.max(a, b), 0);
        element.normalCount = maxCount;
      });
      setMaxScore(newMaxScore);

      const newTeamMaxScore = new Score('', Dice.none, event.gameName);
      newTeamMaxScore.getElements().forEach((element) => {
        const maxCount = !element.isBool
          ? team.scores.values
              .map((score) =>
                score.getElements().find(
                  (e) => e.key === element.key,
                  // eslint-disable-next-line @typescript-eslint/no-unused-vars
                  () => new ScoringElement(null, '')
                )?.countFactoringAttempted()
              )
              .filter((count) => typeof count === 'number')
              .reduce((a, b) => a + b, 0) /
              team.scores.values.length
          : team.scores.values
              .map((score) =>
                score.getElements().find(
                  (e) => e.key === element.key,
                  // eslint-disable-next-line @typescript-eslint/no-unused-vars
                  () => new ScoringElement(null, '')
                )?.countFactoringAttempted()
              )
              .filter((count) => typeof count === 'number')
              .reduce((a, b) => a + b, 0) /
              team.scores.values.length;
        element.normalCount = maxCount;
      });
      setTeamMaxScore(newTeamMaxScore);
    }
  }, [event, team]);

  useEffect(() => {
    const newAutonDrawing =
      event && team && event.teams[team.number]
        ? new AutonDrawing(
            team.number,
            event.teams[team.number].autonDrawing
          )
        : null;
    setAutonDrawing(newAutonDrawing);
  }, [event, team]);

  const handleDiceChange = (newDice: Dice) => {
    setDice(newDice);
  };

  const handleSelectionChange = (opModeType: OpModeType | null) => {
    setSelections({
      ...selections,
      [opModeType]: !selections[opModeType],
    });
  };

  const handleShowCyclesChange = () => {
    setShowCycles(!showCycles);
  };

  const getLineChartConfig = () => {
    const max =
      statConfig.allianceTotal && event
        ? getMaxScore(
            event,
            statConfig,
            dice,
            OpModeType.auto,
            statConfig.removeOutliers
          )
        : teamMaxScore
        ? teamMaxScore.total()
        : 0;
    const data =
      team &&
      event &&
      statConfig &&
      event.teams[team.number] &&
      event.matches
        ? team.scores.diceScores(dice)
            .map((score) => ({
              x: score.match.matchNumber,
              y: score.getScoreDivision(OpModeType.auto).total(),
            }))
            .filter((dataPoint) => typeof dataPoint.y === 'number')
            .sort((a, b) => a.x - b.x)
        : [];
    return {
      data,
      max: max,
    };
  };

  const handleMatchPress = () => {
    navigation.navigate('MatchList', {
      team: team,
      event: event,
      ascending: false,
    });
  };

  const handleTargetPress = () => {
    if (!team?.targetScore) {
      const newTargetScore = new Score(
        '',
        Dice.none,
        event.gameName
      );
      event.getRef()
        ?.child(`teams/${team.number}`)
        .update({
          targetScore: newTargetScore.toJson(),
        })
        .then(() => {
          dataModel.saveEvents();
        });
    }
    navigation.navigate('MatchView', {
      team: team,
      event: event,
    });
  };

  const handleAutonPress = () => {
    navigation.navigate('AutonDrawer', {
      team: team,
      event: event,
    });
  };

  const renderLineChart = () => {
    const lineChartConfig = getLineChartConfig();
    if (lineChartConfig.data.length > 0) {
      return (
        <View style={styles.lineChartContainer}>
          <LineChart
            config={{
              data: lineChartConfig.data,
              grid: {
                horizontal: {
                  show: true,
                  interval: 1,
                  color: '#ccc',
                  width: 1,
                },
                vertical: {
                  show: true,
                  interval: 1,
                  color: '#ccc',
                  width: 1,
                },
              },
              xAxis: {
                show: true,
                color: '#ccc',
                width: 1,
                tickSize: 10,
                tickTextColor: '#333',
                tickTextStyle: {
                  fontWeight: 'bold',
                },
              },
              yAxis: {
                show: true,
                color: '#ccc',
                width: 1,
                tickSize: 10,
                tickTextColor: '#333',
                tickTextStyle: {
                  fontWeight: 'bold',
                },
              },
              line: {
                strokeWidth: 2,
                color: '#007bff',
                smooth: true,
                dashArray: [5, 5],
              },
              padding: {
                top: 20,
                bottom: 20,
                left: 20,
                right: 20,
              },
              height: Dimensions.get('window').height * 0.3,
              width: Dimensions.get('window').width * 0.9,
            }}
            style={styles.lineChart}
          />
          <TouchableOpacity
            onPress={handleShowCyclesChange}
            style={styles.showCyclesButton}
          >
            <Text style={styles.showCyclesButtonText}>
              {showCycles ? 'Hide Cycles' : 'Show Cycles'}
            </Text>
          </TouchableOpacity>
        </View>
      );
    } else {
      return <Text>No data available</Text>;
    }
  };

  return {
    dice,
    setDice,
    selections,
    setSelections,
    showCycles,
    setShowCycles,
    team,
    setTeam,
    maxScore,
    teamMaxScore,
    autonDrawing,
    setAutonDrawing,
    handleDiceChange,
    handleSelectionChange,
    handleShowCyclesChange,
    renderLineChart,
    handleMatchPress,
    handleTargetPress,
    handleAutonPress,
    getMaxScore,
  };
};

const styles = StyleSheet.create({
  lineChartContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 20,
    marginBottom: 20,
  },
  lineChart: {
    backgroundColor: 'transparent',
  },
  showCyclesButton: {
    position: 'absolute',
    top: 10,
    right: 10,
    padding: 10,
    backgroundColor: '#fff',
    borderRadius: 5,
  },
  showCyclesButtonText: {
    color: '#000',
    fontSize: 12,
    fontWeight: 'bold',
  },
});

export default useTeams;