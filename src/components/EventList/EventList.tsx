typescript
import React, { useState, useEffect, useContext } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, Alert, Platform } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useSelector, useDispatch } from 'react-redux';
import { RootState } from '../redux/store';
import { addEvent, removeEvent, updateEvent } from '../redux/actions/eventActions';
import { Event, EventType, Team, Role } from '../models/GameModel';
import { InfoPills } from '../components/misc/InfoPills';
import { TeamView } from '../views/home/team/TeamView';
import { EventView } from './EventView';
import { EventShare } from './EventShare';
import { PlatformAlert, PlatformDialogAction, PlatformTextField, PlatformProgressIndicator } from '../components/misc/PlatformGraphics';
import {  getMatches } from '../functions/APIMethods';
import { StatConfig } from '../models/ScoreModel';
import { getEvents } from '../functions/Storage';
import { FontAwesomeIcon } from '@fortawesome/react-native-fontawesome';
import { faPlus, faTrash, faUpload, faShare, faSearch, faSort, faSortUp, faSortDown, faPhotoCamera, faRefresh } from '@fortawesome/free-solid-svg-icons';
import moment from 'moment';
import { themeChangeProvider, ThemeContext } from '../providers/Theme';


interface EventListProps {
  onTap?: (event: Event) => void;
}

const EventList: React.FC<EventListProps> = ({ onTap }) => {
  const navigation = useNavigation();
  const dispatch = useDispatch();
  const events = useSelector((state: RootState) => state.events);
  const user = useSelector((state: RootState) => state.auth.user);
  const [localEvents, setLocalEvents] = useState<Event[]>([]);
  const [remoteEvents, setRemoteEvents] = useState<Event[]>([]);
  const [driverAnalysis, setDriverAnalysis] = useState<Event[]>([]);
  const [sortingModifier, setSortingModifier] = useState<OpModeType | null>(null);
  const [elementSort, setElementSort] = useState<ScoringElement | null>(null);
  const [statistics, setStatistics] = useState<Statistics>(Statistics.MEDIAN);
  const [ascending, setAscending] = useState<boolean>(false);
  const [bod, setBod] = useState<any[]>([]);
  const theme = useContext(ThemeContext);
  
  useEffect(() => {
    const loadEvents = async () => {
      const loadedEvents = await getEvents();
      setLocalEvents(loadedEvents.filter(event => event.type === EventType.local));
      setRemoteEvents(loadedEvents.filter(event => event.type === EventType.remote));
      setDriverAnalysis(loadedEvents.filter(event => event.type === EventType.analysis));
    };
    loadEvents();
  }, []);

  const format = moment.locale('en').format('MMMM DD, YYYY');

  const _getMatches = async (event: Event) => {
    if (event.hasKey()) {
      const response = await getMatches(event.getKey() ?? '');
      setBod((json.decode(response.body) as any[]).filter((match) => match.red_score !== undefined && match.blue_score !== undefined));
    }
  };

  const _onShare = async (event: Event) => {
    if (user && !user.isAnonymous) {
      if (!event.shared) {
        Alert.alert(
          'Upload Event',
          'Your event will still be private',
          [
            {
              text: 'Cancel',
              onPress: () => {},
              style: 'cancel',
            },
            {
              text: 'Upload',
              onPress: async () => {
                Alert.alert(
                  'Uploading...',
                  '',
                  [
                    {
                      text: 'Back',
                      onPress: () => {},
                      style: 'cancel',
                    },
                  ],
                  {
                    onDismiss: () => {
                      event.shared = true;
                      const json = event.toJson();
                      dispatch(updateEvent(event));
                      navigation.pop();
                      navigation.pop();
                    },
                  },
                );
                // await firebaseDatabase.ref().child(`Events/${event.gameName}/${event.id}`).set(json);
                // dispatch(removeEvent(event));
              },
            },
          ],
        );
      } else {
        navigation.push({
          name: 'EventShare',
          params: { event },
        });
      }
    } else {
      Alert.alert(
        'Cannot Share Event',
        'You must be logged in to share an event.',
        [
          {
            text: 'OK',
            onPress: () => {},
            style: 'cancel',
          },
        ],
      );
    }
  };

  const _onRemove = async (event: Event) => {
    if (user && user.uid) {
      Alert.alert(
        'Delete Event',
        'Are you sure?',
        [
          {
            text: 'Cancel',
            onPress: () => {},
            style: 'cancel',
          },
          {
            text: 'Confirm',
            onPress: async () => {
              if (event.shared) {
                // await firebaseDatabase.ref().child(`Events/${event.gameName}/${event.id}`).remove();
              } else {
                dispatch(removeEvent(event));
              }
              navigation.pop();
            },
          },
        ],
      );
    }
  };

  const _chosen = (newType: EventType) => {
    Alert.prompt(
      `New ${newType === EventType.remote ? 'Remote Event' : newType === EventType.local ? 'In Person Event' : 'Driver Analysis'}`,
      '',
      [
        {
          text: 'Cancel',
          onPress: () => {},
          style: 'cancel',
        },
        {
          text: 'Add',
          onPress: (newName: string) => {
            if (newName && newName.trim().length > 0) {
              dispatch(addEvent(new Event(newName, newType, Statics.gameName)));
            }
          },
        },
      ],
      {
        placeholder: 'Enter name',
      },
    );
  };

  const eventTile = (event: Event) => {
    return (
      <TouchableOpacity
        style={[styles.eventTile, { backgroundColor: theme.darkTheme ? 'white12' : 'black87' }]}
        onPress={() => {
          if (onTap) {
            event.getRef()?.once().then(map => {
              event.updateLocal(map.snapshot.value, null);
              onTap(event);
            });
          } else if (event.type !== EventType.analysis) {
            navigation.push({
              name: 'EventView',
              params: { event },
            });
          } else if (event.type === EventType.analysis) {
            const _newName = event.name;
            const _newNumber = '0';
            if (event.getAllTeams().length === 0) {
              event.addTeam(new Team(_newNumber, _newName));
              dispatch(updateEvent(event));
            }
            navigation.push({
              name: 'TeamView',
              params: { team: event.getAllTeams()[0], event },
            });
          }
        }}
      >
        <View style={styles.eventTileContent}>
          <Text style={[styles.eventTitle, { color: 'white' }]}>{event.name}</Text>
          <View style={styles.eventDetails}>
            {event.shared ? <InfoPills text="Shared" color="blueAccent" /> : <InfoPills text="Private" color="grey" />}
            {event.type === EventType.analysis ? null : <InfoPills text={format.format(event.createdAt.toDate())} color="red" />}
            {event.type === EventType.analysis ? <InfoPills text={`Matches: ${event.matches.length}`} color="purple" /> : null}
          </View>
        </View>
        <View style={styles.eventActions}>
          <TouchableOpacity onPress={() => _onShare(event)}>
            <FontAwesomeIcon icon={event.shared ? faShare : faUpload} size={20} color="blue" />
          </TouchableOpacity>
          <TouchableOpacity onPress={() => _onRemove(event)}>
            <FontAwesomeIcon icon={faTrash} size={20} color="red" />
          </TouchableOpacity>
        </View>
      </TouchableOpacity>
    );
  };

  const renderEventList = (events: Event[]) => {
    return (
      <FlatList
        data={events}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => eventTile(item)}
        contentContainerStyle={styles.eventListContainer}
      />
    );
  };

  const renderEventSection = (title: string, events: Event[]) => {
    return (
      <View style={styles.eventSection}>
        <View style={styles.eventSectionHeader}>
          <Text style={styles.eventSectionTitle}>{title}</Text>
          <TouchableOpacity onPress={() => _chosen(events[0].type)}>
            <FontAwesomeIcon icon={faPlus} size={20} color="white" />
          </TouchableOpacity>
        </View>
        {renderEventList(events)}
      </View>
    );
  };

  return (
    <View style={styles.container}>
      {renderEventSection('My Events', localEvents)}
      {renderEventSection('Driver Practice', driverAnalysis)}
      {renderEventSection('Remote Events', remoteEvents)}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: themeChangeProvider.darkTheme ? '#212121' : '#f5f5f5',
    padding: 8,
  },
  eventTile: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    marginBottom: 8,
    borderRadius: 12,
  },
  eventTileContent: {
    flex: 1,
  },
  eventTitle: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  eventDetails: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
  },
  eventActions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  eventListContainer: {
    padding: 16,
  },
  eventSection: {
    marginBottom: 24,
  },
  eventSectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  eventSectionTitle: {
    fontSize: 24,
    fontWeight: 'bold',
  },
});

export default EventList;