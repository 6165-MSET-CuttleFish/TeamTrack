import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, ActivityIndicator } from 'react-native';
import { useNavigation } from '@react-navigation/native';

import { useGetEvent } from '../../hooks/useGetEvent';
import { useGetMatchList } from '../../hooks/useGetMatchList';
import { useGetTeamList } from '../../hooks/useGetTeamList';
import { Event, Match } from '../../api/api.types';

const EventDetailsScreen = ({ route }: { route: { params: { eventId: string } } }) => {
  const navigation = useNavigation();
  const [event, setEvent] = useState<Event | null>(null);
  const [matches, setMatches] = useState<Match[]>([]);
  const [teams, setTeams] = useState<Team[]>([]);

  const { isLoading: eventLoading, error: eventError } = useGetEvent(
    route.params.eventId,
    setEvent,
  );

  const { isLoading: matchesLoading, error: matchesError } = useGetMatchList(
    route.params.eventId,
    setMatches,
  );

  const { isLoading: teamsLoading, error: teamsError } = useGetTeamList(
    route.params.eventId,
    setTeams,
  );

  useEffect(() => {
    if (eventLoading || matchesLoading || teamsLoading) {
      return;
    }

    if (eventError || matchesError || teamsError) {
      console.error('Error fetching data:', eventError || matchesError || teamsError);
    }
  }, [eventLoading, matchesLoading, teamsLoading, eventError, matchesError, teamsError]);

  if (eventLoading || matchesLoading || teamsLoading) {
    return (
      <View style={styles.container}>
        <ActivityIndicator size="large" color="#0000ff" />
      </View>
    );
  }

  if (eventError || matchesError || teamsError) {
    return (
      <View style={styles.container}>
        <Text>Error loading event details</Text>
      </View>
    );
  }

  if (!event) {
    return (
      <View style={styles.container}>
        <Text>Event not found</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>{event.name}</Text>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Matches</Text>
        <FlatList
          data={matches}
          keyExtractor={(match) => match.id}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={styles.matchItem}
              onPress={() =>
                navigation.navigate('MatchDetails', { matchId: item.id })
              }
            >
              <Text style={styles.matchText}>{item.name}</Text>
            </TouchableOpacity>
          )}
        />
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Teams</Text>
        <FlatList
          data={teams}
          keyExtractor={(team) => team.id}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={styles.teamItem}
              onPress={() =>
                navigation.navigate('TeamDetails', { teamId: item.id })
              }
            >
              <Text style={styles.teamText}>{item.name}</Text>
            </TouchableOpacity>
          )}
        />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: '#fff',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  section: {
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  matchItem: {
    padding: 10,
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 5,
    marginBottom: 5,
  },
  matchText: {
    fontSize: 16,
  },
  teamItem: {
    padding: 10,
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 5,
    marginBottom: 5,
  },
  teamText: {
    fontSize: 16,
  },
});

export default EventDetailsScreen;