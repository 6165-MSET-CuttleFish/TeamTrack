import React, { useState, useEffect } from 'react';
import { View, Text, FlatList, StyleSheet, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';

import { useGetTeamList } from '../../hooks/useGetTeamList';
import { Team } from '../../api/api.types';
import { TeamRow } from './TeamRow';
import { useGetEvent } from '../../hooks/useGetEvent';

interface TeamListScreenProps {
  eventId: string;
}

const TeamListScreen: React.FC<TeamListScreenProps> = ({ eventId }) => {
  const navigation = useNavigation();
  const [teams, setTeams] = useState<Team[]>([]);
  const { isLoading, error, getTeamList } = useGetTeamList();
  const { eventData, isLoading: eventLoading } = useGetEvent(eventId);

  useEffect(() => {
    if (!isLoading && !error) {
      getTeamList(eventId).then(setTeams);
    }
  }, [isLoading, error, getTeamList, eventId]);

  if (eventLoading) {
    return (
      <View style={styles.container}>
        <Text>Loading Event Data...</Text>
      </View>
    );
  }

  if (isLoading) {
    return (
      <View style={styles.container}>
        <Text>Loading Teams...</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.container}>
        <Text>Error loading teams: {error.message}</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Teams for {eventData?.name}</Text>
      <FlatList
        data={teams}
        keyExtractor={(item) => item.id.toString()}
        renderItem={({ item }) => (
          <TouchableOpacity
            onPress={() =>
              navigation.navigate('TeamDetails', {
                teamId: item.id,
                eventId: eventId,
              })
            }
            style={styles.teamRow}
          >
            <TeamRow team={item} event={eventData} />
          </TouchableOpacity>
        )}
        ListEmptyComponent={() => (
          <View style={styles.emptyList}>
            <Text>No Teams Found</Text>
          </View>
        )}
      />
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
  teamRow: {
    padding: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#ddd',
  },
  emptyList: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

export default TeamListScreen;