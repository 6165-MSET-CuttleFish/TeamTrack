import React, { useState, useEffect } from 'react';
import { View, Text, FlatList, TouchableOpacity } from 'react-native';
import { useGetEventList } from '../../hooks/useGetEventList';
import { Event } from '../../api/api.types';
import { EventListScreenStyles as styles } from './EventListScreen.styles';
import { useNavigation } from '@react-navigation/native';
import { EventType } from '../../api/api.types';
import { useAuthContext } from '../../hooks/useFirebaseAuth';
import { PlatformAlert } from '../../components/PlatformAlert';
import { PlatformDialogAction } from '../../components/PlatformDialogAction';
import { PlatformTextField } from '../../components/PlatformTextField';
import { PlatformProgressIndicator } from '../../components/PlatformProgressIndicator';

const EventListScreen = () => {
  const { user } = useAuthContext();
  const navigation = useNavigation();
  const [newName, setNewName] = useState('');
  const [newType, setNewType] = useState<EventType>(EventType.remote);
  const { isLoading, data: events, error } = useGetEventList();

  useEffect(() => {
    // Fetch events when the component mounts
  }, []);

  const handleEventPress = (event: Event) => {
    navigation.navigate('EventDetails', { event });
  };

  const handleAddEvent = () => {
    // Show a dialog to get the event name
    PlatformAlert.show({
      title: 'New Event',
      content: (
        <View>
          <PlatformTextField
            placeholder="Enter event name"
            value={newName}
            onChangeText={setNewName}
          />
        </View>
      ),
      actions: [
        {
          text: 'Cancel',
          isDefaultAction: true,
          onPress: () => {
            setNewName('');
            PlatformAlert.dismiss();
          },
        },
        {
          text: 'Add',
          onPress: async () => {
            PlatformAlert.dismiss();
            if (newName.trim()) {
              // Create the event
              // ...
            }
          },
        },
      ],
    });
  };

  const handleDeleteEvent = async (event: Event) => {
    // Show a confirmation dialog
    PlatformAlert.show({
      title: 'Delete Event',
      content: `Are you sure you want to delete ${event.name}?`,
      actions: [
        {
          text: 'Cancel',
          isDefaultAction: true,
          onPress: () => {
            PlatformAlert.dismiss();
          },
        },
        {
          text: 'Confirm',
          isDestructive: true,
          onPress: async () => {
            PlatformAlert.dismiss();
            // Delete the event
            // ...
          },
        },
      ],
    });
  };

  const handleShareEvent = async (event: Event) => {
    // Show a dialog to confirm uploading
    PlatformAlert.show({
      title: 'Upload Event',
      content: `This event will be shared publicly.`,
      actions: [
        {
          text: 'Cancel',
          isDefaultAction: true,
          onPress: () => {
            PlatformAlert.dismiss();
          },
        },
        {
          text: 'Upload',
          onPress: async () => {
            PlatformAlert.dismiss();
            PlatformAlert.show({
              content: <PlatformProgressIndicator />,
            });
            // Upload the event
            // ...
            PlatformAlert.dismiss();
          },
        },
      ],
    });
  };

  if (isLoading) {
    return (
      <View style={styles.container}>
        <Text>Loading...</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.container}>
        <Text>Error loading events</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerText}>My Events</Text>
        <TouchableOpacity style={styles.addButton} onPress={handleAddEvent}>
          <Text style={styles.addButtonText}>ADD</Text>
        </TouchableOpacity>
      </View>
      <FlatList
        data={events}
        keyExtractor={(item) => item.id}
        renderItem={({ item: event }) => (
          <TouchableOpacity
            style={styles.eventItem}
            onPress={() => handleEventPress(event)}
          >
            <View style={styles.eventInfo}>
              <Text style={styles.eventName}>{event.name}</Text>
              <Text style={styles.eventDate}>{event.createdAt}</Text>
            </View>
            <View style={styles.eventActions}>
              {/* Add share icon here if needed */}
              <TouchableOpacity onPress={() => handleDeleteEvent(event)}>
                <Text style={styles.actionText}>Delete</Text>
              </TouchableOpacity>
            </View>
          </TouchableOpacity>
        )}
        ListHeaderComponent={() => (
          <Text style={styles.header}>My Events</Text>
        )}
      />
    </View>
  );
};

export default EventListScreen;