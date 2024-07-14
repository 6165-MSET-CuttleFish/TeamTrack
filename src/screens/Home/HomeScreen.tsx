import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity } from 'react-native';
import { useGetEventList } from '../../hooks/useGetEventList';
import { useFirebaseAuth } from '../../hooks/useFirebaseAuth';
import { NavigationProp, useNavigation } from '@react-navigation/native';
import { RootStackParamList } from '../../navigation/RootNavigation.types';
import { Event } from '../../api/api.types';
import { Theme } from '../../theme/theme.types';
import { useTheme } from '../../theme/theme';
import { HomeScreenProps } from './HomeScreen.types';

const HomeScreen: React.FC<HomeScreenProps> = () => {
  const { user } = useFirebaseAuth();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const { theme } = useTheme();
  const { data: events, isLoading, error } = useGetEventList();

  useEffect(() => {
    if (error) {
      // Handle error state
    }
  }, [error]);

  const handleEventPress = (event: Event) => {
    navigation.navigate('EventDetails', { event });
  };

  const renderEventItem = ({ item }: { item: Event }) => (
    <TouchableOpacity onPress={() => handleEventPress(item)} style={styles.eventItem(theme)}>
      <Text style={styles.eventTitle(theme)}>{item.name}</Text>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container(theme)}>
      {isLoading ? (
        <Text>Loading events...</Text>
      ) : events?.length > 0 ? (
        <FlatList
          data={events}
          renderItem={renderEventItem}
          keyExtractor={(item) => item.id}
          style={styles.eventList(theme)}
        />
      ) : (
        <Text style={styles.noEventsText(theme)}>No events found.</Text>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: (theme: Theme) => ({
    flex: 1,
    backgroundColor: theme.colors.background,
    padding: 16,
  }),
  eventList: (theme: Theme) => ({
    marginTop: 16,
  }),
  eventItem: (theme: Theme) => ({
    padding: 16,
    marginBottom: 8,
    backgroundColor: theme.colors.cardBackground,
    borderRadius: 8,
  }),
  eventTitle: (theme: Theme) => ({
    fontSize: 18,
    fontWeight: 'bold',
    color: theme.colors.textPrimary,
  }),
  noEventsText: (theme: Theme) => ({
    fontSize: 16,
    color: theme.colors.textPrimary,
    textAlign: 'center',
    marginTop: 16,
  }),
});

export default HomeScreen;