typescript
import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert, Platform, ActivityIndicator } from 'react-native';
import { useNavigation, useRoute } from '@react-navigation/native';
import { useTheme } from '@react-navigation/native';
import { useAuthContext } from '../../contexts/AuthContext';
import { useEventContext } from '../../contexts/EventContext';
import { useTeamContext } from '../../contexts/TeamContext';
import { useMatchContext } from '../../contexts/MatchContext';
import { Event } from '../../models/Event';
import { Team } from '../../models/Team';
import { Match } from '../../models/Match';
import { Score, OpModeType, ScoringElement, Dice } from '../../models/Score';
import { Statistics } from '../../functions/Statistics';
import { TeamList } from '../team/TeamList';
import { MatchList } from '../match/MatchList';
import { AllianceSelection } from '../team/AllianceSelection';
import { CheckList } from '../../components/statistics/CheckList';
import { EventShare } from './EventShare';
import { ImageView } from './ImageView';
import { APIMethods } from '../../functions/APIMethods';

const opModeExt = {
  getAll: () => [OpModeType.AUTO, OpModeType.TELEOP, OpModeType.ENDGAME, null],
  toVal: (opMode) => {
    if (opMode === OpModeType.AUTO) return 'Auto';
    if (opMode === OpModeType.TELEOP) return 'Teleop';
    if (opMode === OpModeType.ENDGAME) return 'Endgame';
    return 'Total';
  },
};

const useEventView = () => {
  const navigation = useNavigation();
  const route = useRoute();
  const event = route.params.event as Event;
  const [sortingModifier, setSortingModifier] = useState<OpModeType | null>(null);
  const [elementSort, setElementSort] = useState<ScoringElement | null>(null);
  const [statistics, setStatistics] = useState<Statistics>(Statistics.MEDIAN);
  const [ascending, setAscending] = useState<boolean>(false);
  const [tab, setTab] = useState<number>(0);
  const [bod, setBod] = useState<any[]>([]);
  const { user } = useAuthContext();
  const { theme } = useTheme();
  const { updateEvent } = useEventContext();
  const { teams, updateTeam } = useTeamContext();
  const { matches, updateMatch } = useMatchContext();
  const [newName, setNewName] = useState<string>('');
  const [newNumber, setNewNumber] = useState<string>('');

  const getMatches = async () => {
    if (event.hasKey()) {
      const response = await APIMethods.getMatches(event.getKey() ?? '');
      setBod(JSON.parse(response.data));
    }
  };

  useEffect(() => {
    if (event.hasKey()) {
      getMatches();
    }
  }, []);

  const materialTabs = () => {
    return [
      <View style={styles.tabContainer}>
        <TeamList
          event={event}
          sortMode={sortingModifier}
          statConfig={event.statConfig}
          elementSort={elementSort}
          statistic={statistics}
        />
        <TouchableOpacity
          style={styles.floatingButton}
          onPress={() => {
            if (event.userTeam.number !== '0') {
              navigation.navigate('AllianceSelection', {
                event: event,
                sortMode: sortingModifier,
                statConfig: event.statConfig,
                elementSort: elementSort,
                statistic: statistics,
              });
            } else {
              Alert.prompt(
                'Enter Team Number',
                null,
                (text) => {
                  if (text) {
                    event.updateUserTeam(new Team(text, text));
                    updateEvent(event);
                  }
                },
                {
                  type: 'plain-text',
                  placeholder: 'Team Number',
                  keyboardType: 'numeric',
                }
              );
            }
          }}
        >
          <Text style={styles.buttonText}>Alliance Selection</Text>
        </TouchableOpacity>
      </View>,
      <MatchList
        event={event}
        ascending={ascending}
        matches={event.getSortedMatches(ascending)}
        updateMatch={updateMatch}
      />,
    ];
  };

  const handleTeamConfig = () => {
    Alert.prompt(
      'New Team',
      null,
      (text) => {
        if (text) {
          setNewNumber(text.replace(/[^0-9]/g, ''));
        }
      },
      {
        type: 'plain-text',
        placeholder: 'Team Number',
        keyboardType: 'numeric',
      }
    ).then(() => {
      Alert.prompt(
        'New Team',
        null,
        (text) => {
          if (text) {
            setNewName(text);
            if (newNumber.length > 0 && newName.length > 0) {
              event.addTeam(new Team(newNumber, newName));
              updateEvent(event);
            }
            setNewName('');
            setNewNumber('');
          }
        },
        {
          type: 'plain-text',
          placeholder: 'Team Name',
        }
      );
    });
  };

  const handleMatchConfig = () => {
    navigation.navigate('MatchConfig', { event: event });
  };

  const handleShare = (e: Event) => {
    if (!user?.isAnonymous) {
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
                  null,
                  [
                    {
                      text: 'Back',
                      onPress: () => {},
                      style: 'cancel',
                    },
                  ],
                  { cancelable: false }
                );
                e.shared = true;
                const json = e.toJson();
                await APIMethods.setEvent(json, e.gameName, e.id);
                updateEvent(event);
                Alert.alert('Event Uploaded', 'Your event has been uploaded!');
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

  const handleAlliance = (e: Event) => {
    if (!user?.isAnonymous) {
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
                  null,
                  [
                    {
                      text: 'Back',
                      onPress: () => {},
                      style: 'cancel',
                    },
                  ],
                  { cancelable: false }
                );
                e.shared = true;
                const json = e.toJson();
                await APIMethods.setEvent(json, e.gameName, e.id);
                updateEvent(event);
                Alert.alert('Event Uploaded', 'Your event has been uploaded!');
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

  return {
    event,
    sortingModifier,
    elementSort,
    statistics,
    ascending,
    tab,
    bod,
    materialTabs,
    handleTeamConfig,
    handleMatchConfig,
    handleShare,
    handleAlliance,
    setSortingModifier,
    setElementSort,
    setStatistics,
    setAscending,
    setTab,
    setNewName,
    setNewNumber,
    teams,
    matches,
    theme,
    user,
  };
};

const EventView = () => {
  const {
    event,
    sortingModifier,
    elementSort,
    statistics,
    ascending,
    tab,
    bod,
    materialTabs,
    handleTeamConfig,
    handleMatchConfig,
    handleShare,
    handleAlliance,
    setSortingModifier,
    setElementSort,
    setStatistics,
    setAscending,
    setTab,
    setNewName,
    setNewNumber,
    teams,
    matches,
    theme,
    user,
  } = useEventView();

  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [isUploading, setIsUploading] = useState<boolean>(false);

  const handleSearch = () => {
    if (tab === 0) {
      navigation.navigate('TeamSearch', {
        statConfig: event.statConfig,
        elementSort: elementSort,
        teams: event.statConfig.sorted
          ? event.teams.sortedTeams(
              sortingModifier,
              elementSort,
              event.statConfig,
              matches.values.toList(),
              statistics
            )
          : event.teams.orderedTeams(),
        sortMode: sortingModifier,
        event: event,
        statistics: statistics,
        isUserTeam: false,
      });
    } else {
      navigation.navigate('MatchSearch', {
        statConfig: event.statConfig,
        matches: event.getSortedMatches(ascending),
        event: event,
        ascending: ascending,
      });
    }
  };

  const handleFetchScores = async () => {
    setIsLoading(true);
    if (event.hasKey()) {
      await getMatches();
      let p = 1;
      const bruh = event.getSortedMatches(ascending);
      bod.forEach((x) => {
        if (event.matches.length < p) {
          if (event.matches.length > p - 1) {
            bruh[event.matches.length - p].setAPIScore(x['red_score'], x['blue_score']);
            updateMatch(bruh[event.matches.length - p]);
          }
          p++;
        }
      });
      setIsLoading(false);
    }
  };

  const handleSort = () => {
    setAscending(!ascending);
  };

  const handleOpModeSort = () => {
    setElementSort(null);
    setSortingModifier(sortingModifier === null ? OpModeType.AUTO : null);
    if (sortingModifier !== null) {
      Alert.alert(
        'Sort by',
        null,
        opModeExt.getAll().map((value) => ({
          text: opModeExt.toVal(value),
          onPress: () => {
            setElementSort(null);
            setSortingModifier(value);
            Alert.alert(
              'Sort by',
              null,
              Score('', Dice.none, event.gameName)
                .getScoreDivision(value)
                .getElements()
                .parse()
                .map((e) => ({
                  text: e?.name ?? 'Total',
                  onPress: () => {
                    setElementSort(e);
                  },
                }))
                .concat({
                  text: 'Cancel',
                  onPress: () => {},
                  style: 'cancel',
                })
            );
          },
        }))
        .concat({
          text: 'Cancel',
          onPress: () => {},
          style: 'cancel',
        })
      );
    }
  };

  const handleStatisticChange = (newValue: Statistics) => {
    setStatistics(newValue);
  };

  return (
    <View style={styles.container}>
      <View style={styles.appBar}>
        <Text style={styles.appBarTitle}>{tab === 0 ? '' : 'Matches'}</Text>
        <View style={styles.appBarActions}>
          {tab === 0 && (
            <TouchableOpacity
              style={styles.appBarButton}
              onPress={() => {
                Alert.alert(
                  'Configure',
                  null,
                  [
                    {
                      text: 'Cancel',
                      onPress: () => {},
                      style: 'cancel',
                    },
                    {
                      text: 'Configure',
                      onPress: () => {
                        Alert.alert(
                          'Configure',
                          null,
                          [
                            {
                              text: 'Cancel',
                              onPress: () => {},
                              style: 'cancel',
                            },
                            {
                              text: 'Save',
                              onPress: () => {
                                updateEvent(event);
                              },
                            },
                          ],
                          { cancelable: false }
                        );
                        navigation.navigate('CheckList', {
                          event: event,
                          statConfig: event.statConfig,
                        });
                      },
                    },
                  ]
                );
              }}
            >
              <Text style={styles.appBarIcon}>⚙️</Text>
            </TouchableOpacity>
          )}
          <TouchableOpacity style={styles.appBarButton} onPress={() => handleShare(event)}>
            <Text style={styles.appBarIcon}>{event.shared ? '📤' : '⬆️'}</Text>
          </TouchableOpacity>
          {tab !== 0 && event.hasKey() && (
            <TouchableOpacity
              style={styles.appBarButton}
              onPress={() => {
                navigation.navigate('ImageView', { event: event });
              }}
            >
              <Text style={styles.appBarIcon}>📷</Text>
            </TouchableOpacity>
          )}
          {tab !== 0 && event.hasKey() && (
            <TouchableOpacity style={styles.appBarButton} onPress={() => handleFetchScores()}>
              <Text style={styles.appBarIcon}>🔄</Text>
            </TouchableOpacity>
          )}
          {isLoading && (
            <View style={styles.appBarButton}>
              <ActivityIndicator size="small" color={theme.colors.primary} />
            </View>
          )}
          {tab === 0 && (
            <View style={styles.appBarButton}>
              <TouchableOpacity
                style={styles.appBarButton}
                onPress={() => {
                  Alert.alert(
                    'Statistic',
                    null,
                    Statistics.values.map((value) => ({
                      text: value.name,
                      onPress: () => {
                        handleStatisticChange(value);
                      },
                    }))
                    .concat({
                      text: 'Cancel',
                      onPress: () => {},
                      style: 'cancel',
                    })
                  );
                }}
              >
                <Text style={styles.appBarIcon}>📊</Text>
              </TouchableOpacity>
            </View>
          )}
          {tab !== 0 && (
            <TouchableOpacity style={styles.appBarButton} onPress={handleSort}>
              <Text style={styles.appBarIcon}>{ascending ? '⬆️' : '⬇️'}</Text>
            </TouchableOpacity>
          )}
          {tab === 0 && (
            <View style={styles.appBarButton}>
              <TouchableOpacity
                style={styles.appBarButton}
                onPress={() => {
                  Alert.alert(
                    'Sort by',
                    null,
                    opModeExt.getAll().map((value) => ({
                      text: opModeExt.toVal(value),
                      onPress: () => {
                        setElementSort(null);
                        setSortingModifier(value);
                        Alert.alert(
                          'Sort by',
                          null,
                          Score('', Dice.none, event.gameName)
                            .getScoreDivision(value)
                            .getElements()
                            .parse()
                            .map((e) => ({
                              text: e?.name ?? 'Total',
                              onPress: () => {
                                setElementSort(e);
                              },
                            }))
                            .concat({
                              text: 'Cancel',
                              onPress: () => {},
                              style: 'cancel',
                            })
                        );
                      },
                    }))
                    .concat({
                      text: 'Cancel',
                      onPress: () => {},
                      style: 'cancel',
                    })
                  );
                }}
              >
                <Text style={styles.appBarIcon}>🔼</Text>
              </TouchableOpacity>
            </View>
          )}
          <TouchableOpacity style={styles.appBarButton} onPress={handleSearch}>
            <Text style={styles.appBarIcon}>🔍</Text>
          </TouchableOpacity>
        </View>
      </View>
      <View style={styles.tabContent}>{materialTabs()[tab]}</View>
      {(event.type !== EventType.REMOTE && event.type !== EventType.ANALYSIS) && (
        <View style={styles.bottomNavigationBar}>
          <TouchableOpacity
            style={[styles.bottomNavigationBarButton, tab === 1 && styles.bottomNavigationBarButtonActive]}
            onPress={() => setTab(1)}
          >
            <Text style={styles.bottomNavigationBarButtonText}>Teams</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.bottomNavigationBarButton, tab === 0 && styles.bottomNavigationBarButtonActive]}
            onPress={() => setTab(0)}
          >
            <Text style={styles.bottomNavigationBarButtonText}>Matches</Text>
          </TouchableOpacity>
        </View>
      )}
      {event.role !== Role.VIEWER && (
        <TouchableOpacity
          style={[styles.floatingActionButton, tab === 0 && styles.floatingActionButtonTeam]}
          onPress={() => (tab === 0 ? handleTeamConfig() : handleMatchConfig())}
        >
          <Text style={styles.floatingActionButtonText}>+</Text>
        </TouchableOpacity>
      )}
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
    padding: 10,
    backgroundColor: '#3F51B5',
  },
  appBarTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: 'white',
  },
  appBarActions: {
    flexDirection: 'row',
  },
  appBarButton: {
    padding: 10,
    margin: 5,
  },
  appBarIcon: {
    fontSize: 24,
    color: 'white',
  },
  tabContent: {
    flex: 1,
  },
  tabContainer: {
    flex: 1,
    padding: 10,
  },
  floatingButton: {
    position: 'absolute',
    bottom: 20,
    right: 20,
    backgroundColor: '#3F51B5',
    padding: 15,
    borderRadius: 50,
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },
  bottomNavigationBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around',
    padding: 10,
    backgroundColor: 'white',
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
  },
  bottomNavigationBarButton: {
    padding: 10,
  },
  bottomNavigationBarButtonText: {
    fontSize: 16,
    color: '#3F51B5',
  },
  bottomNavigationBarButtonActive: {
    borderBottomWidth: 2,
    borderBottomColor: '#3F51B5',
  },
  floatingActionButton: {
    position: 'absolute',
    bottom: 20,
    right: 20,
    backgroundColor: '#3F51B5',
    padding: 15,
    borderRadius: 50,
  },
  floatingActionButtonTeam: {
    bottom: 80,
  },
  floatingActionButtonText: {
    color: 'white',
    fontSize: 24,
    fontWeight: 'bold',
  },
});

export default EventView;