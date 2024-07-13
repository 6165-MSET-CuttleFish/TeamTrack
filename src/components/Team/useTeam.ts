typescript
import React, { useState, useEffect, useRef, useContext } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Platform, Alert, Modal, Image, FlatList } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useRoute } from '@react-navigation/native';
import { LineChart, Grid, YAxis, XAxis } from 'react-native-charts-wrapper';
import { useTheme } from '@react-navigation/native';
import {
  OpModeType,
  Score,
  ScoringElement,
  Dice,
  GameType,
  Event,
  Team,
  GameModel,
  Match,
  EventModel,
} from '../../models';
import { MatchList } from '../Match/MatchList';
import { MatchView } from '../Match/MatchView';
import { ChangeList } from '../Change/ChangeList';
import { ScoreCard } from '../Score/ScoreCard';
import { Collapsible } from '../../components/Misc/Collapsible';
import { EmptyList } from '../../components/Misc/EmptyList';
import { AutonDrawer } from './AutonDrawer';
import { CheckList } from '../../components/Statistics/CheckList';
import { StatConfig, AppModel } from '../../models';
import { v4 as uuidv4 } from 'uuid';
import { getDatabase, ref, onValue, runTransaction, get } from 'firebase/database';
import { getStorage, ref as storageRef, uploadBytes, getDownloadURL } from 'firebase/storage';
import { DatabaseContext } from '../../contexts/DatabaseContext';
import { AutonPainter } from '../../components/AutonomousDrawingTool';
import { useTranslation } from 'react-i18next';
import { getStatistic, getLessIsBetter, spots } from '../../functions/Statistics';
import { percentIncrease, maxValue } from '../../functions/Extensions';
import { getScoreDivision, diceScores, sortedScores } from '../../models/ScoreModel';

const db = getDatabase();
const storage = getStorage();

type TeamViewProps = {
  team: Team;
  event: Event;
  isSoleWindow?: boolean;
};

const useTeam = ({ team, event, isSoleWindow = true }: TeamViewProps) => {
  const navigation = useNavigation();
  const route = useRoute();
  const [dice, setDice] = useState<Dice>(Dice.none);
  const [selections, setSelections] = useState<{ [key: string]: boolean }>({
    null: true,
    OpModeType.auto: false,
    OpModeType.tele: false,
    OpModeType.endgame: false,
    OpModeType.penalty: false,
  });
  const [maxScore, setMaxScore] = useState<Score | null>(null);
  const [teamMaxScore, setTeamMaxScore] = useState<Score | null>(null);
  const [showCycles, setShowCycles] = useState<boolean>(false);
  const [autonData, setAutonData] = useState<string | null>(null);
  const { colors } = useTheme();
  const { t } = useTranslation();
  const { eventRef } = useContext(DatabaseContext);
  const painterRef = useRef<AutonPainter | null>(null);
  const [autonImage, setAutonImage] = useState<string | null>(null);
  const [autonLoading, setAutonLoading] = useState<boolean>(false);
  const [autonError, setAutonError] = useState<string | null>(null);

  useEffect(() => {
    painterRef.current = new AutonPainter(team, event);
  }, []);

  useEffect(() => {
    const unsubscribe = onValue(ref(db, `events/${event.id}`), (snapshot) => {
      const eventData = snapshot.val();
      if (eventData) {
        event.updateLocal(eventData);
        const updatedTeam = event.teams[team.number];
        if (updatedTeam) {
          team = updatedTeam;
        }
        updateMaxScore();
        updateTeamMaxScore();
      }
    });

    return () => unsubscribe();
  }, []);

  const updateMaxScore = () => {
    const newMaxScore = new Score('', Dice.none, event.gameName);
    newMaxScore.getElements().forEach((element) => {
      element.normalCount = !element.isBool
        ? Object.values(event.teams).map(
            (team) =>
              !element.isBool
                ? team.scores.values.map(
                    (score) =>
                      score
                        .getElements()
                        .find((e) => e.key === element.key)?.countFactoringAttempted() || 0
                  )
                  .filter((value) => typeof value === 'number')
                  .reduce((a, b) => a + b, 0) / team.scores.values.length
                : team.scores.values.map(
                    (score) =>
                      score
                        .getElements()
                        .find((e) => e.key === element.key)?.countFactoringAttempted() || 0
                  )
                  .filter((value) => typeof value === 'number')
                  .reduce((a, b) => a + b, 0) / team.scores.values.length
          )
          .reduce((a, b) => Math.max(a, b), 0)
        : Object.values(event.teams).map(
            (team) =>
              !element.isBool
                ? team.scores.values.map(
                    (score) =>
                      score
                        .getElements()
                        .find((e) => e.key === element.key)?.countFactoringAttempted() || 0
                  )
                  .filter((value) => typeof value === 'number')
                  .reduce((a, b) => a + b, 0) / team.scores.values.length
                : team.scores.values.map(
                    (score) =>
                      score
                        .getElements()
                        .find((e) => e.key === element.key)?.countFactoringAttempted() || 0
                  )
                  .filter((value) => typeof value === 'number')
                  .reduce((a, b) => a + b, 0) / team.scores.values.length
          )
          .reduce((a, b) => Math.max(a, b), 0);
    });
    setMaxScore(newMaxScore);
  };

  const updateTeamMaxScore = () => {
    const newTeamMaxScore = new Score('', Dice.none, event.gameName);
    newTeamMaxScore.getElements().forEach((element) => {
      element.normalCount = !element.isBool
        ? team.scores.values.map(
            (score) =>
              !element.isBool
                ? score
                  .getElements()
                  .find((e) => e.key === element.key)?.countFactoringAttempted() || 0
                : score
                  .getElements()
                  .find((e) => e.key === element.key)?.countFactoringAttempted() || 0
          )
          .filter((value) => typeof value === 'number')
          .reduce((a, b) => a + b, 0) / team.scores.values.length
        : team.scores.values.map(
            (score) =>
              !element.isBool
                ? score
                  .getElements()
                  .find((e) => e.key === element.key)?.countFactoringAttempted() || 0
                : score
                  .getElements()
                  .find((e) => e.key === element.key)?.countFactoringAttempted() || 0
          )
          .filter((value) => typeof value === 'number')
          .reduce((a, b) => a + b, 0) / team.scores.values.length;
    });
    setTeamMaxScore(newTeamMaxScore);
  };

  useEffect(() => {
    const unsubscribe = onValue(ref(db, `events/${event.id}/teams/${team.number}/autonData`), (snapshot) => {
      const autonData = snapshot.val();
      if (autonData) {
        setAutonData(autonData);
      }
    });

    return () => unsubscribe();
  }, []);

  useEffect(() => {
    if (autonData) {
      setAutonLoading(true);
      const storageRef = storageRef(storage, `events/${event.id}/teams/${team.number}/autonData.svg`);
      getDownloadURL(storageRef)
        .then((url) => setAutonImage(url))
        .catch((error) => {
          setAutonError('Error loading auton data');
          console.error('Error loading auton data:', error);
        })
        .finally(() => setAutonLoading(false));
    }
  }, [autonData]);

  const getSelection = (opModeType: OpModeType | null) => selections[opModeType] ?? false;

  const handleDiceChange = (newValue: Dice) => {
    setDice(newValue);
  };

  const handleOpModeSelection = (opModeType: OpModeType | null) => {
    setSelections((prevSelections) => ({
      ...prevSelections,
      [opModeType]: !prevSelections[opModeType],
    }));
  };

  const handleAutonData = (data: string) => {
    setAutonData(data);
  };

  const handleShowCycles = () => {
    setShowCycles((prevShowCycles) => !prevShowCycles);
  };

  const handleMatchListPress = async () => {
    const result = await navigation.push(MatchList, {
      event: event,
      team: team,
      ascending: false,
    });
    if (result) {
      // Handle result if needed
    }
  };

  const handleTargetPress = async () => {
    if (team.targetScore == null) {
      team.targetScore = new Score(uuidv4(), Dice.none, event.gameName);
      await runTransaction(ref(db, `events/${event.id}/teams/${team.number}`), (mutableData) => {
        (mutableData as any)['targetScore'] = team.targetScore.toJson();
        return Transaction.success(mutableData);
      });
      AppModel.saveEvents();
    }
    const result = await navigation.push(MatchView, {
      event: event,
      team: team,
    });
    if (result) {
      // Handle result if needed
    }
  };

  const handleAutonPress = async () => {
    const result = await navigation.push(AutonDrawer, {
      event: event,
      team: team,
      handleAutonData,
    });
    if (result) {
      // Handle result if needed
    }
  };

  const handleConfigurePress = () => {
    Alert.alert(
      t('Configure Statistics'),
      '',
      [
        {
          text: t('Cancel'),
          style: 'cancel',
        },
        {
          text: t('Configure'),
          onPress: () => {
            navigation.navigate('CheckList', {
              event: event,
              statConfig: event.statConfig,
              showSorting: false,
            });
          },
        },
      ],
      { cancelable: true }
    );
  };

  const handleRobotIterationsPress = () => {
    navigation.push(ChangeList, {
      team: team,
      event: event,
    });
  };

  const lineChartConfig = () => {
    let max = event.statConfig.allianceTotal
      ? Object.values(event.matches).reduce((a, b) => (a.allianceScore(team, dice) || 0) > (b.allianceScore(team, dice) || 0) ? a : b).allianceScore(team, dice) || 0
      : Object.values(event.teams)
          .map((team) => {
            const score = team.scores.diceScores(dice).reduce((a, b) => (a.total() || 0) > (b.total() || 0) ? a : b);
            return score.total() || 0;
          })
          .reduce((a, b) => Math.max(a, b), 0);
    return {
      data: {
        dataSets: [
          ...Object.keys(selections)
            .filter((opModeType) => selections[opModeType])
            .map((opModeType: OpModeType | null) => {
              const spotsData = event.statConfig.allianceTotal
                ? Object.values(event.matches)
                    .filter((match) => match.dice === dice || dice === Dice.none)
                    .map((match) => {
                      return {
                        x: match.matchNumber,
                        y: match.allianceScore(team, dice) || 0,
                      };
                    })
                : team.scores.diceScores(dice).map((score) => {
                    const scoreValue = getScoreDivision(score, opModeType as OpModeType);
                    return {
                      x: score.matchNumber,
                      y: scoreValue.total() || 0,
                    };
                  });
              return {
                values: spotsData,
                config: {
                  label: opModeType ? opModeType.getName() : 'All',
                  drawCircles: true,
                  lineWidth: 2,
                  drawCubicIntensity: 0.2,
                  circleRadius: 3,
                  circleColor: {
                    normal: { color: colors.primary },
                    highlight: { color: colors.primary },
                  },
                  color: { color: colors.primary },
                },
              };
            }),
        ],
        config: {
          xAxis: {
            enabled: true,
            granularityEnabled: true,
            drawGridLines: true,
            drawLabels: true,
            labelRotationAngle: -30,
            valueFormatter: (value) => `${value}`,
            position: 'BOTTOM',
            drawAxisLine: true,
            axisMinimum: 0,
            axisMaximum: Object.values(event.matches).length,
          },
          yAxis: {
            drawGridLines: true,
            drawLabels: true,
            position: 'LEFT',
            drawAxisLine: true,
            axisMinimum: 0,
            axisMaximum: max,
            valueFormatter: (value) => `${value}`,
          },
          drawGridBackground: true,
          borderColor: { color: colors.primary },
          gridBackgroundColor: { color: colors.primary },
          gridColor: { color: colors.primary },
          drawBorders: true,
          legend: {
            enabled: true,
            textColor: { color: colors.primary },
            form: 'CIRCLE',
            formSize: 10,
            textSize: 12,
          },
        },
      },
    };
  };

  const renderAutonData = () => {
    if (autonLoading) {
      return (
        <View style={styles.autonContainer}>
          <Text style={styles.autonTitle}>{t('Loading Auton Data')}</Text>
        </View>
      );
    }

    if (autonError) {
      return (
        <View style={styles.autonContainer}>
          <Text style={styles.autonTitle}>{t('Error Loading Auton Data')}</Text>
        </View>
      );
    }

    if (autonImage) {
      return (
        <View style={styles.autonContainer}>
          <Image
            source={{ uri: autonImage }}
            style={{ width: '100%', height: 200 }}
            resizeMode="contain"
          />
        </View>
      );
    }

    return (
      <View style={styles.autonContainer}>
        <Text style={styles.autonTitle}>{t('No Auton Data Available')}</Text>
      </View>
    );
  };

  return {
    dice,
    handleDiceChange,
    selections,
    handleOpModeSelection,
    maxScore,
    teamMaxScore,
    showCycles,
    handleShowCycles,
    handleMatchListPress,
    handleTargetPress,
    handleAutonPress,
    handleConfigurePress,
    handleRobotIterationsPress,
    lineChartConfig,
    renderAutonData,
  };
};

const styles = StyleSheet.create({
  autonContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    margin: 10,
    padding: 10,
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 5,
  },
  autonTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 10,
  },
});

export default useTeam;