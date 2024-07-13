typescript
import React, { useState, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert, FlatList, Button } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useTheme } from '@react-navigation/native';
import { useRoute } from '@react-navigation/native';
import { DataModel } from '../../../models/AppModel';
import { GameModel } from '../../../models/GameModel';
import { EventType } from '../../../models/GameModel';
import { Team } from '../../../models/ScoreModel';
import { EventShare } from './EventShare';
import { EventView } from './EventView';
import { TeamView } from '../team/TeamView';
import { InfoPills } from '../../../components/misc/InfoPills';
import { CheckList } from '../../../components/statistics/CheckList';
import { PlatformAlert, PlatformTextField, PlatformProgressIndicator } from '../../../components/misc/PlatformGraphics';
import { useAuthentication } from '../../../functions/Authentication';
import { APIMethods } from '../../../functions/APIMethods';
import { Statistics } from '../../../functions/Statistics';

interface Props {
  onTap?: (event: Event) => void;
}

const EventList: React.FC<Props> = ({ onTap }) => {
  const navigation = useNavigation();
  const route = useRoute();
  const [events, setEvents] = useState<Event[]>([]);
  const [localEvents, setLocalEvents] = useState<Event[]>([]);
  const [remoteEvents, setRemoteEvents] = useState<Event[]>([]);
  const [driverAnalysisEvents, setDriverAnalysisEvents] = useState<Event[]>([]);
  const [sortingModifier, setSortingModifier] = useState<OpModeType | null>(null);
  const [elementSort, setElementSort] = useState<ScoringElement | null>(null);
  const [statistics, setStatistics] = useState<Statistics>(Statistics.MEDIAN);
  const [ascending, setAscending] = useState<boolean>(false);
  const [newName, setNewName] = useState('');
  const [newNum, setNewNum] = useState('');
  const [bod, setBod] = useState<any[]>([]);
  const theme = useTheme();
  const { user } = useAuthentication();
  const format = new Intl.DateTimeFormat('en-US', { month: 'long', day: '2-digit', year: 'numeric' });
  const ref = useRef<any>(null);

  useEffect(() => {
    const unsubscribe = DataModel.events.onSnapshot(snapshot => {
      const events = snapshot.docs.map(doc => {
        const data = doc.data();
        return new Event({ ...data, id: doc.id });
      });
      setEvents(events);
      setLocalEvents(events.filter(event => event.type === EventType.local));
      setRemoteEvents(events.filter(event => event.type === EventType.remote));
      setDriverAnalysisEvents(events.filter(event => event.type === EventType.analysis));
    });

    return () => unsubscribe();
  }, []);

  useEffect(() => {
    if (ref.current) {
      ref.current.scrollToIndex({ index: 0 });
    }
  }, [localEvents, remoteEvents, driverAnalysisEvents]);

  const _onShare = async (event: Event) => {
    if (user && !user.isAnonymous) {
      if (!event.shared) {
        Alert.alert(
          'Upload Event',
          'Your event will still be private',
          [
            {
              text: 'Cancel',
              style: 'cancel',
            },
            {
              text: 'Upload',
              onPress: async () => {
                Alert.alert(
                  'Uploading...',
                  null,
                  [
                    {
                      text: 'Back',
                      style: 'cancel',
                    },
                  ],
                  {
                    onDismiss: async () => {
                      event.shared = true;
                      const json = event.toJson();
                      await DataModel.firebaseDatabase.ref(`Events/${event.gameName}/${event.id}`).set(json);
                      DataModel.events.remove(event);
                      setEvents(DataModel.events);
                    },
                  },
                );
              },
            },
          ],
        );
      } else {
        navigation.push(
          {
            name: 'EventShare',
            params: { event },
          },
        );
      }
    } else {
      Alert.alert(
        'Cannot Share Event',
        'You must be logged in to share an event.',
        [
          {
            text: 'OK',
            style: 'cancel',
          },
        ],
      );
    }
  };

  const _chosen = async (newType: EventType) => {
    Alert.alert(
      `New ${newType === EventType.remote ? 'Remote Event' : newType === EventType.local ? 'In Person Event' : 'Driver Analysis'}`,
      null,
      [
        {
          text: 'Cancel',
          style: 'cancel',
          onPress: () => {
            setNewName('');
            setNewNum('');
          },
        },
        {
          text: 'Add',
          onPress: () => {
            if (newName !== '' && newType !== EventType.analysis) {
              const newEvent = new Event({
                name: newName,
                type: newType,
                gameName: GameModel.gameName,
              });
              DataModel.events.add(newEvent);
              setEvents(DataModel.events);
            } else if (newName !== '' && newType === EventType.analysis) {
              const newEvent = new Event({
                name: newName,
                type: newType,
                gameName: GameModel.gameName,
              });
              DataModel.events.add(newEvent);
              setEvents(DataModel.events);
            }
            setNewName('');
            setNewNum('');
          },
        },
      ],
      {
        onDismiss: () => {
          setNewName('');
          setNewNum('');
        },
      },
    );
  };

  const _getMatches = async () => {
    if (events.length > 0 && events[0].hasKey()) {
      const response = await APIMethods.getMatches(events[0].getKey() ?? '');
      setBod(JSON.parse(response.body));
    }
  };

  const _onRemove = async (event: Event) => {
    Alert.alert(
      'Delete Event',
      'Are you sure?',
      [
        {
          text: 'Cancel',
          style: 'cancel',
        },
        {
          text: 'Confirm',
          style: 'destructive',
          onPress: async () => {
            if (event.shared) {
              await event.getRef()?.remove();
              DataModel.events.remove(event);
              setEvents(DataModel.events);
            } else {
              DataModel.events.remove(event);
              setEvents(DataModel.events);
            }
          },
        },
      ],
    );
  };

  const eventTile = ({ item }: { item: Event }) => {
    return (
      <TouchableOpacity onPress={() => {
        if (onTap) {
          event.getRef()?.once().then(map => {
            event.updateLocal(JSON.parse(JSON.stringify(map?.snapshot.value)), null);
            onTap(event);
          });
        } else if (event.type !== EventType.analysis) {
          navigation.navigate('EventView', { event });
        } else if (event.type === EventType.analysis) {
          if (event.getAllTeams().length === 0) {
            event.addTeam(new Team(newNum, newName));
            DataModel.events.remove(event);
            DataModel.events.add(event);
            setEvents(DataModel.events);
          }
          navigation.navigate('TeamView', { team: event.getAllTeams()[0], event });
        }
      }}>
        <View style={[styles.eventTile, { backgroundColor: theme.dark ? '#121212' : '#000000' }]}>
          <Text style={[styles.eventTileText, { color: theme.dark ? 'white' : 'white' }]}>{item.name}</Text>
          <View style={styles.pillContainer}>
            {item.shared ? (
              <InfoPills text="Shared" color="blue" />
            ) : (
              <InfoPills text="Private" color="grey" />
            )}
            {item.type !== EventType.analysis ? (
              <InfoPills text={format.format(item.createdAt.toDate())} color="red" />
            ) : null}
            {item.type === EventType.analysis ? (
              <InfoPills text={`Matches: ${item.matches.length}`} color="purple" />
            ) : null}
          </View>
        </View>
      </TouchableOpacity>
    );
  };

  const _teamConfig = () => {
    Alert.alert(
      'New Team',
      null,
      [
        {
          text: 'Cancel',
          style: 'cancel',
          onPress: () => {
            setNewName('');
            setNewNum('');
          },
        },
        {
          text: 'Add',
          onPress: () => {
            if (newNum !== '' && newName !== '') {
              events[0].addTeam(new Team(newNum, newName));
              setEvents(DataModel.events);
            }
            setNewName('');
            setNewNum('');
          },
        },
      ],
      {
        onDismiss: () => {
          setNewName('');
          setNewNum('');
        },
      },
    );
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerText}>My Events</Text>
        <Button
          title="ADD"
          onPress={() => {
            _chosen(EventType.local);
          }}
          color="#007bff"
        />
      </View>
      <FlatList
        ref={ref}
        data={localEvents}
        keyExtractor={(item) => item.id}
        renderItem={eventTile}
        style={styles.list}
      />
      <View style={styles.header}>
        <Text style={styles.headerText}>Driver Practice</Text>
        <Button
          title="ADD"
          onPress={() => {
            _chosen(EventType.analysis);
          }}
          color="#007bff"
        />
      </View>
      <FlatList
        ref={ref}
        data={driverAnalysisEvents}
        keyExtractor={(item) => item.id}
        renderItem={eventTile}
        style={styles.list}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
    padding: 16,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  headerText: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  list: {
    marginBottom: 16,
  },
  eventTile: {
    padding: 16,
    borderRadius: 8,
    marginBottom: 8,
    elevation: 2,
  },
  eventTileText: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  pillContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
  },
});

export default EventList;