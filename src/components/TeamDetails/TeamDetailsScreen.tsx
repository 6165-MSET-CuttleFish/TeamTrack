import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useGetTeam } from '../../hooks/useGetTeam';
import { useGetMatchList } from '../../hooks/useGetMatchList';
import { Team, Match } from '../../services/firebase/firebase.types';
import { useGetEvent } from '../../hooks/useGetEvent';
import { Event } from '../../services/firebase/firebase.types';
import { useGetTeamList } from '../../hooks/useGetTeamList';
import { useCreateMatch } from '../../hooks/useCreateMatch';
import { useUpdateMatch } from '../../hooks/useUpdateMatch';
import { useUpdateTeam } from '../../hooks/useUpdateTeam';
import { useDeleteMatch } from '../../hooks/useDeleteMatch';
import { useCreateEvent } from '../../hooks/useCreateEvent';
import { useUpdateEvent } from '../../hooks/useUpdateEvent';
import { useDeleteEvent } from '../../hooks/useDeleteEvent';
import { useCreateTeam } from '../../hooks/useCreateTeam';
import { useDeleteTeam } from '../../hooks/useDeleteTeam';
import { useFirebaseAuth } from '../../hooks/useFirebaseAuth';
import { useGetMatch } from '../../hooks/useGetMatch';
import { useGetEventList } from '../../hooks/useGetEventList';

interface TeamDetailsScreenProps {
  id: string;
}

const TeamDetailsScreen: React.FC<TeamDetailsScreenProps> = ({ id }) => {
  const navigation = useNavigation();
  const { data: team, isLoading, error } = useGetTeam(id);
  const { data: matches, isLoading: matchesLoading, error: matchesError } = useGetMatchList({ teamId: id });
  const { data: event, isLoading: eventLoading, error: eventError } = useGetEvent(team?.eventId ?? '');
  const { data: teams, isLoading: teamsLoading, error: teamsError } = useGetTeamList({ eventId: team?.eventId ?? '' });
  const { mutate: createMatch } = useCreateMatch();
  const { mutate: updateMatch } = useUpdateMatch();
  const { mutate: updateTeam } = useUpdateTeam();
  const { mutate: deleteMatch } = useDeleteMatch();
  const { mutate: createEvent } = useCreateEvent();
  const { mutate: updateEvent } = useUpdateEvent();
  const { mutate: deleteEvent } = useDeleteEvent();
  const { mutate: createTeam } = useCreateTeam();
  const { mutate: deleteTeam } = useDeleteTeam();
  const { user, isLoading: userLoading, error: userError } = useFirebaseAuth();
  const { data: match, isLoading: matchLoading, error: matchError } = useGetMatch('');
  const { data: events, isLoading: eventsLoading, error: eventsError } = useGetEventList();

  const [selectedMatch, setSelectedMatch] = useState<Match | null>(null);

  useEffect(() => {
    if (user) {
      // Fetch team and matches based on user authentication
    } else {
      navigation.navigate('AuthStack');
    }
  }, [user, navigation]);

  const handleMatchPress = (match: Match) => {
    setSelectedMatch(match);
  };

  const handleMatchUpdate = (match: Match) => {
    updateMatch(match);
  };

  const handleMatchDelete = (matchId: string) => {
    deleteMatch(matchId);
  };

  const handleTeamUpdate = (team: Team) => {
    updateTeam(team);
  };

  const handleTeamDelete = () => {
    deleteTeam(id);
  };

  if (isLoading || matchesLoading || eventLoading || teamsLoading || userLoading || matchLoading || eventsLoading) {
    return (
      <View style={styles.container}>
        <Text>Loading...</Text>
      </View>
    );
  }

  if (error || matchesError || eventError || teamsError || userError || matchError || eventsError) {
    return (
      <View style={styles.container}>
        <Text>An error occurred. Please try again later.</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Team Details</Text>
      <View style={styles.teamInfo}>
        <Text style={styles.teamName}>{team?.name ?? ''}</Text>
        <Text style={styles.teamNumber}>{team?.number ?? ''}</Text>
        <Text style={styles.teamEvent}>Event: {event?.name ?? ''}</Text>
      </View>
      <Text style={styles.matchesTitle}>Matches</Text>
      <FlatList
        data={matches}
        keyExtractor={(match) => match.id}
        renderItem={({ item: match }) => (
          <TouchableOpacity onPress={() => handleMatchPress(match)}>
            <View style={[styles.matchItem, selectedMatch?.id === match.id && styles.selectedMatch]}>
              <Text style={styles.matchNumber}>{match.matchNumber}</Text>
              <Text style={styles.matchScore}>Score: {match.score}</Text>
            </View>
          </TouchableOpacity>
        )}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  teamInfo: {
    marginBottom: 20,
  },
  teamName: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  teamNumber: {
    fontSize: 16,
  },
  teamEvent: {
    fontSize: 14,
  },
  matchesTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  matchItem: {
    padding: 15,
    borderWidth: 1,
    borderColor: '#ccc',
    marginBottom: 10,
    borderRadius: 8,
  },
  selectedMatch: {
    backgroundColor: '#f0f0f0',
  },
  matchNumber: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  matchScore: {
    fontSize: 14,
  },
});

export default TeamDetailsScreen;