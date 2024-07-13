typescript
import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Image } from 'react-native';
import { useNavigation } from '@react-navigation/native';

import { Team } from '../../models/Team';
import { Event } from '../../models/Event';
import { Statistics } from '../../functions/Statistics';
import { OpModeType } from '../../models/OpModeType';
import { ScoringElement } from '../../models/ScoringElement';
import { StatConfig } from '../../models/StatConfig';
import { getPercentIncrease } from '../../functions/Extensions';
import { BarGraph } from '../statistics/BarGraph';
import { PercentChange } from '../statistics/PercentChange';

interface TeamCardProps {
  team: Team;
  event: Event;
  max: number;
  sortMode?: OpModeType;
  elementSort?: ScoringElement;
  statistics: Statistics;
  statConfig: StatConfig;
  onTap?: () => void;
}

const TeamCard: React.FC<TeamCardProps> = ({
  team,
  event,
  max,
  sortMode,
  elementSort,
  statistics,
  statConfig,
  onTap,
}) => {
  const navigation = useNavigation();

  const [percentIncrease, setPercentIncrease] = useState<number | null>(null);
  const [wlt, setWlt] = useState<string[]>([]);

  useEffect(() => {
    const calculatePercentIncrease = () => {
      if (statConfig.allianceTotal) {
        const scores = event.getMatches(team)
          .map((e) => e.alliance(team)?.combinedScore())
          .filter((score): score is Score => typeof score !== 'undefined') as Score[];
        setPercentIncrease(getPercentIncrease(scores, elementSort));
      } else {
        const scores = Object.values(team.scores)
          .map((e) => e.getScoreDivision(sortMode));
        setPercentIncrease(getPercentIncrease(scores, elementSort));
      }
    };

    const calculateWlt = () => {
      setWlt((team.getWLT(event) ?? '').split('-'));
    };

    calculatePercentIncrease();
    calculateWlt();
  }, []);

  const wltColor = (i: number) => {
    if (i === 0) {
      return 'green';
    } else if (i === 1) {
      return 'red';
    } else {
      return 'grey';
    }
  };

  return (
    <TouchableOpacity onPress={onTap} style={styles.container}>
      <View style={styles.row}>
        <View style={styles.teamInfo}>
          <Text style={styles.teamName}>{team.name}</Text>
          <View style={styles.wltContainer}>
            {wlt.map((value, index) => (
              <Text key={index} style={{ color: wltColor(index) }}>
                {value}
                {index < wlt.length - 1 && '-'}
              </Text>
            ))}
          </View>
        </View>
        <View style={styles.teamNumber}>
          <Text style={styles.teamNumberText}>{team.number}</Text>
        </View>
        <View style={styles.trailing}>
          {percentIncrease !== null && percentIncrease.isFinite && (
            <PercentChange percentIncrease={percentIncrease} lessIsBetter={sortMode?.getLessIsBetter()} />
          )}
          <BarGraph
            height={60}
            width={15}
            vertical={false}
            val={
              statConfig.allianceTotal
                ? event.matches.values
                    .toList()
                    .spots(
                      team,
                      'none',
                      statConfig.showPenalties,
                      type: sortMode,
                      element: elementSort
                    )
                    .removeOutliers(statConfig.removeOutliers)
                    .map((spot) => spot.y)
                    .getStatistic(statistics.getFunction())
                : team.scores.customStatisticScore(
                    'none',
                    statConfig.removeOutliers,
                    statistics,
                    sortMode,
                    elementSort
                  )
            }
            max={max}
            title=""
            compressed={true}
            lessIsBetter={
              (statistics.getLessIsBetter() || sortMode?.getLessIsBetter()) &&
              !(statistics.getLessIsBetter() && sortMode?.getLessIsBetter())
            }
          />
          <TouchableOpacity
            onPress={() =>
              navigation.navigate('TeamDetails', {
                team: team,
                event: event,
              })
            }
          >
            <Image
              source={require('../../assets/icons/navigate-next.png')}
              style={styles.navigateIcon}
            />
          </TouchableOpacity>
        </View>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    borderWidth: 1,
    borderColor: 'grey',
    padding: 10,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  teamInfo: {
    flex: 1,
  },
  teamName: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  wltContainer: {
    flexDirection: 'row',
    marginTop: 5,
  },
  teamNumber: {
    width: 60,
    alignItems: 'center',
  },
  teamNumberText: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  trailing: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  navigateIcon: {
    width: 20,
    height: 20,
  },
});

export default TeamCard;