typescript
import React, { useState, useEffect } from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet, ActivityIndicator } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Event, Team, StatConfig, Statistics, ScoringElement, OpModeType } from '../models';
import EmptyList from '../components/EmptyList';
import TeamRow from './TeamRow';
import TeamView from './TeamView';
import PlatformProgressIndicator from '../components/PlatformProgressIndicator';
import { useDatabase } from '../hooks/useDatabase';
import { getStatistic, maxValue } from '../functions/Statistics';

interface TeamListProps {
  event: Event;
  sortMode?: OpModeType;
  elementSort?: ScoringElement;
  statConfig: StatConfig;
  statistic: Statistics;
}

const TeamList: React.FC<TeamListProps> = ({ event, sortMode, elementSort, statConfig, statistic }) => {
  const navigation = useNavigation();
  const [teams, setTeams] = useState<Team[]>([]);
  const [max, setMax] = useState<number>(0);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const database = useDatabase();

  useEffect(() => {
    const unsubscribe = database.ref(`events/${event.key}`).on('value', (snapshot) => {
      const updatedEvent = snapshot.val() as Event;
      event.updateLocal(updatedEvent);
      setTeams(statConfig.sorted
        ? event.teams.sortedTeams(sortMode, elementSort, statConfig, event.matches.values.toList(), statistic)
        : event.teams.orderedTeams()
      );
      setMax(calculateMax(event, statConfig, statistic, sortMode, elementSort));
      setIsLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const calculateMax = (event: Event, statConfig: StatConfig, statistic: Statistics, sortMode?: OpModeType, elementSort?: ScoringElement): number => {
    let maxScore = event.teams.maxCustomStatisticScore(null, statConfig.removeOutliers, statistic, sortMode, elementSort);
    if (statConfig.allianceTotal) {
      maxScore = event.teams.values.map((e) => {
        return event.matches.values
          .toList()
          .spots(e, null, statConfig.showPenalties, type: sortMode)
          .removeOutliers(statConfig.removeOutliers)
          .map((spot) => spot.y)
          .getStatistic(statistic.getFunction());
      }).maxValue();
    }
    return maxScore;
  };

  const handlePressTeam = (team: Team) => {
    navigation.navigate('TeamView', { team, event });
  };

  if (isLoading) {
    return (
      <View style={styles.container}>
        <PlatformProgressIndicator />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {teams.length === 0 && <EmptyList />}
      <FlatList
        data={teams}
        keyExtractor={(item) => item.key}
        renderItem={({ item }) => (
          <TouchableOpacity onPress={() => handlePressTeam(item)}>
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
        )}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
});

export default TeamList;