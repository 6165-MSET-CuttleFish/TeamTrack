typescript
import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useGlobalState } from '../../GlobalState';
import { Event, Team, OpModeType, ScoringElement, StatConfig, Statistics } from '../../models';
import { getStatistic, removeOutliers, spots } from '../../functions/Statistics';
import { PlatformProgressIndicator, PlatformAlert, showPlatformDialog } from '../../components/misc/PlatformGraphics';
import { BarGraph } from '../../components/statistics/BarGraph';
import { PercentChange } from '../../components/statistics/PercentChange';
import { getWLT, getMatches } from '../../functions/Extensions';
import { getScoreDivision, customStatisticScore } from '../../models/ScoreModel';

interface TeamCardListProps {
  event: Event;
  sortMode: OpModeType | null;
  elementSort: ScoringElement | null;
  statConfig: StatConfig;
  statistics: Statistics;
}

const TeamCardList: React.FC<TeamCardListProps> = ({ event, sortMode, elementSort, statConfig, statistics }) => {
  const [teams, setTeams] = useState<Team[]>([]);
  const [max, setMax] = useState<number>(0);
  const [isUserTeam, setIsUserTeam] = useState<boolean>(false);
  const navigation = useNavigation();
  const { dataModel } = useGlobalState();

  useEffect(() => {
    const isUserTeam = event.teams.values.some(
      (team) =>
        event.userTeam?.number !== null && team.number === event.userTeam?.number
    );
    setIsUserTeam(isUserTeam);
  }, [event]);

  useEffect(() => {
    let teams = event.teams.sortedTeams(
      sortMode,
      elementSort,
      statConfig,
      event.matches.values.toList(),
      statistics
    );

    if (statConfig.allianceTotal) {
      teams = teams.sort((a, b) => {
        const aScore = getMatches(event, a)
          .map((e) => e.alliance(a)?.combinedScore())
          .whereType<Score>()
          .getStatistic(statistics.getFunction());
        const bScore = getMatches(event, b)
          .map((e) => e.alliance(b)?.combinedScore())
          .whereType<Score>()
          .getStatistic(statistics.getFunction());
        return bScore - aScore;
      });
    }

    setTeams(teams);
  }, [event, sortMode, elementSort, statConfig, statistics]);

  useEffect(() => {
    let max = event.teams.maxCustomStatisticScore(
      'none', // TODO: Check if this should be Dice.none
      statConfig.removeOutliers,
      statistics,
      sortMode,
      elementSort
    );

    if (statConfig.allianceTotal) {
      max = event.teams.values
        .map(
          (e) =>
            spots(
              e,
              'none', // TODO: Check if this should be Dice.none
              statConfig.showPenalties,
              type: sortMode,
              element: elementSort
            )
            .removeOutliers(statConfig.removeOutliers)
            .map((spot) => spot.y)
            .getStatistic(statistics.getFunction())
        )
        .reduce((a, b) => Math.max(a, b));
    }

    setMax(max);
  }, [event, sortMode, elementSort, statConfig, statistics]);

  const wltColor = (i: number) => {
    if (i === 0) {
      return 'green';
    } else if (i === 1) {
      return 'red';
    } else {
      return 'grey';
    }
  };

  const handleTeamPress = (team: Team) => {
    navigation.navigate('TeamView', { team, event });
  };

  const handleDeleteTeam = (team: Team) => {
    showPlatformDialog({
      title: 'Delete Team',
      content: 'Are you sure?',
      actions: [
        {
          isDefaultAction: true,
          child: 'Cancel',
          onPress: () => navigation.pop(),
        },
        {
          isDefaultAction: false,
          isDestructive: true,
          child: 'Confirm',
          onPress: () => {
            const deletionResult = event.deleteTeam(team);
            dataModel.saveEvents();
            navigation.pop();
            if (deletionResult !== null) {
              showPlatformDialog({
                title: 'Error',
                content: 'Team is present in matches',
                actions: [
                  {
                    child: 'Okay',
                    isDefaultAction: true,
                    onPress: () => navigation.pop(),
                  },
                ],
              });
            }
          },
        },
      ],
    });
  };

  const renderTeamCard = ({ item: team }: { item: Team }) => {
    const percentIncrease = statConfig.allianceTotal
      ? getMatches(event, team)
          .map((e) => e.alliance(team)?.combinedScore())
          .whereType<Score>()
          .percentIncrease(elementSort)
      : team.scores.values
          .map((e) => getScoreDivision(e, sortMode))
          .percentIncrease(elementSort);

    const wlt = getWLT(team, event)?.split('-');

    return (
      <TouchableOpacity onPress={() => handleTeamPress(team)} style={styles.teamCard}>
        <View style={styles.teamInfo}>
          <Text style={styles.teamNumber}>{team.number}</Text>
          <View style={styles.teamNameContainer}>
            <Text style={styles.teamName}>{team.name}</Text>
            {wlt && (
              <View style={styles.wltContainer}>
                {wlt.map((wltValue, index) => (
                  <Text key={index} style={{ color: wltColor(index) }}>
                    {wltValue}
                    {index < wlt.length - 1 && '-'}
                  </Text>
                ))}
              </View>
            )}
          </View>
        </View>
        <View style={styles.trailingContainer}>
          {percentIncrease !== null && percentIncrease.isFinite && (
            <PercentChange percentIncrease={percentIncrease} lessIsBetter={sortMode?.getLessIsBetter()} />
          )}
          <BarGraph
            height={60}
            width={15}
            vertical={false}
            val={
              statConfig.allianceTotal
                ? getMatches(event, team)
                    .map((e) => e.alliance(team)?.combinedScore())
                    .whereType<Score>()
                    .getStatistic(statistics.getFunction())
                : customStatisticScore(
                    team,
                    'none', // TODO: Check if this should be Dice.none
                    statConfig.removeOutliers,
                    statistics,
                    sortMode,
                    elementSort
                  )
            }
            max={max}
            title=""
            compressed={true}
            lessIsBetter={
              (statistics.getLessIsBetter() || sortMode?.getLessIsBetter()) &&
              !(statistics.getLessIsBetter() && sortMode?.getLessIsBetter())
            }
          />
          <TouchableOpacity onPress={() => handleDeleteTeam(team)} style={styles.deleteButton}>
            <Text style={styles.deleteButtonText}>Delete</Text>
          </TouchableOpacity>
        </View>
      </TouchableOpacity>
    );
  };

  return (
    <View style={styles.container}>
      {event.shared && !teams.length && (
        <View style={styles.loadingContainer}>
          <PlatformProgressIndicator />
        </View>
      )}
      {teams.length === 0 && !event.shared && (
        <View style={styles.emptyListContainer}>
          <Text style={styles.emptyListText}>No teams found</Text>
        </View>
      )}
      {teams.length > 0 && (
        <FlatList
          data={teams}
          keyExtractor={(team) => team.number.toString()}
          renderItem={renderTeamCard}
          style={styles.teamList}
        />
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  teamList: {
    paddingHorizontal: 16,
  },
  teamCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    marginVertical: 8,
    backgroundColor: '#fff',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  teamInfo: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  teamNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    marginRight: 16,
  },
  teamNameContainer: {
    flex: 1,
  },
  teamName: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 4,
  },
  wltContainer: {
    flexDirection: 'row',
  },
  trailingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  deleteButton: {
    padding: 8,
    borderRadius: 4,
    backgroundColor: 'red',
    marginLeft: 16,
  },
  deleteButtonText: {
    color: '#fff',
    fontWeight: 'bold',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyListContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyListText: {
    fontSize: 18,
  },
});

export default TeamCardList;