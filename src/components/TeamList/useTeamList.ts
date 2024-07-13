typescript
import React, { useState, useEffect } from 'react';
import { View, FlatList, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { PlatformAlert, PlatformDialogAction, PlatformProgressIndicator, showPlatformDialog } from 'react-native-platform-dialog';
import { useAppModel, useEvent, useStatistics } from '../../hooks';
import { Event, Team, StatConfig, OpModeType, ScoringElement, Dice } from '../../models';
import { TeamRow } from './TeamRow';
import { ExampleTeamRow } from './ExampleTeamRow';
import { TeamView } from './TeamView';
import { EmptyList } from '../../components/misc/EmptyList';

interface TeamListProps {
  event: Event;
  sortMode: OpModeType | undefined;
  elementSort: ScoringElement | undefined;
  statConfig: StatConfig;
}

export const useTeamList = ({ event, sortMode, elementSort, statConfig }: TeamListProps) => {
  const [max, setMax] = useState<number>(0);
  const [teams, setTeams] = useState<Team[]>([]);
  const [isUserTeam, setIsUserTeam] = useState<boolean>(false);
  const navigation = useNavigation();
  const statistics = useStatistics();
  const appModel = useAppModel();

  useEffect(() => {
    const isUserTeam = event.teams.values.some(
      (team) => team.number === event.userTeam?.number
    );
    setIsUserTeam(isUserTeam);
  }, [event]);

  useEffect(() => {
    const updateMaxAndTeams = () => {
      let maxScore = 0;
      let sortedTeams: Team[] = [];
      if (statConfig.allianceTotal) {
        maxScore = event.teams.values
          .map((team) => {
            const spots = event.matches.values
              .toList()
              .filter((match) => match.teams.some((matchTeam) => matchTeam.number === team.number))
              .map((match) => match.spots(team, Dice.none, statConfig.showPenalties, type: sortMode))
              .filter((spots) => spots.length > 0)
              .flat()
              .filter((spot) => spot.y !== null)
              .removeOutliers(statConfig.removeOutliers)
              .map((spot) => spot.y)
              .getStatistic(statistics.getFunction());
            return spots;
          })
          .maxValue();
        sortedTeams = event.teams.values.sort((a, b) => {
          const aScore = event.matches.values
            .toList()
            .filter((match) => match.teams.some((matchTeam) => matchTeam.number === a.number))
            .map((match) => match.spots(a, Dice.none, statConfig.showPenalties, type: sortMode))
            .filter((spots) => spots.length > 0)
            .flat()
            .filter((spot) => spot.y !== null)
            .removeOutliers(statConfig.removeOutliers)
            .map((spot) => spot.y)
            .getStatistic(statistics.getFunction());
          const bScore = event.matches.values
            .toList()
            .filter((match) => match.teams.some((matchTeam) => matchTeam.number === b.number))
            .map((match) => match.spots(b, Dice.none, statConfig.showPenalties, type: sortMode))
            .filter((spots) => spots.length > 0)
            .flat()
            .filter((spot) => spot.y !== null)
            .removeOutliers(statConfig.removeOutliers)
            .map((spot) => spot.y)
            .getStatistic(statistics.getFunction());
          return bScore - aScore;
        });
      } else {
        maxScore = event.teams.maxCustomStatisticScore(
          Dice.none,
          statConfig.removeOutliers,
          statistics,
          sortMode,
          elementSort
        );
        sortedTeams = event.teams.sortedTeams(
          sortMode,
          elementSort,
          statConfig,
          event.matches.values.toList(),
          statistics
        );
      }
      setMax(maxScore);
      setTeams(sortedTeams);
    };
    updateMaxAndTeams();
  }, [event, statConfig, sortMode, elementSort, statistics]);

  const handleTeamPress = async (team: Team) => {
    await navigation.push('TeamView', { team, event });
  };

  const handleDeleteTeam = async (team: Team) => {
    showPlatformDialog({
      context: navigation.dangerouslyGetParent(),
      builder: (context) => (
        <PlatformAlert
          title={<Text>Delete Team</Text>}
          content={<Text>Are you sure?</Text>}
          actions={[
            <PlatformDialogAction
              isDefaultAction
              child={<Text>Cancel</Text>}
              onPressed={() => navigation.dangerouslyGetParent().pop()}
            />,
            <PlatformDialogAction
              isDestructive
              child={<Text>Confirm</Text>}
              onPressed={() => {
                const message = event.deleteTeam(team);
                appModel.saveEvents();
                navigation.dangerouslyGetParent().pop();
                if (message) {
                  showPlatformDialog({
                    context: navigation.dangerouslyGetParent(),
                    builder: (context) => (
                      <PlatformAlert
                        title={<Text>Error</Text>}
                        content={<Text>Team is present in matches</Text>}
                        actions={[
                          <PlatformDialogAction
                            isDefaultAction
                            child={<Text>Okay</Text>}
                            onPressed={() => navigation.dangerouslyGetParent().pop()}
                          />,
                        ]}
                      />
                    ),
                  });
                }
              }}
            />,
          ]}
        />
      ),
    });
  };

  return { max, teams, isUserTeam, handleTeamPress, handleDeleteTeam };
};

export const TeamList: React.FC<TeamListProps> = ({ event, sortMode, elementSort, statConfig }) => {
  const { max, teams, isUserTeam, handleTeamPress, handleDeleteTeam } = useTeamList({
    event,
    sortMode,
    elementSort,
    statConfig,
  });
  const navigation = useNavigation();

  return (
    <View style={styles.container}>
      {event.shared ? (
        <View style={styles.loadingContainer}>
          <PlatformProgressIndicator />
        </View>
      ) : teams.length === 0 ? (
        <EmptyList />
      ) : (
        <>
          <ExampleTeamRow
            sortMode={sortMode}
            elementSort={elementSort}
            statistics={useStatistics()}
          />
          <FlatList
            data={teams}
            keyExtractor={(team) => team.number.toString()}
            renderItem={({ item: team }) => (
              <TouchableOpacity onPress={() => handleTeamPress(team)} style={styles.teamRowContainer}>
                <TeamRow
                  team={team}
                  event={event}
                  sortMode={sortMode}
                  statConfig={statConfig}
                  elementSort={elementSort}
                  max={max}
                  statistics={useStatistics()}
                  onDelete={() => handleDeleteTeam(team)}
                />
              </TouchableOpacity>
            )}
          />
        </>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  teamRowContainer: {
    marginBottom: 16,
  },
});