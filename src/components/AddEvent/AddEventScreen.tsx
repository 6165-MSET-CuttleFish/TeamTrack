import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useCreateEvent } from '../../hooks/useCreateEvent';

interface AddEventScreenProps {
  // Any props you need to pass to this screen
}

const AddEventScreen: React.FC<AddEventScreenProps> = () => {
  const navigation = useNavigation();
  const [eventName, setEventName] = useState('');
  const [eventDescription, setEventDescription] = useState('');
  const [eventDate, setEventDate] = useState('');
  const [eventTime, setEventTime] = useState('');
  const { createEvent, isLoading } = useCreateEvent();

  const handleCreateEvent = async () => {
    try {
      await createEvent({
        name: eventName,
        description: eventDescription,
        date: eventDate,
        time: eventTime,
      });
      navigation.navigate('Home');
    } catch (error) {
      console.error('Error creating event:', error);
      // Handle error appropriately (e.g., show error message)
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Create New Event</Text>

      <TextInput
        style={styles.input}
        placeholder="Event Name"
        value={eventName}
        onChangeText={setEventName}
      />
      <TextInput
        style={styles.input}
        placeholder="Event Description"
        value={eventDescription}
        onChangeText={setEventDescription}
      />
      <TextInput
        style={styles.input}
        placeholder="Event Date"
        value={eventDate}
        onChangeText={setEventDate}
      />
      <TextInput
        style={styles.input}
        placeholder="Event Time"
        value={eventTime}
        onChangeText={setEventTime}
      />

      <TouchableOpacity
        style={[styles.button, isLoading && styles.buttonLoading]}
        onPress={handleCreateEvent}
        disabled={isLoading}
      >
        <Text style={styles.buttonText}>Create Event</Text>
      </TouchableOpacity>
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
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    padding: 10,
    marginBottom: 10,
  },
  button: {
    backgroundColor: '#007bff',
    padding: 15,
    borderRadius: 5,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
    fontWeight: 'bold',
  },
  buttonLoading: {
    opacity: 0.5,
  },
});

export default AddEventScreen;