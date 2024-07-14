import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';

import { Match } from '../../api/api.types';
import { useGetMatch } from '../../hooks/useGetMatch';
import { Event } from '../../api/api.types';
import { useGetEvent } from '../../hooks/useGetEvent';
import { useDeleteMatch } from '../../hooks/useDeleteMatch';

import { Header } from '../../components/Header/Header';
import { MatchDetailsItem } from '../../components/MatchDetailsItem/MatchDetailsItem';
import { MatchDetailsSection } from '../../components/MatchDetailsSection/MatchDetailsSection';

import { Colors } from '../../theme/theme.types';
import { useFirebaseAuth } from '../../hooks/useFirebaseAuth';

interface MatchDetailsScreenProps {
  matchId: string;
}

const MatchDetailsScreen: React.FC<MatchDetailsScreenProps> = ({
  matchId,
}) => {
  const navigation = useNavigation();
  const { user } = useFirebaseAuth();

  const [event, setEvent] = useState<Event | null>(null);
  const { data: match, isLoading: isMatchLoading, error: matchError } =
    useGetMatch(matchId);

  const { data: eventData, isLoading: isEventLoading, error: eventError } =
    useGetEvent(match?.eventId ?? '');

  const { mutate: deleteMatch, isLoading: isDeletingMatch } = useDeleteMatch();

  useEffect(() => {
    if (eventData) {
      setEvent(eventData);
    }
  }, [eventData]);

  const handleDeleteMatch = async () => {
    if (match) {
      await deleteMatch(match.id);
      navigation.goBack();
    }
  };

  if (isMatchLoading || isEventLoading) {
    return (
      <View style={styles.container}>
        <Text>Loading...</Text>
      </View>
    );
  }

  if (matchError || eventError) {
    return (
      <View style={styles.container}>
        <Text>Error: {matchError?.message || eventError?.message}</Text>
      </View>
    );
  }

  if (!match || !event) {
    return null;
  }

  return (
    <View style={styles.container}>
      <Header title="Match Details" />
      <ScrollView style={styles.scroll}>
        <MatchDetailsSection
          title="Match Information"
          style={styles.section}
        >
          <MatchDetailsItem
            title="Match ID"
            value={match.id}
          />
          <MatchDetailsItem
            title="Event"
            value={event.name}
            onPress={() =>
              navigation.navigate('EventDetails', {
                eventId: event.id,
              })
            }
          />
          <MatchDetailsItem
            title="Red Alliance"
            value={`${match.red.team1.number} - ${match.red.team1.name}`}
            onPress={() =>
              navigation.navigate('TeamDetails', {
                teamId: match.red.team1.id,
              })
            }
          />
          <MatchDetailsItem
            title=""
            value={`${match.red.team2.number} - ${match.red.team2.name}`}
            onPress={() =>
              navigation.navigate('TeamDetails', {
                teamId: match.red.team2.id,
              })
            }
          />
          <MatchDetailsItem
            title="Blue Alliance"
            value={`${match.blue.team1.number} - ${match.blue.team1.name}`}
            onPress={() =>
              navigation.navigate('TeamDetails', {
                teamId: match.blue.team1.id,
              })
            }
          />
          <MatchDetailsItem
            title=""
            value={`${match.blue.team2.number} - ${match.blue.team2.name}`}
            onPress={() =>
              navigation.navigate('TeamDetails', {
                teamId: match.blue.team2.id,
              })
            }
          />
        </MatchDetailsSection>
        {match.type !== 'remote' && (
          <MatchDetailsSection
            title="Scores"
            style={styles.section}
          >
            <MatchDetailsItem
              title="Red Score"
              value={match.redScore.toString()}
            />
            <MatchDetailsItem
              title="Blue Score"
              value={match.blueScore.toString()}
            />
          </MatchDetailsSection>
        )}
        {match.type === 'remote' && (
          <MatchDetailsSection
            title="Scores"
            style={styles.section}
          >
            <MatchDetailsItem
              title="Red Autonomous Score"
              value={match.red.autoScore.toString()}
            />
            <MatchDetailsItem
              title="Red Teleop Score"
              value={match.red.teleopScore.toString()}
            />
            <MatchDetailsItem
              title="Red Endgame Score"
              value={match.red.endgameScore.toString()}
            />
            <MatchDetailsItem
              title="Red Penalty Score"
              value={match.red.penaltyScore.toString()}
            />
            <MatchDetailsItem
              title="Blue Autonomous Score"
              value={match.blue.autoScore.toString()}
            />
            <MatchDetailsItem
              title="Blue Teleop Score"
              value={match.blue.teleopScore.toString()}
            />
            <MatchDetailsItem
              title="Blue Endgame Score"
              value={match.blue.endgameScore.toString()}
            />
            <MatchDetailsItem
              title="Blue Penalty Score"
              value={match.blue.penaltyScore.toString()}
            />
          </MatchDetailsSection>
        )}
        <MatchDetailsSection
          title="Actions"
          style={styles.section}
        >
          <TouchableOpacity
            style={styles.button}
            onPress={() => navigation.navigate('EditMatch', { matchId })}
          >
            <Text style={styles.buttonText}>Edit</Text>
          </TouchableOpacity>
          {user && (
            <TouchableOpacity
              style={styles.button}
              onPress={handleDeleteMatch}
            >
              <Text style={styles.buttonText}>Delete</Text>
            </TouchableOpacity>
          )}
        </MatchDetailsSection>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  scroll: {
    padding: 20,
  },
  section: {
    marginBottom: 20,
  },
  button: {
    backgroundColor: Colors.primary,
    padding: 15,
    borderRadius: 10,
    marginBottom: 10,
  },
  buttonText: {
    color: Colors.white,
    textAlign: 'center',
    fontSize: 16,
  },
});

export default MatchDetailsScreen;