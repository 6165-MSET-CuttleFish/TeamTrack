import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useGetEvent } from '../../hooks/useGetEvent';
import { useGetMatchList } from '../../hooks/useGetMatchList';
import { useDeleteMatch } from '../../hooks/useDeleteMatch';

import { Event, Match } from '../../api/api.types';

const EventDetailsScreen = ({ route }: { route: any }) => {
  const navigation = useNavigation();
  const { eventId } = route.params;

  const { data: event, isLoading, error } = useGetEvent(eventId);
  const { data: matches, isLoading: matchesLoading, error: matchesError } = useGetMatchList(eventId);
  const { mutate: deleteMatch } = useDeleteMatch();

  const [selectedMatchId, setSelectedMatchId] = useState<string | null>(null);

  useEffect(() => {
    if (event && matches) {
      const match = matches.find(match => match.id === selectedMatchId);
      if (match) {
        navigation.navigate('MatchDetails', { matchId: match.id });
      }
    }
  }, [event, matches, selectedMatchId, navigation]);

  const handleDeleteMatch = (matchId: string) => {
    deleteMatch(matchId)
      .then(() => {
        // Update the match list after deletion
        // You might need to implement a refresh mechanism here
      })
      .catch(err => {
        console.error('Error deleting match:', err);
        // Handle error appropriately
      });
  };

  if (isLoading || matchesLoading) {
    return (
      <View style={styles.container}>
        <Text>Loading...</Text>
      </View>
    );
  }

  if (error || matchesError) {
    return (
      <View style={styles.container}>
        <Text>Error loading event or matches.</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>{event.name}</Text>
        <Text style={styles.subtitle}>{event.gameName}</Text>
      </View>

      <View style={styles.matchesList}>
        <FlatList
          data={matches}
          keyExtractor={item => item.id}
          renderItem={({ item: match }) => (
            <TouchableOpacity
              style={styles.matchItem}
              onPress={() => setSelectedMatchId(match.id)}
            >
              <Text style={styles.matchText}>Match {match.matchNumber}</Text>
              <TouchableOpacity
                style={styles.deleteButton}
                onPress={() => handleDeleteMatch(match.id)}
              >
                <Text style={styles.deleteButtonText}>Delete</Text>
              </TouchableOpacity>
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
  },
  header: {
    marginBottom: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  subtitle: {
    fontSize: 18,
  },
  matchesList: {
    flex: 1,
  },
  matchItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 15,
    marginBottom: 5,
    backgroundColor: '#f0f0f0',
    borderRadius: 5,
  },
  matchText: {
    fontSize: 16,
    flex: 1,
  },
  deleteButton: {
    backgroundColor: '#dc3545',
    padding: 10,
    borderRadius: 5,
  },
  deleteButtonText: {
    color: '#fff',
    fontSize: 14,
  },
});

export default EventDetailsScreen;