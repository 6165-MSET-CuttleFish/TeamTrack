tsx
import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, Alert, ActivityIndicator, Platform } from 'react-native';
import { useNavigation, useRoute } from '@react-navigation/native';
import { useTheme } from '@react-navigation/native';
import { Picker } from '@react-native-picker/picker';
import {  useAuth } from '../../hooks/useAuth';
import { Event, Team, EventType, OpModeType, Statistics, Role,  Match, ScoringElement, Dice } from '../../models/GameModel';
import { useEventContext } from '../../contexts/EventContext';
import { useTeamContext } from '../../contexts/TeamContext';
import { useMatchContext } from '../../contexts/MatchContext';
import { useUserContext } from '../../contexts/UserContext';
import { useStatisticsContext } from '../../contexts/StatisticsContext';
import { TeamList } from '../team/TeamList';
import { MatchList } from '../match/MatchList';
import { AllianceSelection } from '../team/AllianceSelection';
import { CheckList } from '../../components/statistics/CheckList';
import { ImageView } from './ImageView';
import { APIMethods } from '../../functions/APIMethods';
import { PlatformTextField } from '../../components/misc/PlatformGraphics';
import { PlatformButton } from '../../components/misc/PlatformGraphics';
import { PlatformAlert } from '../../components/misc/PlatformGraphics';
import { PlatformProgressIndicator } from '../../components/misc/PlatformGraphics';
import { PlatformDialogAction } from '../../components/misc/PlatformGraphics';
import { useDatabase } from '../../hooks/useDatabase';
import { useStorage } from '../../hooks/useStorage';

const opModeExt = [
  { value: OpModeType.AUTO, label: 'Auto' },
  { value: OpModeType.TELEOP, label: 'Teleop' },
  { value: OpModeType.ENDGAME, label: 'Endgame' },
  { value: null, label: 'Total' },
];

const statisticsExt = [
  { value: Statistics.AVERAGE, label: 'Average' },
  { value: Statistics.MEDIAN, label: 'Median' },
  { value: Statistics.TOTAL, label: 'Total' },
  { value: Statistics.HIGH, label: 'High' },
  { value: Statistics.LOW, label: 'Low' },
];

export default function Event() {
  const navigation = useNavigation();
  const route = useRoute();
  const { event, setEvent, updateEvent } = useEventContext();
  const { teams, updateTeams } = useTeamContext();
  const { matches, updateMatches } = useMatchContext();
  const { currentUser } = useUserContext();
  const { statistics, setStatistics } = useStatisticsContext();
  const { database } = useDatabase();
  const { storage } = useStorage();
  const theme = useTheme();
  const { user } = useAuth();

  const [sortingModifier, setSortingModifier] = useState<OpModeType | null>(null);
  const [elementSort, setElementSort] = useState<ScoringElement | null>(null);
  const [ascending, setAscending] = useState<boolean>(false);
  const [tab, setTab] = useState<number>(0);
  const [bod, setBod] = useState<any[]>([]);
  const [newName, setNewName] = useState<string>('');
  const [newNumber, setNewNumber] = useState<string>('');

  useEffect(() => {
    const fetchData = async () => {
      if (event.hasKey()) {
        const response = await APIMethods.getMatches(event.getKey() ?? '');
        setBod(JSON.parse(response.body));
      }
    };

    fetchData();
  }, [event]);

  const _getMatches = async () => {
    if (event.hasKey()) {
      const response = await APIMethods.getMatches(event.getKey() ?? '');
      setBod(JSON.parse(response.body));
    }
  };

  const _onShare = async (e: Event) => {
    if (user && !user.isAnonymous) {
      if (!e.shared) {
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
                  'Uploading',
                  '',
                  [
                    {
                      text: 'Back',
                      style: 'cancel',
                      onPress: () => {
                        Alert.alert(
                          'Upload Failed',
                          'Please check your internet connection',
                          [
                            {
                              text: 'OK',
                              style: 'cancel',
                            },
                          ]
                        );
                      },
                    },
                  ],
                  {
                    onDismiss: () => {
                      Alert.alert(
                        'Upload Failed',
                        'Please check your internet connection',
                        [
                          {
                            text: 'OK',
                            style: 'cancel',
                          },
                        ]
                      );
                    },
                  }
                );
                try {
                  e.shared = true;
                  await database.ref(`Events/${e.gameName}/${e.id}`).set(e.toJson());
                  updateEvent(e);
                  Alert.alert(
                    'Upload Successful',
                    'Your event is now shared',
                    [
                      {
                        text: 'OK',
                        style: 'cancel',
                      },
                    ]
                  );
                } catch (error) {
                  console.error(error);
                  Alert.alert(
                    'Upload Failed',
                    'Please check your internet connection',
                    [
                      {
                        text: 'OK',
                        style: 'cancel',
                      },
                    ]
                  );
                }
              },
            },
          ]
        );
      } else {
        navigation.navigate('EventShare', { event: e });
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
        ]
      );
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
          onPress: () => {
            setNewName('');
            setNewNumber('');
          },
        },
        {
          text: 'Add',
          onPress: () => {
            setNewNumber(newNumber.replace(/[^0-9]/g, ''));
            if (newNumber.length > 0 && newName.length > 0) {
              const newTeam = new Team(newNumber, newName);
              updateTeams(newTeam);
              setNewName('');
              setNewNumber('');
            }
          },
        },
      ],
      {
        placeholder: 'Team number',
        keyboardType: 'numeric',
        onChangeText: (text) => setNewNumber(text),
      },
      {
        placeholder: 'Team Name',
        onChangeText: (text) => setNewName(text),
      }
    );
  };

  const _matchConfig = () => {
    navigation.navigate('MatchConfig', { event: event });
  };

  const _onAlliance = (e: Event) => {
    if (user && !user.isAnonymous) {
      if (!e.shared) {
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
                  'Uploading',
                  '',
                  [
                    {
                      text: 'Back',
                      style: 'cancel',
                      onPress: () => {
                        Alert.alert(
                          'Upload Failed',
                          'Please check your internet connection',
                          [
                            {
                              text: 'OK',
                              style: 'cancel',
                            },
                          ]
                        );
                      },
                    },
                  ],
                  {
                    onDismiss: () => {
                      Alert.alert(
                        'Upload Failed',
                        'Please check your internet connection',
                        [
                          {
                            text: 'OK',
                            style: 'cancel',
                          },
                        ]
                      );
                    },
                  }
                );
                try {
                  e.shared = true;
                  await database.ref(`Events/${e.gameName}/${e.id}`).set(e.toJson());
                  updateEvent(e);
                  Alert.alert(
                    'Upload Successful',
                    'Your event is now shared',
                    [
                      {
                        text: 'OK',
                        style: 'cancel',
                      },
                    ]
                  );
                } catch (error) {
                  console.error(error);
                  Alert.alert(
                    'Upload Failed',
                    'Please check your internet connection',
                    [
                      {
                        text: 'OK',
                        style: 'cancel',
                      },
                    ]
                  );
                }
              },
            },
          ]
        );
      } else {
        navigation.navigate('EventShare', { event: e });
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
        ]
      );
    }
  };

  const _handleSort = () => {
    setAscending(!ascending);
  };

  const _handleTabChange = (index: number) => {
    setTab(index);
  };

  const _handleSortingModifierChange = (value: OpModeType | null) => {
    setSortingModifier(value);
    setElementSort(null);
  };

  const _handleElementSortChange = (value: ScoringElement | null) => {
    setElementSort(value);
  };

  const _handleStatisticsChange = (value: Statistics) => {
    setStatistics(value);
  };

  const renderTabContent = () => {
    switch (tab) {
      case 0:
        return (
          <MatchList
            event={event}
            ascending={ascending}
            handleSort={_handleSort}
          />
        );
      case 1:
        return (
          <TeamList
            event={event}
            sortMode={sortingModifier}
            statConfig={event.statConfig}
            elementSort={elementSort}
            statistic={statistics}
            handleSortingModifierChange={_handleSortingModifierChange}
            handleElementSortChange={_handleElementSortChange}
            handleStatisticsChange={_handleStatisticsChange}
          />
        );
      default:
        return null;
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.appBar}>
        <View style={styles.appBarTitle}>
          <Text style={styles.appBarTitleText}>{tab === 0 ? '' : 'Matches'}</Text>
        </View>
        <View style={styles.appBarActions}>
          {tab === 0 && (
            <TouchableOpacity onPress={() => {
              Alert.prompt(
                'Configure Statistics',
                null,
                [
                  {
                    text: 'Cancel',
                    style: 'cancel',
                  },
                  {
                    text: 'Save',
                    onPress: () => {
                      updateEvent(event);
                    },
                  },
                ],
                null,
                {
                  placeholder: 'Enter a value',
                  onChangeText: (text) => {
                    event.statConfig.updateStat(text, event.statConfig.getStat(text));
                  },
                },
                {
                  placeholder: 'Enter a value',
                  onChangeText: (text) => {
                    event.statConfig.updateStat(text, event.statConfig.getStat(text));
                  },
                },
                {
                  placeholder: 'Enter a value',
                  onChangeText: (text) => {
                    event.statConfig.updateStat(text, event.statConfig.getStat(text));
                  },
                },
                {
                  placeholder: 'Enter a value',
                  onChangeText: (text) => {
                    event.statConfig.updateStat(text, event.statConfig.getStat(text));
                  },
                },
                {
                  placeholder: 'Enter a value',
                  onChangeText: (text) => {
                    event.statConfig.updateStat(text, event.statConfig.getStat(text));
                  },
                },
                {
                  placeholder: 'Enter a value',
                  onChangeText: (text) => {
                    event.statConfig.updateStat(text, event.statConfig.getStat(text));
                  },
                },
                {
                  placeholder: 'Enter a value',
                  onChangeText: (text) => {
                    event.statConfig.updateStat(text, event.statConfig.getStat(text));
                  },
                },
              );
            }}>
              <View style={styles.appBarAction}>
                <Text style={styles.appBarActionText}>Configure</Text>
              </View>
            </TouchableOpacity>
          )}
          <TouchableOpacity onPress={() => _onShare(event)}>
            <View style={styles.appBarAction}>
              <Text style={styles.appBarActionText}>{event.shared ? 'Share' : 'Upload'}</Text>
            </View>
          </TouchableOpacity>
          {tab !== 0 && event.hasKey() && (
            <TouchableOpacity onPress={() => navigation.navigate('ImageView', { event: event })}>
              <View style={styles.appBarAction}>
                <Text style={styles.appBarActionText}>Import Match Schedule</Text>
              </View>
            </TouchableOpacity>
          )}
          {tab !== 0 && event.hasKey() && (
            <TouchableOpacity onPress={() => _getMatches()}>
              <View style={styles.appBarAction}>
                <Text style={styles.appBarActionText}>Fetch API Scores</Text>
              </View>
            </TouchableOpacity>
          )}
          {tab === 0 && (
            <View style={styles.appBarAction}>
              <Picker
                selectedValue={statistics}
                onValueChange={(itemValue) => _handleStatisticsChange(itemValue)}
                style={styles.picker}
              >
                {statisticsExt.map((item) => (
                  <Picker.Item key={item.value} label={item.label} value={item.value} />
                ))}
              </Picker>
            </View>
          )}
          {tab !== 0 && (
            <TouchableOpacity onPress={() => _handleSort()}>
              <View style={styles.appBarAction}>
                <Text style={styles.appBarActionText}>{ascending ? 'Sort Up' : 'Sort Down'}</Text>
              </View>
            </TouchableOpacity>
          )}
          {tab === 0 && (
            <View style={styles.appBarAction}>
              <Picker
                selectedValue={sortingModifier}
                onValueChange={(itemValue) => _handleSortingModifierChange(itemValue)}
                style={styles.picker}
              >
                {opModeExt.map((item) => (
                  <Picker.Item key={item.value} label={item.label} value={item.value} />
                ))}
              </Picker>
            </View>
          )}
          {tab === 0 && (
            <View style={styles.appBarAction}>
              <TouchableOpacity onPress={() => {
                Alert.alert(
                  'Sort By',
                  null,
                  opModeExt
                    .filter((item) => item.value !== null)
                    .map((item) => ({
                      text: item.label,
                      onPress: () => {
                        setSortingModifier(item.value);
                        Alert.alert(
                          'Select Element',
                          null,
                          Score('', Dice.none, event.gameName)
                            .getScoreDivision(item.value)
                            .getElements()
                            .parse()
                            .map((element) => ({
                              text: element?.name ?? 'Total',
                              onPress: () => {
                                setElementSort(element);
                              },
                            }))
                            .concat([{ text: 'Cancel', style: 'cancel' }]),
                          {
                            onDismiss: () => {
                              setSortingModifier(null);
                            },
                          }
                        );
                      },
                    }))
                    .concat([{ text: 'Cancel', style: 'cancel' }]),
                  {
                    onDismiss: () => {
                      setSortingModifier(null);
                    },
                  }
                );
              }}>
                <View style={styles.appBarAction}>
                  <Text style={styles.appBarActionText}>Sort</Text>
                </View>
              </TouchableOpacity>
            </View>
          )}
          <View style={styles.appBarAction}>
            <TouchableOpacity onPress={() => {
              navigation.navigate('TeamSearch', {
                statConfig: event.statConfig,
                elementSort: elementSort,
                teams: event.statConfig.sorted
                  ? event.teams.sortedTeams(sortingModifier, elementSort, event.statConfig, matches.values.toArray(), statistics)
                  : event.teams.orderedTeams(),
                sortMode: sortingModifier,
                event: event,
                statistics: statistics,
                isUserTeam: false,
              });
            }}>
              <View style={styles.appBarAction}>
                <Text style={styles.appBarActionText}>Search</Text>
              </View>
            </TouchableOpacity>
          </View>
        </View>
      </View>
      <View style={styles.tabContainer}>
        <View style={styles.tab}>
          <TouchableOpacity style={styles.tabButton} onPress={() => _handleTabChange(0)}>
            <View style={styles.tabIcon}>
              <Text style={styles.tabIconText}>Matches</Text>
            </View>
          </TouchableOpacity>
        </View>
        <View style={styles.tab}>
          <TouchableOpacity style={styles.tabButton} onPress={() => _handleTabChange(1)}>
            <View style={styles.tabIcon}>
              <Text style={styles.tabIconText}>Teams</Text>
            </View>
          </TouchableOpacity>
        </View>
      </View>
      <View style={styles.contentContainer}>
        {renderTabContent()}
      </View>
      {event.type !== EventType.remote && event.type !== EventType.analysis && (
        <View style={styles.floatingActionButtonContainer}>
          {event.role !== Role.viewer && (
            <TouchableOpacity
              style={styles.floatingActionButton}
              onPress={() => {
                tab === 0 ? _matchConfig() : _teamConfig();
              }}
            >
              <View style={styles.floatingActionButtonIcon}>
                <Text style={styles.floatingActionButtonIconText}>+</Text>
              </View>
            </TouchableOpacity>
          )}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  appBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 10,
    backgroundColor: '#3f51b5',
  },
  appBarTitle: {
    flex: 1,
  },
  appBarTitleText: {
    fontSize: 20,
    color: '#fff',
  },
  appBarActions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  appBarAction: {
    marginLeft: 10,
    padding: 10,
    borderRadius: 5,
    backgroundColor: '#424242',
  },
  appBarActionText: {
    fontSize: 16,
    color: '#fff',
  },
  tabContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around',
    padding: 10,
    backgroundColor: '#fff',
  },
  tab: {
    flex: 1,
  },
  tabButton: {
    padding: 10,
    borderRadius: 5,
  },
  tabIcon: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: 10,
    borderRadius: 5,
    backgroundColor: '#e0e0e0',
  },
  tabIconText: {
    fontSize: 16,
  },
  contentContainer: {
    flex: 1,
    padding: 10,
    backgroundColor: '#fff',
  },
  floatingActionButtonContainer: {
    position: 'absolute',
    bottom: 20,
    right: 20,
  },
  floatingActionButton: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: '#3f51b5',
    alignItems: 'center',
    justifyContent: 'center',
  },
  floatingActionButtonIcon: {
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
  floatingActionButtonIconText: {
    fontSize: 20,
    color: '#3f51b5',
  },
  picker: {
    width: 100,
  },
});