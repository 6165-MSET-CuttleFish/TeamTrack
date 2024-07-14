import React, { useState, useEffect } from 'react';
import { StyleSheet, View, Text, TouchableOpacity } from 'react-native';
import { useGetEventList } from '../../hooks/useGetEventList';
import { useFirebaseAuth } from '../../hooks/useFirebaseAuth';
import { Event } from '../../api/api.types';
import { useNavigation } from '@react-navigation/native';
import { RootNavigationProps } from '../../services/navigation/navigation.types';
import { HomeScreenStyles } from './HomeScreen.styles';

interface HomeScreenProps {
  navigation: RootNavigationProps['navigation'];
}

const HomeScreen: React.FC<HomeScreenProps> = ({ navigation }) => {
  const [events, setEvents] = useState<Event[]>([]);
  const { user } = useFirebaseAuth();
  const { getEventList } = useGetEventList();

  useEffect(() => {
    const fetchEvents = async () => {
      const fetchedEvents = await getEventList();
      setEvents(fetchedEvents);
    };
    fetchEvents();
  }, [getEventList]);

  const handleEventPress = (event: Event) => {
    navigation.navigate('EventDetails', { eventId: event.id });
  };

  const handleAddEventPress = () => {
    navigation.navigate('AddEvent');
  };

  return (
    <View style={HomeScreenStyles.container}>
      <Text style={HomeScreenStyles.title}>My Events</Text>
      <TouchableOpacity style={HomeScreenStyles.addEventButton} onPress={handleAddEventPress}>
        <Text style={HomeScreenStyles.addEventButtonText}>Add Event</Text>
      </TouchableOpacity>
      <View style={HomeScreenStyles.eventList}>
        {events.map((event) => (
          <TouchableOpacity key={event.id} style={HomeScreenStyles.eventItem} onPress={() => handleEventPress(event)}>
            <Text style={HomeScreenStyles.eventTitle}>{event.name}</Text>
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );
};

export default HomeScreen;