typescript
import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, Alert, ActivityIndicator, Platform } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useTheme } from '@react-navigation/native';
import { useRoute } from '@react-navigation/native';
import { OpModeType, EventType, Role, Team, Match, ScoringElement, Statistics, Dice } from '../models/AppModel';
import { getMatches } from '../functions/APIMethods';
import { TeamList } from '../components/team/TeamList';
import { MatchList } from '../components/match/MatchList';
import { AllianceSelection } from '../components/team/AllianceSelection';
import { CheckList } from '../components/statistics/CheckList';
import { ImageView } from '../components/misc/ImageView';
import { EventShare } from './EventShare';
import { opModeExt } from '../functions/Extensions';
import { PlatformAlert, PlatformTextField, PlatformProgressIndicator, PlatformDialogAction } from '../components/misc/PlatformGraphics';
import { firebaseDatabase } from '../functions/FirebaseMethods';
import { useAuthContext } from '../context/AuthContext';

interface EventProps {
  event: Event;
}

export const EventView: React.FC<EventProps> = ({ event }) => {
  const navigation = useNavigation();
  const theme = useTheme();
  const route = useRoute();
  const [sortingModifier, setSortingModifier] = useState<OpModeType | null>(null);
  const [elementSort, setElementSort] = useState<ScoringElement | null>(null);
  const [statistics, setStatistics] = useState<Statistics>(Statistics.MEDIAN);
  const [ascending, setAscending] = useState<boolean>(false);
  const [matches, setMatches] = useState<Match[]>([]);
  const [tab, setTab] = useState<number>(0);
  const [bod, setBod] = useState<any[]>([]);
  const { user } = useAuthContext();

  useEffect(() => {
    const fetchMatches = async () => {
      if (event.hasKey()) {
        const response = await getMatches(event.getKey() ?? '');
        setBod(JSON.parse(response.body));
      }
    };

    fetchMatches();
  }, []);

  useEffect(() => {
    if (bod.length > 0) {
      const bruh = event.getSortedMatches(ascending);
      let p = 1;
      for (const x of bod) {
        if (event.matches.length < p) {
          if (event.matches.length > p - 1) {
            bruh[event.matches.length - p].setAPIScore(x['red_score'], x['blue_score']);
          }
          p++;
        }
      }
      setMatches(bruh);
    }
  }, [bod]);

  const _getMatches = async () => {
    if (event.hasKey()) {
      const response = await getMatches(event.getKey() ?? '');
      setBod(JSON.parse(response.body));
      setMatches(event.getSortedMatches(ascending));
    }
  };

  const _teamConfig = () => {
    Alert.prompt(
      'New Team',
      null,
      [
        {
          text: 'Cancel',
          style: 'cancel',
        },
        {
          text: 'Add',
          onPress: (newNumber, newName) => {
            const cleanNumber = newNumber.split('').reduce((value, element) => (parseInt(element) !== NaN ? value + element : value), '');
            if (cleanNumber.length > 0 && newName.length > 0) {
              event.addTeam(new Team(cleanNumber, newName));
            }
          },
        },
      ],
      {
        keyboardType: 'number-pad',
        textInputs: [
          { placeholder: 'Team number' },
          { placeholder: 'Team Name' },
        ],
      }
    );
  };

  const _matchConfig = () => {
    navigation.navigate('MatchConfig', { event: event });
  };

  const _onShare = () => {
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
                      await firebaseDatabase.ref().child(`Events/${event.gameName}/${event.id}`).set(json);
                      navigation.goBack();
                    },
                  }
                );
              },
            },
          ]
        );
      } else {
        navigation.navigate('EventShare', { event: event });
      }
    } else {
      Alert.alert('Cannot Share Event', 'You must be logged in to share an event.');
    }
  };

  const _onAlliance = () => {
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
                      await firebaseDatabase.ref().child(`Events/${event.gameName}/${event.id}`).set(json);
                      navigation.goBack();
                    },
                  }
                );
              },
            },
          ]
        );
      } else {
        navigation.navigate('EventShare', { event: event });
      }
    } else {
      Alert.alert('Cannot Share Event', 'You must be logged in to share an event.');
    }
  };

  const renderTabContent = () => {
    if (tab === 0) {
      return (
        <MatchList
          event={event}
          ascending={ascending}
          matches={matches}
        />
      );
    } else {
      return (
        <TeamList
          event={event}
          sortMode={sortingModifier}
          statConfig={event.statConfig}
          elementSort={elementSort}
          statistic={statistics}
        />
      );
    }
  };

  const handleSort = () => {
    setAscending(!ascending);
  };

  const handleSortingModifierChange = (newValue: OpModeType | null) => {
    setSortingModifier(newValue);
    setElementSort(null);
    if (newValue) {
      Alert.alert(
        'Select Sorting Element',
        null,
        [
          {
            text: 'Cancel',
            style: 'cancel',
          },
          ...Score('', Dice.none, event.gameName)
            .getScoreDivision(newValue)
            .getElements()
            .parse()
            .map((e) => ({
              text: e?.name ?? 'Total',
              onPress: () => {
                setElementSort(e);
              },
            })),
        ]
      );
    }
  };

  const handleStatisticsChange = (newValue: Statistics) => {
    setStatistics(newValue);
  };

  return (
    <View style={styles.container}>
      <View style={styles.appBar}>
        {tab === 0 ? (
          <Text style={styles.appBarTitle}>Matches</Text>
        ) : (
          <Text style={styles.appBarTitle}>Teams</Text>
        )}
        <View style={styles.appBarActions}>
          {tab === 0 ? (
            <TouchableOpacity onPress={() => navigation.navigate('MatchConfig', { event: event })}>
              <Text style={styles.appBarAction}>Add Match</Text>
            </TouchableOpacity>
          ) : (
            <TouchableOpacity onPress={_teamConfig}>
              <Text style={styles.appBarAction}>Add Team</Text>
            </TouchableOpacity>
          )}
          <TouchableOpacity onPress={() => _onShare()}>
            <Text style={styles.appBarAction}>Share</Text>
          </TouchableOpacity>
          {event.hasKey() && tab !== 0 && (
            <TouchableOpacity onPress={() => navigation.navigate('ImageView', { event: event })}>
              <Text style={styles.appBarAction}>Import Schedule</Text>
            </TouchableOpacity>
          )}
          {event.hasKey() && tab !== 0 && (
            <TouchableOpacity onPress={_getMatches}>
              <Text style={styles.appBarAction}>Fetch Scores</Text>
            </TouchableOpacity>
          )}
          {tab === 0 && (
            <TouchableOpacity onPress={() => handleSort()}>
              <Text style={styles.appBarAction}>
                {ascending ? 'Sort Up' : 'Sort Down'}
              </Text>
            </TouchableOpacity>
          )}
          {tab === 0 && (
            <TouchableOpacity onPress={() => navigation.navigate('AllianceSelection', { event: event })}>
              <Text style={styles.appBarAction}>Alliance Selection</Text>
            </TouchableOpacity>
          )}
          {tab === 0 && (
            <TouchableOpacity onPress={() => navigation.navigate('CheckList', { event: event, statConfig: event.statConfig })}>
              <Text style={styles.appBarAction}>Configure</Text>
            </TouchableOpacity>
          )}
          {tab === 0 && (
            <View style={styles.appBarDropdown}>
              <TouchableOpacity onPress={() => {
                Alert.alert(
                  'Select Statistics',
                  null,
                  [
                    {
                      text: 'Cancel',
                      style: 'cancel',
                    },
                    ...Object.values(Statistics).map((value) => ({
                      text: value.name,
                      onPress: () => handleStatisticsChange(value),
                    })),
                  ]
                );
              }}>
                <Text style={styles.appBarAction}>{statistics.name}</Text>
              </TouchableOpacity>
            </View>
          )}
          {tab === 1 && (
            <View style={styles.appBarDropdown}>
              <TouchableOpacity onPress={() => {
                Alert.alert(
                  'Select Sorting Mode',
                  null,
                  [
                    {
                      text: 'Cancel',
                      style: 'cancel',
                    },
                    ...opModeExt
                      .getAll()
                      .map((value) => ({
                        text: value?.toVal() ?? 'Total',
                        onPress: () => handleSortingModifierChange(value),
                      })),
                  ]
                );
              }}>
                <Text style={styles.appBarAction}>{sortingModifier?.toVal() ?? 'Total'}</Text>
              </TouchableOpacity>
            </View>
          )}
        </View>
      </View>
      <View style={styles.tabContainer}>
        {event.type !== EventType.remote && event.type !== EventType.analysis && (
          <View style={styles.tabs}>
            <TouchableOpacity
              style={[styles.tab, tab === 0 ? styles.activeTab : null]}
              onPress={() => setTab(0)}
            >
              <Text style={[styles.tabText, tab === 0 ? styles.activeTabText : null]}>Matches</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.tab, tab === 1 ? styles.activeTab : null]}
              onPress={() => setTab(1)}
            >
              <Text style={[styles.tabText, tab === 1 ? styles.activeTabText : null]}>Teams</Text>
            </TouchableOpacity>
          </View>
        )}
        {renderTabContent()}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  appBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: theme.colors.primary,
    padding: 16,
  },
  appBarTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: 'white',
  },
  appBarActions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  appBarAction: {
    fontSize: 16,
    color: 'white',
    margin: 10,
  },
  appBarDropdown: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  tabContainer: {
    flex: 1,
    padding: 16,
  },
  tabs: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 16,
  },
  tab: {
    padding: 10,
    backgroundColor: 'lightgray',
    borderRadius: 10,
  },
  activeTab: {
    backgroundColor: 'gray',
  },
  tabText: {
    fontSize: 16,
  },
  activeTabText: {
    fontWeight: 'bold',
  },
});