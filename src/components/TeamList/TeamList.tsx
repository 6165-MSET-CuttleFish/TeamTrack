tsx
import React, { useState, useEffect, useContext } from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { PlatformAlert, PlatformDialogAction } from 'react-native-platform-dialog';
import { showPlatformDialog } from 'react-native-platform-dialog';
import {  PlatformProgressIndicator } from 'react-native-platform-graphics';
import { Slidable, SlidableAction } from 'react-native-slidable';

import { Event, Team, OpModeType, ScoringElement, StatConfig } from '../models/AppModel';
import { Dice, removeOutliers, getStatistic, maxValue, spots, sortedTeams, orderedTeams, maxCustomStatisticScore } from '../functions/Statistics';
import { ExampleTeamRow } from './ExampleTeamRow';
import { TeamRow } from './TeamRow';
import { TeamView } from './TeamView';
import { AppContext } from '../context/AppContext';

interface TeamListProps {
  event: Event;
  sortMode: OpModeType | null;
  elementSort: ScoringElement | null;
  statConfig: StatConfig;
  statistic: any;
}

const TeamList: React.FC<TeamListProps> = ({ event, sortMode, elementSort, statConfig, statistic }) => {
  const [isUserTeam, setIsUserTeam] = useState(false);
  const navigation = useNavigation();
  const { dataModel } = useContext(AppContext);

  useEffect(() => {
    setIsUserTeam(event.teams.values.some(team => event.userTeam?.number !== null && team.number === event.userTeam?.number));
  }, [event.teams, event.userTeam]);

  const [max, setMax] = useState(0);
  const [teams, setTeams] = useState<Team[]>([]);

  useEffect(() => {
    let maxScore = 0;
    let sortedTeamArray: Team[] = [];

    if (statConfig.allianceTotal) {
      maxScore = event.teams.values
        .map(e => event.matches.values
          .toList()
          .spots(e, Dice.none, statConfig.showPenalties, type: sortMode)
          .removeOutliers(statConfig.removeOutliers)
          .map(spot => spot.y)
          .getStatistic(statistic.getFunction())
        )
        .maxValue();
    } else {
      maxScore = maxCustomStatisticScore(event.teams, Dice.none, statConfig.removeOutliers, statistic, sortMode, elementSort);
    }

    sortedTeamArray = statConfig.sorted
      ? sortedTeams(event.teams, sortMode, elementSort, statConfig, event.matches.values.toList(), statistic)
      : orderedTeams(event.teams);

    setMax(maxScore);
    setTeams(sortedTeamArray);
  }, [event.teams, event.matches, sortMode, elementSort, statConfig, statistic]);

  const handleTeamPress = async (team: Team) => {
    navigation.navigate('TeamView', { team, event });
  };

  const handleDeleteTeam = async (team: Team) => {
    showPlatformDialog({
      title: 'Delete Team',
      content: 'Are you sure?',
      actions: [
        {
          text: 'Cancel',
          onPress: () => {},
          style: 'cancel',
        },
        {
          text: 'Confirm',
          onPress: () => {
            const deleteResult = event.deleteTeam(team);
            dataModel.saveEvents();
            if (deleteResult !== null) {
              showPlatformDialog({
                title: 'Error',
                content: 'Team is present in matches',
                actions: [
                  {
                    text: 'Okay',
                    onPress: () => {},
                    style: 'cancel',
                  },
                ],
              });
            }
          },
          style: 'destructive',
        },
      ],
    });
  };

  if (teams.length === 0 && !event.shared) {
    return (
      <View style={styles.emptyList}>
        <Text>No teams found.</Text>
      </View>
    );
  }

  if (!event.shared) {
    return (
      <View style={styles.container}>
        <ExampleTeamRow
          sortMode={sortMode}
          elementSort={elementSort}
          statistics={statistic}
        />
        <FlatList
          data={teams}
          keyExtractor={(item) => item.number.toString()}
          renderItem={({ item }) => (
            <Slidable
              renderRightActions={(progress) => (
                <SlidableAction
                  onPress={() => handleDeleteTeam(item)}
                  backgroundColor="#DC143C"
                  icon="trash"
                />
              )}
            >
              <TouchableOpacity onPress={() => handleTeamPress(item)}>
                <TeamRow
                  team={item}
                  event={event}
                  sortMode={sortMode}
                  statConfig={statConfig}
                  elementSort={elementSort}
                  max={max}
                  statistics={statistic}
                />
              </TouchableOpacity>
            </Slidable>
          )}
        />
      </View>
    );
  } else {
    return (
      <View style={styles.container}>
        <PlatformProgressIndicator />
      </View>
    );
  }
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  emptyList: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default TeamList;