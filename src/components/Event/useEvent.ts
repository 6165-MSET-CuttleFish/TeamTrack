typescript
import React, { useState, useEffect } from 'react';
import { useNavigation, useRoute } from '@react-navigation/native';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Platform,
  ScrollView,
  FlatList,
  TextInput,
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import { Event, EventType, Team, Role, Match, OpModeType, Score, Dice } from '../models/GameModel';
import { useAppModel } from '../models/AppModel';
import { TeamList } from '../components/TeamList';
import { MatchList } from '../components/MatchList';
import { CheckList } from '../components/CheckList';
import { useStatistics } from '../functions/Statistics';
import { AllianceSelection } from '../components/AllianceSelection';
import { ImageView } from '../components/ImageView';
import { APIMethods } from '../functions/APIMethods';

export const useEvent = () => {
  const navigation = useNavigation();
  const route = useRoute();
  const { darkTheme } = useTheme();
  const { events, saveEvents } = useAppModel();
  const event = events.find(
    (e: Event) => e.id === route.params?.eventId
  ) as Event;

  const [tab, setTab] = useState(0);
  const [sortingModifier, setSortingModifier] = useState<OpModeType | null>(null);
  const [elementSort, setElementSort] = useState<ScoringElement | null>(null);
  const [ascending, setAscending] = useState(false);
  const { statistics, setStatistics } = useStatistics();

  const [matches, setMatches] = useState<Match[]>(event.matches);
  const [bod, setBod] = useState<any[]>([]);
  const [newName, setNewName] = useState('');
  const [newNumber, setNewNumber] = useState('');

  const _getMatches = async () => {
    if (event.hasKey()) {
      const response = await APIMethods.getMatches(event.getKey() || '');
      setBod(JSON.parse(response.body));
    }
  };

  const handleTabChange = (index: number) => {
    setTab(index);
  };

  const _onShare = async (e: Event) => {
    const user = await FirebaseAuth.getInstance().currentUser();
    if (user && !user.isAnonymous) {
      if (!e.shared) {
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
                  'Please wait...',
                  [{ text: 'OK', onPress: () => {} }],
                  { cancelable: false }
                );
                e.shared = true;
                const json = e.toJson();
                await firebaseDatabase
                  .ref()
                  .child(`Events/${e.gameName}/${e.id}`)
                  .set(json);
                events.remove(e);
                saveEvents();
                navigation.goBack();
              },
            },
          ]
        );
      } else {
        navigation.navigate('EventShare', { event: e });
      }
    } else {
      Alert.alert('Cannot Share Event', 'You must be logged in to share an event.');
    }
  };

  const _matchConfig = async () => {
    await navigation.navigate('MatchConfig', { event: event });
  };

  const _teamConfig = () => {
    Alert.prompt(
      'New Team',
      null,
      [
        {
          text: 'Cancel',
          onPress: () => {
            setNewName('');
            setNewNumber('');
          },
          style: 'cancel',
        },
        {
          text: 'Add',
          onPress: () => {
            setNewNumber(newNumber.replace(/[^0-9]/g, ''));
            if (newNumber.length > 0 && newName.length > 0) {
              event.addTeam(new Team(newNumber, newName));
              setNewName('');
              setNewNumber('');
            }
          },
        },
      ],
      {
        textInputProps: {
          keyboardType: 'numeric',
        },
        textInputs: [
          {
            placeholder: 'Team number',
            onChangeText: setNewNumber,
            value: newNumber,
          },
          {
            placeholder: 'Team Name',
            onChangeText: setNewName,
            value: newName,
          },
        ],
      }
    );
  };

  const handleSortingModifierChange = (newValue: OpModeType | null) => {
    setSortingModifier(newValue);
    setElementSort(null);
    if (sortingModifier) {
      Alert.alert(
        'Sort By Element',
        null,
        Score('', Dice.none, event.gameName)
          .getScoreDivision(newValue)
          .getElements()
          .parse()
          .map((e) => ({
            text: e?.name ?? 'Total',
            onPress: () => {
              setElementSort(e);
            },
          }))
          .concat([{ text: 'Cancel', onPress: () => {} }]),
        { cancelable: true }
      );
    }
  };

  const handleAscendingChange = () => {
    setAscending(!ascending);
  };

  useEffect(() => {
    _getMatches();
  }, []);

  useEffect(() => {
    const sortedMatches = event.getSortedMatches(ascending);
    setMatches(sortedMatches);
  }, [ascending, event, bod]);

  return {
    tab,
    handleTabChange,
    sortingModifier,
    handleSortingModifierChange,
    elementSort,
    setElementSort,
    ascending,
    handleAscendingChange,
    statistics,
    setStatistics,
    matches,
    _onShare,
    _matchConfig,
    _teamConfig,
    event,
    darkTheme,
  };
};