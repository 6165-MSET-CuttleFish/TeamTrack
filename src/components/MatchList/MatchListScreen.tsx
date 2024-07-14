import React, { useState, useEffect } from 'react';
import { View, FlatList, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useGetMatchList } from '../../hooks/useGetMatchList';
import { useDeleteMatch } from '../../hooks/useDeleteMatch';
import { useGetEvent } from '../../hooks/useGetEvent';
import { Match } from '../../api/api.types';
import { Event } from '../../api/api.types';
import { useGetTeam } from '../../hooks/useGetTeam';
import { Team } from '../../api/api.types';
import { useCreateMatch } from '../../hooks/useCreateMatch';
import { Alert } from 'react-native';
import { OpModeType } from '../../api/api.types';

const MatchListScreen = () => {
  const navigation = useNavigation();
  const [event, setEvent] = useState<Event | null>(null);
  const [team, setTeam] = useState<Team | null>(null);
  const [matches, setMatches] = useState<Match[]>([]);
  const [maxScores, setMaxScores] = useState<Record<OpModeType, number>>({});
  const [isLoading, setIsLoading] = useState(true);
  const { data: matchList, refetch: refetchMatchList, isLoading: isLoadingMatchList } = useGetMatchList();
  const { data: eventData, refetch: refetchEvent } = useGetEvent();
  const { data: teamData, refetch: refetchTeam } = useGetTeam();
  const { mutate: createMatch } = useCreateMatch();
  const { mutate: deleteMatch } = useDeleteMatch();

  useEffect(() => {
    if (eventData) {
      setEvent(eventData);
      refetchMatchList({ eventId: eventData.id });
    }
  }, [eventData, refetchMatchList]);

  useEffect(() => {
    if (teamData) {
      setTeam(teamData);
    }
  }, [teamData]);

  useEffect(() => {
    if (matchList) {
      setMatches(matchList);
      setIsLoading(false);
      if (team) {
        const maxScoresTemp: Record<OpModeType, number> = {};
        Object.values(OpModeType).forEach((type) => {
          maxScoresTemp[type] = Math.max(
            ...matchList
              .filter((match) => match.alliances.some((alliance) => alliance.teams.some((t) => t.id === team.id)))
              .map((match) => match.alliances.find((alliance) => alliance.teams.some((t) => t.id === team.id))?.scores[type] ?? 0)
          );
        });
        setMaxScores(maxScoresTemp);
      }
    }
  }, [matchList, team]);

  const handleDeleteMatch = async (matchId: string) => {
    try {
      await deleteMatch({ matchId, eventId: event?.id });
      refetchMatchList();
    } catch (error) {
      Alert.alert('Error', 'Failed to delete match.');
    }
  };

  const handleCreateMatch = async () => {
    try {
      const newMatch = await createMatch({ eventId: event?.id, redAlliance: { teams: [] }, blueAlliance: { teams: [] } });
      refetchMatchList();
      navigation.navigate('MatchDetails', { matchId: newMatch.id });
    } catch (error) {
      Alert.alert('Error', 'Failed to create match.');
    }
  };

  const handleNavigateToMatchDetails = (matchId: string) => {
    navigation.navigate('MatchDetails', { matchId });
  };

  if (isLoading) {
    return (
      <View style={styles.container}>
        <Text>Loading...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={matches}
        keyExtractor={(match) => match.id}
        renderItem={({ item: match }) => (
          <TouchableOpacity onPress={() => handleNavigateToMatchDetails(match.id)} style={styles.matchRow}>
            <Text style={styles.matchNumber}>{match.alliances.findIndex((alliance) => alliance.teams.some((t) => t.id === team?.id)) + 1}</Text>
            <Text style={styles.matchTeams}>{`${match.alliances[0].teams[0].name} & ${match.alliances[0].teams[1].name} VS ${match.alliances[1].teams[0].name} & ${match.alliances[1].teams[1].name}`}</Text>
            <Text style={styles.matchScore}>{`${match.alliances[0].scores.total} - ${match.alliances[1].scores.total}`}</Text>
          </TouchableOpacity>
        )}
        ListHeaderComponent={() => (
          <View style={styles.header}>
            <Text style={styles.headerText}>Matches</Text>
            {event && team && (
              <TouchableOpacity onPress={handleCreateMatch} style={styles.addButton}>
                <Text style={styles.addButtonText}>Add Match</Text>
              </TouchableOpacity>
            )}
          </View>
        )}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  matchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#ddd',
  },
  matchNumber: {
    fontSize: 16,
    fontWeight: 'bold',
    marginRight: 16,
  },
  matchTeams: {
    fontSize: 16,
    flex: 1,
  },
  matchScore: {
    fontSize: 16,
  },
  header: {
    padding: 16,
    backgroundColor: '#f5f5f5',
  },
  headerText: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  addButton: {
    backgroundColor: '#007bff',
    padding: 12,
    borderRadius: 4,
    marginTop: 16,
  },
  addButtonText: {
    color: '#fff',
    textAlign: 'center',
  },
});

export default MatchListScreen;