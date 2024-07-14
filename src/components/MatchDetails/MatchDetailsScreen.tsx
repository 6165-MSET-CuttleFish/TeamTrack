import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useGetMatch } from '../../hooks/useGetMatch';
import { useUpdateMatch } from '../../hooks/useUpdateMatch';
import { useDeleteMatch } from '../../hooks/useDeleteMatch';
import { OpModeType } from '../../utils/constants';
import { ScoreSummary } from '../scores/ScoreSummary';
import { UsersRow } from '../users/UsersRow';
import { getAllianceColor } from '../../utils/theme';
import { Dice } from '../../utils/constants';
import { Score } from '../../utils/constants';
import { Incrementer } from '../scores/Incrementer';
import { BarGraph } from '../statistics/BarGraph';
import { useGetEvent } from '../../hooks/useGetEvent';

interface MatchDetailsScreenProps {
  matchId: string;
}

const MatchDetailsScreen: React.FC<MatchDetailsScreenProps> = ({ matchId }) => {
  const navigation = useNavigation();
  const [selectedTeam, setSelectedTeam] = useState<string | null>(null);
  const [selectedAlliance, setSelectedAlliance] = useState<string | null>(null);
  const [showPenalties, setShowPenalties] = useState(true);
  const [paused, setPaused] = useState(true);
  const [allowView, setAllowView] = useState(false);
  const [endgameStarted, setEndgameStarted] = useState(false);
  const [time, setTime] = useState(0);
  const [lapses, setLapses] = useState<number[]>([]);
  const [sum, setSum] = useState(0);
  const [view, setView] = useState<OpModeType>(OpModeType.auto);
  const [maxScoresInd, setMaxScoresInd] = useState<{ [key: string]: number }>({});
  const [maxScoresTarget, setMaxScoresTarget] = useState<{ [key: string]: number }>({});
  const [maxScoresTotal, setMaxScoresTotal] = useState<{ [key: string]: number }>({});
  const [previouslyCycledElement, setPreviouslyCycledElement] = useState<string | null>(null);

  const { data: matchData, isLoading: matchLoading, error: matchError } = useGetMatch(matchId);
  const { data: eventData, isLoading: eventLoading, error: eventError } = useGetEvent(matchData?.eventId);

  const { mutate: updateMatch, isLoading: updateMatchLoading, error: updateMatchError } = useUpdateMatch();
  const { mutate: deleteMatch, isLoading: deleteMatchLoading, error: deleteMatchError } = useDeleteMatch();

  useEffect(() => {
    const intervalId = setInterval(() => {
      if (!paused) {
        setTime((prevTime) => prevTime + 0.1);
        if (time > 90 && !endgameStarted) {
          setEndgameStarted(true);
        }
      }
    }, 100);

    return () => clearInterval(intervalId);
  }, [paused, time, endgameStarted]);

  useEffect(() => {
    if (matchData) {
      setSelectedAlliance(matchData.red.team1?.number ?? null);
      if (selectedTeam) {
        setSelectedAlliance(matchData.alliance(selectedTeam));
      }
    }
  }, [matchData, selectedTeam]);

  useEffect(() => {
    if (eventData) {
      const maxScoresInd = {};
      const maxScoresTarget = {};
      const maxScoresTotal = {};

      Object.values(OpModeType).forEach((type) => {
        maxScoresInd[type] = {};
        maxScoresTarget[type] = {};
        maxScoresTotal[type] = {};
      });

      Object.values(OpModeType).forEach((type) => {
        const elements = new Score('', Dice.none, eventData.gameName)
          .getScoreDivision(type)
          .getElements()
          .parse(false);

        elements.forEach((element) => {
          maxScoresInd[type][element.key] = eventData.teams
            .map((team) => team.scores.maxScore(Dice.none, false, type, element.key))
            .reduce((max, score) => (score > max ? score : max)) ?? 0;

          maxScoresTotal[type][element.key] = eventData.matches
            .map((match) => [match.red, match.blue])
            .reduce((acc, alliance) => acc.concat(alliance))
            .map((alliance) =>
              alliance
                ?.combinedScore()
                .getScoreDivision(type)
                .getScoringElementCount(element.key)
                ?.abs() ?? 0
            )
            .reduce((max, score) => (score > max ? score : max)) ?? 0;

          maxScoresTarget[type][element.key] = eventData.teams
            .map((team) =>
              team.targetScore
                ?.getScoreDivision(type)
                .getElements()
                .parse()
                .find((element) => element.key === element.key)?.scoreValue() ?? 0
            )
            .reduce((max, score) => (score > max ? score : max)) ?? 0;
        });
      });

      setMaxScoresInd(maxScoresInd);
      setMaxScoresTarget(maxScoresTarget);
      setMaxScoresTotal(maxScoresTotal);
    }
  }, [eventData]);

  const getAllianceColor = () => {
    if (matchData && matchData.type === 'local') {
      if (selectedAlliance === matchData.red.team1?.number) {
        return getAllianceColor('red');
      } else {
        return getAllianceColor('blue');
      }
    }
    return getAllianceColor('green');
  };

  const getPenaltyAlliance = () => {
    if (matchData.type === 'remote' || matchData.type === 'analysis') {
      return selectedAlliance;
    }
    if (selectedAlliance === matchData.red.team1?.number) {
      return matchData.blue.team1?.number;
    }
    if (selectedAlliance === matchData.blue.team1?.number) {
      return matchData.red.team1?.number;
    }
    return null;
  };

  const getDcName = (type: OpModeType) => {
    switch (type) {
      case OpModeType.auto:
        return 'autoDc';
      case OpModeType.tele:
        return 'teleDc';
      default:
        return 'endDc';
    }
  };

  const stateSetter = (key?: string) => {
    if (key && !eventData.shared) {
      setPreviouslyCycledElement(key);
    }
  };

  const mutableIncrement = (mutableData: { [key: string]: any }, element: any) => {
    if (mutableData[element.key] && mutableData[element.key]['count'] < element.max()) {
      const newLapse = (time - sum).toFixed(3);
      setLapses([...lapses, parseFloat(newLapse)]);
      setSum(time);
      if (!paused && previouslyCycledElement === element.key) {
        mutableData[element.key]['cycleTimes'] = [...(mutableData[element.key]['cycleTimes'] || []), newLapse];
      }
      setPreviouslyCycledElement(element.key);
    }
  };

  const onIncrement = (element: any) => {
    const newLapse = (time - sum).toFixed(3);
    setLapses([...lapses, parseFloat(newLapse)]);
    setSum(time);
    if (!paused && previouslyCycledElement === element.key) {
      element.cycleTimes.push(newLapse);
    }
    setPreviouslyCycledElement(element.key);
  };

  const allianceColor = () => {
    if (selectedAlliance === matchData?.blue?.team1?.number) {
      return 'blue';
    } else {
      return 'red';
    }
  };

  const teamPath = (opModeType: OpModeType) => {
    if (selectedTeam) {
      return `teams/${selectedTeam}/scores/${matchData?.id}/${opModeType.toRep()}`;
    }
    return `teams/${selectedTeam}/targetScore/${opModeType.toRep()}`;
  };

  const matchPath = (opModeType: OpModeType) => {
    return `matches/${matchData?.id}/${allianceColor()}/sharedScore/${OpModeType.endgame.toRep()}`;
  };

  const buttonRow = () => {
    const teams = matchData?.getTeams().toList() || [];
    return (
      <View style={styles.buttonRow}>
        {teams.map((team) => (
          <TouchableOpacity
            key={team.number}
            style={[
              styles.teamButton,
              {
                backgroundColor:
                  selectedTeam === team.number
                    ? 'grey'
                    : matchData?.alliance(team.number) === matchData.red.team1?.number
                    ? getAllianceColor('red')
                    : getAllianceColor('blue'),
              },
            ]}
            onPress={() => {
              setSelectedTeam(team.number);
              setSelectedAlliance(matchData?.alliance(team.number));
            }}
          >
            <Text
              style={[
                styles.teamButtonText,
                {
                  color: selectedTeam === team.number ? 'white' : 'white',
                },
              ]}
            >
              {team.number}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
    );
  };

  const viewSelect = (type: OpModeType) => {
    return (
      <ScrollView style={styles.scrollView}>
        {!paused || allowView || type === OpModeType.auto ? (
          <View>
            {matchData && matchData.type !== 'remote' && matchData.type !== 'analysis' && (
              <TouchableOpacity
                style={[
                  styles.disconnectedButton,
                  {
                    backgroundColor:
                      (matchData.getScoreDivision(type).robotDisconnected ?? false)
                        ? getAllianceColor('yellow')
                        : 'transparent',
                  },
                ]}
                onPress={() => {
                  updateMatch({
                    ...matchData,
                    [getDcName(type)]: !(matchData.getScoreDivision(type).robotDisconnected ?? false),
                  });
                }}
              >
                <BarGraph
                  title="Contribution"
                  vertical={false}
                  height={15}
                  width={300}
                  val={matchData.getScoreDivision(type).total(false)?.toDouble() || 0.0}
                  max={
                    matchData.alliance(selectedTeam)
                      ?.combinedScore()
                      .getScoreDivision(type)
                      .total(false)
                      ?.toDouble() || 0.0
                  }
                />
              </TouchableOpacity>
            )}
            <Incrementer
              getTime={() => time}
              element={new Score('', Dice.none, eventData.gameName).teleScore.getElements()[0]}
              onPressed={() => {
                updateMatch({
                  ...matchData,
                  teams: matchData.teams.map((team) => {
                    if (team.number === selectedTeam) {
                      return {
                        ...team,
                        scores: {
                          ...team.scores,
                          [matchData.id]: {
                            ...team.scores[matchData.id],
                            teleScore: {
                              ...team.scores[matchData.id]?.teleScore,
                              elements: team.scores[matchData.id]?.teleScore.getElements().map(
                                (element) => ({
                                  ...element,
                                  incrementValue: 1,
                                })
                              ),
                            },
                          },
                        },
                      };
                    }
                    return team;
                  }),
                });
              }}
              backgroundColor={'grey'}
            />
            {(matchData.getScoreDivision(type).robotDisconnected ?? false) && (
              <View style={styles.disconnectedText}>
                <Text style={styles.disconnectedText}>Robot Disconnected</Text>
              </View>
            )}
            {!(matchData.getScoreDivision(type).robotDisconnected ?? false) && (
              <View>
                {matchData.getScoreDivision(type).getElements().parse().map((e) => (
                  <Incrementer
                    key={e.key}
                    getTime={() => time}
                    element={e}
                    onPressed={() => {
                      stateSetter(e.key);
                      updateMatch({
                        ...matchData,
                        teams: matchData.teams.map((team) => {
                          if (team.number === selectedTeam) {
                            return {
                              ...team,
                              scores: {
                                ...team.scores,
                                [matchData.id]: {
                                  ...team.scores[matchData.id],
                                  [type.toRep()]: {
                                    ...team.scores[matchData.id]?.[type.toRep()],
                                    elements: team.scores[matchData.id]?.[type.toRep()].getElements().map(
                                      (element) => ({
                                        ...element,
                                        incrementValue: element.key === e.key ? element.incrementValue + 1 : element.incrementValue,
                                      })
                                    ),
                                  },
                                },
                              },
                            };
                          }
                          return team;
                        }),
                      });
                    }}
                    event={eventData}
                    path={teamPath(type)}
                    max={matchData ? (maxScoresInd[type][e.key] || 0) : (maxScoresTarget[type][e.key] || 0)}
                  />
                ))}
                {matchData && (
                  <View>
                    {matchData.alliance(selectedTeam).sharedScore.getScoreDivision(type).getElements().parse().map((e) => (
                      <Incrementer
                        key={e.key}
                        getTime={() => time}
                        element={e}
                        onPressed={() => {
                          stateSetter(e.key);
                          updateMatch({
                            ...matchData,
                            [allianceColor()]: {
                              ...matchData[allianceColor()],
                              sharedScore: {
                                ...matchData[allianceColor()].sharedScore,
                                [type.toRep()]: {
                                  ...matchData[allianceColor()].sharedScore[type.toRep()],
                                  elements: matchData[allianceColor()].sharedScore[type.toRep()].getElements().map(
                                    (element) => ({
                                      ...element,
                                      incrementValue: element.key === e.key ? element.incrementValue + 1 : element.incrementValue,
                                    })
                                  ),
                                },
                              },
                            },
                          });
                        }}
                        event={eventData}
                        path={matchPath(type)}
                        backgroundColor={getAllianceColor(allianceColor())}
                      />
                    ))}
                  </View>
                )}
              </View>
            )}
          </View>
        ) : (
          <View>
            <Text>Begin {type === OpModeType.tele ? 'Tele-Op' : 'End Game'} Phase</Text>
            <TouchableOpacity onPress={() => {
              setPaused(false);
              setAllowView(true);
            }}>
              <Text>Driver Control Play</Text>
            </TouchableOpacity>
            <Text>View {type === OpModeType.tele ? 'Tele-Op' : 'End Game'} Controls</Text>
            <TouchableOpacity onPress={() => {
              setAllowView(true);
            }}>
              <Text>View</Text>
            </TouchableOpacity>
          </View>
        )}
      </ScrollView>
    );
  };

  const getMaxScoreInd = () => {
    const maxScore = {};
    Object.values(OpModeType).forEach((type) => {
      maxScore[type] = maxScoresInd[type][null] || 0;
    });
    return maxScore;
  };

  const getMaxScoreTotal = () => {
    const maxScore = {};
    Object.values(OpModeType).forEach((type) => {
      maxScore[type] = maxScoresTotal[type][null] || 0;
    });
    return maxScore;
  };

  const getMaxScoreTarget = () => {
    const maxScore = {};
    Object.values(OpModeType).forEach((type) => {
      maxScore[type] = maxScoresTarget[type][null] || 0;
    });
    return maxScore;
  };

  return (
    <View style={styles.container}>
      <View style={[styles.header, { backgroundColor: getAllianceColor() }]}>
        <Text style={styles.headerText}>Match Details</Text>
        {matchData && matchData.activeUsers?.length > 0 ? (
          <TouchableOpacity onPress={() => navigation.navigate('Users', { matchId })}>
            <UsersRow users={matchData.activeUsers} showRole={false} size={20} />
          </TouchableOpacity>
        ) : null}
      </View>
      {matchData && matchData.type !== 'remote' && matchData.type !== 'analysis' && (
        <View style={styles.matchInfo}>
          {buttonRow()}
          <View style={styles.matchScore}>
            <Text style={styles.matchScoreText}>{matchData.redScore(true)}</Text>
            <Text style={styles.matchScoreText}> - </Text>
            <Text style={styles.matchScoreText}>{matchData.blueScore(true)}</Text>
          </View>
        </View>
      )}
      <ScrollView style={styles.content}>
        <View style={styles.matchSummary}>
          <Text style={styles.teamName}>
            {selectedTeam ? `${selectedTeam} : ${matchData?.teams[selectedTeam]?.name || ''}` : ''}
          </Text>
          {matchData && matchData.type !== 'remote' && matchData.type !== 'analysis' && (
            <TouchableOpacity onPress={() => setShowPenalties((prev) => !prev)}>
              <Text>Show Penalties: {showPenalties ? 'True' : 'False'}</Text>
            </TouchableOpacity>
          )}
          <View style={styles.scoreSummary}>
            <ScoreSummary
              event={eventData}
              score={
                matchData?.type === 'remote' || matchData?.type === 'analysis'
                  ? matchData.alliance(selectedTeam)?.combinedScore()
                  : matchData?.teams[selectedTeam]?.scores[matchData.id]
              }
              maxes={
                matchData?.type === 'remote' || matchData?.type === 'analysis'
                  ? getMaxScoreTotal()
                  : getMaxScoreInd()
              }
              showPenalties={showPenalties}
            />
          </View>
        </View>
        {getPenaltyAlliance() && matchData && (
          <View style={styles.penaltySection}>
            <Text style={styles.penaltySectionTitle}>Penalties</Text>
            {matchData.teams[selectedTeam]?.scores[matchData.id]?.penalties.getElements().map((e) => (
              <Incrementer
                key={e.key}
                getTime={() => time}
                element={e}
                onPressed={() => {
                  stateSetter(e.key);
                  updateMatch({
                    ...matchData,
                    teams: matchData.teams.map((team) => {
                      if (team.number === selectedTeam) {
                        return {
                          ...team,
                          scores: {
                            ...team.scores,
                            [matchData.id]: {
                              ...team.scores[matchData.id],
                              penalties: {
                                ...team.scores[matchData.id].penalties,
                                elements: team.scores[matchData.id].penalties.getElements().map(
                                  (element) => ({
                                    ...element,
                                    incrementValue: element.key === e.key ? element.incrementValue + 1 : element.incrementValue,
                                  })
                                ),
                              },
                            },
                          },
                        };
                      }
                      return team;
                    }),
                  });
                }}
                event={eventData}
                path={teamPath(OpModeType.penalty)}
                backgroundColor={'transparent'}
              />
            ))}
          </View>
        )}
        <View style={styles.opModeSelector}>
          <TouchableOpacity onPress={() => setView(OpModeType.auto)}>
            <Text style={styles.opModeSelectorText}>Autonomous</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => setView(OpModeType.tele)}>
            <Text style={styles.opModeSelectorText}>Tele-Op</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => setView(OpModeType.endgame)}>
            <Text style={styles.opModeSelectorText}>Endgame</Text>
          </TouchableOpacity>
        </View>
        <View style={styles.opModeContent}>
          {viewSelect(view)}
        </View>
      </ScrollView>
      {matchData && matchData.type !== 'remote' && matchData.type !== 'analysis' && (
        <View style={styles.footer}>
          <TouchableOpacity onPress={() => setPaused((prev) => !prev)}>
            <Text style={styles.footerText}>{paused ? 'Play' : 'Pause'}</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => {
            setTime(0);
            setLapses([]);
            setSum(0);
            setPaused(true);
          }}>
            <Text style={styles.footerText}>Stop</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => {
            updateMatch({
              ...matchData,
              teams: matchData.teams.map((team) => {
                if (team.number === selectedTeam) {
                  return {
                    ...team,
                    scores: {
                      ...team.scores,
                      [matchData.id]: {
                        ...team.scores[matchData.id],
                        autoScore: {
                          ...team.scores[matchData.id].autoScore,
                          elements: team.scores[matchData.id].autoScore.getElements().map((element) => ({
                            ...element,
                            incrementValue: 0,
                          })),
                        },
                        teleScore: {
                          ...team.scores[matchData.id].teleScore,
                          elements: team.scores[matchData.id].teleScore.getElements().map((element) => ({
                            ...element,
                            incrementValue: 0,
                          })),
                        },
                        endScore: {
                          ...team.scores[matchData.id].endScore,
                          elements: team.scores[matchData.id].endScore.getElements().map((element) => ({
                            ...element,
                            incrementValue: 0,
                          })),
                        },
                        penalties: {
                          ...team.scores[matchData.id].penalties,
                          elements: team.scores[matchData.id].penalties.getElements().map((element) => ({
                            ...element,
                            incrementValue: 0,
                          })),
                        },
                      },
                    };
                  }
                  return team;
                });
              },
            });
          }}>
            <Text style={styles.footerText}>Reset</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => {
            deleteMatch(matchId);
            navigation.goBack();
          }}>
            <Text style={styles.footerText}>Delete</Text>
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    height: 50,
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerText: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  matchInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 10,
  },
  buttonRow: {
    flexDirection: 'row',
  },
  teamButton: {
    padding: 10,
    margin: 5,
    borderRadius: 5,
  },
  teamButtonText: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  matchScore: {
    flexDirection: 'row',
  },
  matchScoreText: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  content: {
    padding: 10,
  },
  matchSummary: {
    marginBottom: 20,
  },
  teamName: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  scoreSummary: {
    marginBottom: 20,
  },
  penaltySection: {
    marginBottom: 20,
  },
  penaltySectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  opModeSelector: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 20,
  },
  opModeSelectorText: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  opModeContent: {
    marginBottom: 20,
  },
  disconnectedButton: {
    padding: 10,
    marginBottom: 10,
    borderRadius: 5,
  },
  disconnectedText: {
    fontSize: 16,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 10,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: 10,
    backgroundColor: 'lightgrey',
  },
  footerText: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  scrollView: {
    flex: 1,
  },
});

export default MatchDetailsScreen;