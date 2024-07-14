import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useGetTeam } from '../../hooks/useGetTeam';
import { useGetMatchList } from '../../hooks/useGetMatchList';
import { Team } from '../../models/Team';
import { Match } from '../../models/Match';
import { useGetEvent } from '../../hooks/useGetEvent';
import { Event } from '../../models/Event';
import { useGetEventList } from '../../hooks/useGetEventList';
import { useGetTeamList } from '../../hooks/useGetTeamList';
import { OpModeType } from '../../models/OpModeType';
import { ScoringElement } from '../../models/ScoringElement';
import { Dice } from '../../models/Dice';

const TeamDetailsScreen: React.FC<{ teamNumber: string }> = ({ teamNumber }) => {
  const navigation = useNavigation();
  const { data: team, isLoading: teamLoading } = useGetTeam(teamNumber);
  const { data: matches, isLoading: matchLoading } = useGetMatchList(teamNumber);
  const { data: event, isLoading: eventLoading } = useGetEvent(teamNumber);
  const { data: events, isLoading: eventsLoading } = useGetEventList();
  const { data: teams, isLoading: teamsLoading } = useGetTeamList();

  const [selectedEvent, setSelectedEvent] = useState<Event | null>(null);
  const [selectedOpMode, setSelectedOpMode] = useState<OpModeType>(OpModeType.auto);
  const [selectedElement, setSelectedElement] = useState<ScoringElement | null>(null);
  const [selectedDice, setSelectedDice] = useState<Dice>(Dice.none);

  useEffect(() => {
    if (events && events.length > 0) {
      setSelectedEvent(events[0]);
    }
  }, [events]);

  const handleOpModeChange = (opMode: OpModeType) => {
    setSelectedOpMode(opMode);
  };

  const handleElementChange = (element: ScoringElement) => {
    setSelectedElement(element);
  };

  const handleDiceChange = (dice: Dice) => {
    setSelectedDice(dice);
  };

  const renderMatchItem = ({ item }: { item: Match }) => {
    return (
      <TouchableOpacity
        style={styles.matchItem}
        onPress={() => navigation.navigate('MatchDetails', { matchId: item.id })}
      >
        <Text style={styles.matchNumber}>Match {item.matchNumber}</Text>
        <Text style={styles.matchScore}>
          {item.score?.getScoreDivision(selectedOpMode)?.total()}
        </Text>
      </TouchableOpacity>
    );
  };

  const renderEventItem = ({ item }: { item: Event }) => {
    return (
      <TouchableOpacity
        style={styles.eventItem}
        onPress={() => setSelectedEvent(item)}
      >
        <Text style={styles.eventName}>{item.name}</Text>
      </TouchableOpacity>
    );
  };

  const renderElementItem = ({ item }: { item: ScoringElement }) => {
    return (
      <TouchableOpacity
        style={styles.elementItem}
        onPress={() => setSelectedElement(item)}
      >
        <Text style={styles.elementName}>{item.name}</Text>
      </TouchableOpacity>
    );
  };

  const renderDiceItem = ({ item }: { item: Dice }) => {
    return (
      <TouchableOpacity
        style={styles.diceItem}
        onPress={() => setSelectedDice(item)}
      >
        <Text style={styles.diceName}>{item.toVal(event?.gameName)}</Text>
      </TouchableOpacity>
    );
  };

  if (teamLoading || matchLoading || eventLoading || eventsLoading || teamsLoading) {
    return (
      <View style={styles.container}>
        <Text>Loading...</Text>
      </View>
    );
  }

  if (!team) {
    return (
      <View style={styles.container}>
        <Text>Team not found</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.teamInfo}>
        <Text style={styles.teamName}>{team.name}</Text>
        <Text style={styles.teamNumber}>Team {team.number}</Text>
      </View>

      <View style={styles.eventSelector}>
        <Text style={styles.eventSelectorTitle}>Event:</Text>
        <FlatList
          data={events}
          horizontal
          renderItem={renderEventItem}
          keyExtractor={(item) => item.id}
        />
      </View>

      {selectedEvent && (
        <>
          <View style={styles.opModeSelector}>
            <Text style={styles.opModeSelectorTitle}>Op Mode:</Text>
            <View style={styles.opModeButtons}>
              {Object.values(OpModeType).map((opMode) => (
                <TouchableOpacity
                  key={opMode}
                  style={styles.opModeButton}
                  onPress={() => handleOpModeChange(opMode)}
                >
                  <Text
                    style={[
                      styles.opModeButtonText,
                      selectedOpMode === opMode && styles.selectedOpModeButtonText,
                    ]}
                  >
                    {opMode.getName()}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          <View style={styles.elementSelector}>
            <Text style={styles.elementSelectorTitle}>Element:</Text>
            <FlatList
              data={selectedEvent.game?.scoringElements}
              horizontal
              renderItem={renderElementItem}
              keyExtractor={(item) => item.key}
            />
          </View>

          <View style={styles.diceSelector}>
            <Text style={styles.diceSelectorTitle}>Dice:</Text>
            <FlatList
              data={Object.values(Dice)}
              horizontal
              renderItem={renderDiceItem}
              keyExtractor={(item) => item.toString()}
            />
          </View>

          <View style={styles.matchList}>
            <Text style={styles.matchListTitle}>Matches:</Text>
            <FlatList
              data={matches?.filter(
                (match) =>
                  match.eventId === selectedEvent.id &&
                  match.score?.getScoreDivision(selectedOpMode)?.total() !== null,
              )}
              renderItem={renderMatchItem}
              keyExtractor={(item) => item.id}
            />
          </View>
        </>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    padding: 20,
  },
  teamInfo: {
    alignItems: 'center',
    marginBottom: 20,
  },
  teamName: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  teamNumber: {
    fontSize: 18,
  },
  eventSelector: {
    marginBottom: 20,
  },
  eventSelectorTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  eventItem: {
    padding: 10,
    marginRight: 10,
    backgroundColor: '#eee',
    borderRadius: 5,
  },
  eventName: {
    fontSize: 16,
  },
  opModeSelector: {
    marginBottom: 20,
  },
  opModeSelectorTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  opModeButtons: {
    flexDirection: 'row',
  },
  opModeButton: {
    padding: 10,
    marginRight: 10,
    backgroundColor: '#eee',
    borderRadius: 5,
  },
  opModeButtonText: {
    fontSize: 16,
  },
  selectedOpModeButtonText: {
    fontWeight: 'bold',
  },
  elementSelector: {
    marginBottom: 20,
  },
  elementSelectorTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  elementItem: {
    padding: 10,
    marginRight: 10,
    backgroundColor: '#eee',
    borderRadius: 5,
  },
  elementName: {
    fontSize: 16,
  },
  diceSelector: {
    marginBottom: 20,
  },
  diceSelectorTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  diceItem: {
    padding: 10,
    marginRight: 10,
    backgroundColor: '#eee',
    borderRadius: 5,
  },
  diceName: {
    fontSize: 16,
  },
  matchList: {
    marginBottom: 20,
  },
  matchListTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  matchItem: {
    padding: 10,
    marginBottom: 10,
    backgroundColor: '#eee',
    borderRadius: 5,
  },
  matchNumber: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  matchScore: {
    fontSize: 16,
  },
});

export default TeamDetailsScreen;