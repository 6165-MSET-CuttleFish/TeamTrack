typescript
import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, Platform } from 'react-native';
import { useNavigation, useRoute } from '@react-navigation/native';
import { Dropdown } from 'react-native-element-dropdown';
import { LineChart } from 'react-native-chart-kit';
import { Dice } from '../models/GameModel';
import { Team, Event, EventType, OpModeType } from '../models/AppModel';
import { Score } from '../models/ScoreModel';
import { Collapsible } from '../components/misc/Collapsible';
import { EmptyList } from '../components/misc/EmptyList';
import { PlatformGraphics } from '../components/misc/PlatformGraphics';
import { ScoreCard } from '../components/scores/ScoreCard';
import { MatchList } from '../views/home/match/MatchList';
import { MatchView } from '../views/home/match/MatchView';
import { ChangeList } from '../views/home/change/ChangeList';
import { AutonDrawer } from '../views/home/team/AutonDrawer';
import { v4 as uuidv4 } from 'uuid';
import { database, storage } from '../firebase';
import { Statistics } from '../functions/Statistics';
import { Extensions } from '../functions/Extensions';
import { AutonPainter } from '../components/AutonomousDrawingTool';
import { useDatabase } from '../hooks/useDatabase';

const scopeMarks = ['', 'Both_Side', 'Red_Side', 'Blue_Side'];
let dropdownScope = scopeMarks[0];

interface TeamViewProps {
  team: Team;
  event: Event;
  isSoleWindow?: boolean;
}

const TeamView = ({ team, event, isSoleWindow = true }: TeamViewProps) => {
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
  const [painter, setPainter] = useState<AutonPainter | null>(null);
  const navigation = useNavigation();
  const route = useRoute();
  const { getEventRef } = useDatabase();

  useEffect(() => {
    const initialMaxScore = new Score('', Dice.none, event.gameName);
    initialMaxScore.getElements().forEach((element) => {
      element.normalCount = event.teams.values
        .map((team) => {
          return !element.isBool
            ? team.scores.values
                .map((score) => {
                  return score.getElements().find((e) => e.key === element.key)
                    ?.countFactoringAttempted() || 0;
                })
                .filter((value): value is number => typeof value === 'number')
                .reduce((a, b) => a + b, 0) / event.teams.values.length
            : team.scores.values
                .map((score) => {
                  return score.getElements().find((e) => e.key === element.key)
                    ?.countFactoringAttempted() || 0;
                })
                .filter((value): value is number => typeof value === 'number')
                .reduce((a, b) => a + b, 0) / event.teams.values.length;
        })
        .reduce((a, b) => Math.max(a, b), 0) as number;
    });

    setMaxScore(initialMaxScore);

    setPainter(new AutonPainter({ team: team, event: event }));

    const unsubscribe = getEventRef(event.key)?.onValue((snapshot) => {
      const data = snapshot.val();
      if (data) {
        event.updateLocal(data, null); // Pass null for context as it's not available here
        const updatedTeam = event.teams[team.number] || Team.nullTeam();
        const updatedTeamMaxScore = new Score('', Dice.none, event.gameName);
        updatedTeamMaxScore.getElements().forEach((element) => {
          element.normalCount = !element.isBool
            ? updatedTeam.scores.values
                .map((score) => {
                  return score.getElements().find((e) => e.key === element.key)
                    ?.countFactoringAttempted() || 0;
                })
                .filter((value): value is number => typeof value === 'number')
                .reduce((a, b) => a + b, 0) / updatedTeam.scores.values.length
            : updatedTeam.scores.values
                .map((score) => {
                  return score.getElements().find((e) => e.key === element.key)
                    ?.countFactoringAttempted() || 0;
                })
                .filter((value): value is number => typeof value === 'number')
                .reduce((a, b) => a + b, 0) / updatedTeam.scores.values.length;
        });
        setTeamMaxScore(updatedTeamMaxScore);
      }
    });

    return () => {
      unsubscribe?.();
    };
  }, [event, team, getEventRef]);

  const getSelection = (opModeType: OpModeType | null) =>
    selections[opModeType] ?? false;

  const handleDiceChange = (newValue: Dice) => {
    setDice(newValue);
  };

  const handleOpModeChange = (opModeType: OpModeType) => {
    setSelections((prevSelections) => ({
      ...prevSelections,
      [opModeType]: !prevSelections[opModeType],
    }));
  };

  const handleShowCycles = () => {
    setShowCycles(!showCycles);
  };

  const navigateToMatchList = () => {
    navigation.navigate('MatchList', {
      event: event,
      team: team,
      ascending: false,
    });
  };

  const navigateToMatchView = async () => {
    if (!team.targetScore) {
      team.targetScore = new Score(uuidv4(), Dice.none, event.gameName);
      await database
        .ref(`teams/${team.number}`)
        .update({ targetScore: team.targetScore.toJson() });
    }
    navigation.navigate('MatchView', { event: event, team: team });
  };

  const navigateToAutonDrawer = () => {
    navigation.navigate('AutonDrawer', { event: event, team: team });
  };

  const renderLineChart = () => {
    if (team.scores.diceScores(dice).length > 1) {
      return (
        <View style={styles.chartContainer}>
          <LineChart
            data={{
              labels: event.statConfig.allianceTotal
                ? event.getSortedMatches(true)
                    .filter((e) => e.dice === dice || dice === Dice.none)
                    .map((match, index) => (index + 1).toString())
                : team.scores.diceScores(dice).map((score, index) =>
                    (index + 1).toString(),
                  ),
              datasets: [
                ...Object.values(OpModeType).map((opModeType) => ({
                  data: event.statConfig.allianceTotal
                    ? event.getSortedMatches(true)
                        .filter((e) => e.dice === dice || dice === Dice.none)
                        .map((match) => {
                          return match.getScoreDivision(opModeType)?.total() || 0;
                        })
                        .removeOutliers(event.statConfig.removeOutliers)
                    : team.scores.diceScores(dice).map((score) =>
                        score.getScoreDivision(opModeType)?.total() || 0,
                      ),
                  color: opModeType.getColor(),
                  strokeWidth: 2,
                })),
              ],
            }}
            width={PlatformGraphics.screenWidth(0.9)}
            height={220}
            yAxisLabel="$"
            yAxisSuffix="k"
            yAxisInterval={1} // optional, defaults to 1
            chartConfig={{
              backgroundColor: '#1cc910',
              backgroundGradientFrom: '#eff3ff',
              backgroundGradientTo: '#eff3ff',
              decimalPlaces: 2, // optional, defaults to 2dp
              color: (opacity = 1) => `rgba(0, 0, 0, ${opacity})`,
              labelColor: (opacity = 1) => `rgba(0, 0, 0, ${opacity})`,
              style: {
                borderRadius: 16,
              },
              propsForDots: {
                r: '6',
                strokeWidth: '2',
                stroke: '#ffa726',
              },
            }}
            bezier
            style={{
              marginVertical: 8,
              borderRadius: 16,
            }}
          />
          <TouchableOpacity
            style={styles.cycleButton}
            onPress={handleShowCycles}
          >
            <Text style={styles.cycleButtonText}>
              {showCycles ? 'Show Matches' : 'Show Cycles'}
            </Text>
          </TouchableOpacity>
        </View>
      );
    } else {
      return <EmptyList />;
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <View style={styles.headerContent}>
          <Text style={styles.headerTitle}>
            {team.name}
            {team.number === '6165' && <Text style={styles.headerSubTitle}>
              {team.number}
            </Text>}
          </Text>
          {team.number !== '6165' && (
            <Text style={styles.headerSubTitle}>{team.number}</Text>
          )}
        </View>
        <View style={styles.headerActions}>
          <Dropdown
            style={styles.dropdown}
            data={scopeMarks.map((value, index) => ({
              label: value,
              value: index.toString(),
            }))}
            search={false}
            labelField="label"
            valueField="value"
            placeholder="All Cases"
            value={dropdownScope}
            onChange={(item) => {
              dropdownScope = item.value;
            }}
          />
          <TouchableOpacity
            style={styles.settingsButton}
            onPress={() => {
              navigation.navigate('CheckList', {
                state: this, // Pass 'this' for state
                statConfig: event.statConfig,
                event: event,
                showSorting: false,
              });
            }}
          >
            <Text style={styles.settingsButtonText}>Settings</Text>
          </TouchableOpacity>
          {event.type === EventType.remote && (
            <TouchableOpacity
              style={styles.listButton}
              onPress={() => {
                navigation.navigate('ChangeList', {
                  team: team,
                  event: event,
                });
              }}
            >
              <Text style={styles.listButtonText}>Iterations</Text>
            </TouchableOpacity>
          )}
        </View>
      </View>
      <FlatList
        data={Object.values(OpModeType)}
        keyExtractor={(opModeType) => opModeType.toString()}
        renderItem={({ item: opModeType }) => (
          <ScoreCard
            allianceTotal={event.statConfig.allianceTotal}
            team={team}
            event={event}
            targetScore={
              team.targetScore?.getScoreDivision(opModeType) || null
            }
            scoreDivisions={team.scores
              .sortedScores()
              .map((e) => e.getScoreDivision(opModeType))
              .filter(Boolean) as Score[]}
            dice={dice}
            removeOutliers={event.statConfig.removeOutliers}
            matches={event.getSortedMatches(true)}
            title={opModeType.getName()}
            type={opModeType}
          />
        )}
      />
      <Collapsible
        isCollapsed={team.scores.diceScores(dice).length <= 1}
      >
        <View style={styles.opModeButtons}>
          {Object.values(OpModeType).map((opModeType) => (
            <TouchableOpacity
              key={opModeType.toString()}
              style={[
                styles.opModeButton,
                getSelection(opModeType)
                  ? { backgroundColor: opModeType.getColor() }
                  : null,
              ]}
              onPress={() => handleOpModeChange(opModeType)}
            >
              <Text style={styles.opModeButtonText}>
                {opModeType.getName()}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
        {renderLineChart()}
      </Collapsible>
      <View style={styles.buttonContainer}>
        {isSoleWindow && (
          <TouchableOpacity
            style={styles.button}
            onPress={navigateToMatchList}
          >
            <Text style={styles.buttonText}>Matches</Text>
          </TouchableOpacity>
        )}
        {isSoleWindow && (
          <TouchableOpacity style={styles.button} onPress={navigateToMatchView}>
            <Text style={styles.buttonText}>Target</Text>
          </TouchableOpacity>
        )}
        {isSoleWindow && (
          <TouchableOpacity
            style={styles.button}
            onPress={navigateToAutonDrawer}
          >
            <Text style={styles.buttonText}>Auton</Text>
          </TouchableOpacity>
        )}
      </View>
    </View>
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
    backgroundColor: '#f0f0f0',
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  headerSubTitle: {
    fontSize: 16,
    marginLeft: 8,
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  settingsButton: {
    padding: 8,
    borderRadius: 8,
    backgroundColor: '#ddd',
    marginLeft: 16,
  },
  settingsButtonText: {
    fontSize: 16,
  },
  listButton: {
    padding: 8,
    borderRadius: 8,
    backgroundColor: '#ddd',
    marginLeft: 16,
  },
  listButtonText: {
    fontSize: 16,
  },
  dropdown: {
    width: 120,
    marginLeft: 16,
  },
  opModeButtons: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: 16,
  },
  opModeButton: {
    padding: 8,
    borderRadius: 8,
    backgroundColor: '#eee',
  },
  opModeButtonText: {
    fontSize: 14,
  },
  chartContainer: {
    padding: 16,
  },
  cycleButton: {
    position: 'absolute',
    top: 16,
    right: 16,
    padding: 8,
    borderRadius: 8,
    backgroundColor: '#ddd',
  },
  cycleButtonText: {
    fontSize: 14,
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: 16,
    marginBottom: 16,
  },
  button: {
    padding: 12,
    borderRadius: 8,
    backgroundColor: '#007bff',
    width: PlatformGraphics.screenWidth(0.3),
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    textAlign: 'center',
  },
});

export default TeamView;