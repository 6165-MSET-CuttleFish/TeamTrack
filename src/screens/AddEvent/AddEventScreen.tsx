import React, { useState } from 'react';
import { View, Text, TextInput, Button, StyleSheet } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useCreateEvent } from '../../hooks/useCreateEvent';
import { useGetEventList } from '../../hooks/useGetEventList';
import { EventType } from '../../utils/constants/constants.types';
import { Theme } from '../../theme/theme';
import { useTheme } from '../../hooks/useTheme';

const AddEventScreen: React.FC = () => {
  const navigation = useNavigation();
  const [eventName, setEventName] = useState('');
  const [eventGame, setEventGame] = useState('');
  const [eventDate, setEventDate] = useState('');
  const [eventType, setEventType] = useState<EventType>(EventType.InPerson);
  const { createEvent } = useCreateEvent();
  const { theme } = useTheme();
  const { events } = useGetEventList();

  const handleSubmit = async () => {
    try {
      await createEvent({
        name: eventName,
        game: eventGame,
        date: eventDate,
        type: eventType,
      });
      navigation.navigate('Home');
    } catch (error) {
      console.error('Error creating event:', error);
      // Handle error, e.g., display an error message to the user.
    }
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <Text style={[styles.title, { color: theme.text }]}>Create New Event</Text>
      <View style={styles.inputContainer}>
        <TextInput
          style={[styles.input, { backgroundColor: theme.inputBackground, color: theme.text }]}
          placeholder="Event Name"
          value={eventName}
          onChangeText={setEventName}
        />
      </View>
      <View style={styles.inputContainer}>
        <TextInput
          style={[styles.input, { backgroundColor: theme.inputBackground, color: theme.text }]}
          placeholder="Game Name"
          value={eventGame}
          onChangeText={setEventGame}
        />
      </View>
      <View style={styles.inputContainer}>
        <TextInput
          style={[styles.input, { backgroundColor: theme.inputBackground, color: theme.text }]}
          placeholder="Event Date"
          value={eventDate}
          onChangeText={setEventDate}
        />
      </View>
      <View style={styles.inputContainer}>
        <Button
          title="In Person"
          color={eventType === EventType.InPerson ? Theme.primaryColor : Theme.secondaryColor}
          onPress={() => setEventType(EventType.InPerson)}
        />
        <Button
          title="Remote"
          color={eventType === EventType.Remote ? Theme.primaryColor : Theme.secondaryColor}
          onPress={() => setEventType(EventType.Remote)}
        />
        <Button
          title="Analysis"
          color={eventType === EventType.Analysis ? Theme.primaryColor : Theme.secondaryColor}
          onPress={() => setEventType(EventType.Analysis)}
        />
      </View>
      <Button
        title="Create Event"
        color={Theme.primaryColor}
        onPress={handleSubmit}
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
  inputContainer: {
    marginBottom: 10,
  },
  input: {
    height: 40,
    borderColor: 'gray',
    borderWidth: 1,
    padding: 10,
    borderRadius: 5,
  },
});

export default AddEventScreen;