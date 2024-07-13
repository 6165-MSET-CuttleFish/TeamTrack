tsx
import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Slidable } from 'react-native-elements';
import { FontAwesomeIcon } from '@fortawesome/react-native-fontawesome';
import { faUpload, faTrash } from '@fortawesome/free-solid-svg-icons';
import { useTheme } from '@react-navigation/native';
import InfoPill from '../misc/InfoPill';
import { EventType } from '../../models/GameModel';
import { useAppModel } from '../../models/AppModel';

interface EventCardProps {
  event: any;
  onTap: (event: any) => void;
}

const EventCard: React.FC<EventCardProps> = ({ event, onTap }) => {
  const navigation = useNavigation();
  const { colors } = useTheme();
  const { dataModel, firebaseDatabase } = useAppModel();
  const [isShared, setIsShared] = useState(event.shared);

  useEffect(() => {
    setIsShared(event.shared);
  }, [event.shared]);

  const formatDate = new Intl.DateTimeFormat('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(event.createdAt.toDate()));

  const handleShare = async () => {
    if (!event.shared) {
      Alert.alert('Upload Event', 'Your event will still be private', [
        {
          text: 'Cancel',
          style: 'cancel',
        },
        {
          text: 'Upload',
          onPress: async () => {
            Alert.alert('Uploading...', '', [
              {
                text: 'Back',
                style: 'cancel',
              },
            ]);
            try {
              event.shared = true;
              await firebaseDatabase
                .ref()
                .child(`Events/${event.gameName}/${event.id}`)
                .set(event.toJson());
              dataModel.events.remove(event);
              dataModel.saveEvents();
              setIsShared(true);
              Alert.alert('Event Uploaded!');
            } catch (error) {
              console.error(error);
              Alert.alert('Error Uploading Event');
            }
          },
        },
      ]);
    } else {
      navigation.navigate('EventShare', { event });
    }
  };

  const handleDelete = () => {
    Alert.alert('Delete Event', 'Are you sure?', [
      {
        text: 'Cancel',
        style: 'cancel',
      },
      {
        text: 'Confirm',
        style: 'destructive',
        onPress: async () => {
          try {
            if (event.shared) {
              await firebaseDatabase
                .ref()
                .child(`Events/${event.gameName}/${event.id}`)
                .remove();
            } else {
              dataModel.events.remove(event);
              dataModel.saveEvents();
            }
            Alert.alert('Event Deleted!');
          } catch (error) {
            console.error(error);
            Alert.alert('Error Deleting Event');
          }
        },
      },
    ]);
  };

  const handlePress = async () => {
    if (onTap) {
      const map = await event.getRef()?.once();
      event.updateLocal(map?.snapshot.value, null);
      onTap(event);
    } else if (event.type !== EventType.analysis) {
      navigation.navigate('EventView', { event });
    } else if (event.type === EventType.analysis) {
      if (event.getAllTeams().length === 0) {
        event.addTeam({ number: '0', name: event.name });
      }
      dataModel.saveEvents();
      navigation.navigate('TeamView', {
        team: event.getAllTeams()[0],
        event,
      });
    }
  };

  return (
    <Slidable
      leftActionPaneStyle={{ backgroundColor: colors.primary }}
      rightActionPaneStyle={{ backgroundColor: 'red' }}
      rightOpenValue={-75}
      leftOpenValue={75}
      onRightOpen={() => handleDelete()}
      onLeftOpen={() => handleShare()}
    >
      <View style={styles.eventCard}>
        <TouchableOpacity onPress={handlePress} style={styles.eventContent}>
          <Text style={styles.eventTitle}>{event.name}</Text>
          <View style={styles.eventInfo}>
            <InfoPill text={isShared ? 'Shared' : 'Private'} color={colors.primary} />
            {event.type !== EventType.analysis && (
              <InfoPill text={formatDate} color='red' />
            )}
            {event.type === EventType.analysis && (
              <InfoPill text={`Matches: ${event.matches.length}`} color='purple' />
            )}
          </View>
        </TouchableOpacity>
        <View style={styles.eventActions}>
          <Slidable.Action
            onPress={() => handleShare()}
            icon={<FontAwesomeIcon icon={faUpload} size={20} color="white" />}
          />
          <Slidable.Action
            onPress={() => handleDelete()}
            icon={<FontAwesomeIcon icon={faTrash} size={20} color="white" />}
          />
        </View>
      </View>
    </Slidable>
  );
};

const styles = StyleSheet.create({
  eventCard: {
    backgroundColor: 'white',
    marginBottom: 10,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
  eventContent: {
    padding: 16,
  },
  eventTitle: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  eventInfo: {
    flexDirection: 'row',
    marginTop: 8,
    alignItems: 'center',
  },
  eventActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: 16,
  },
});

export default EventCard;