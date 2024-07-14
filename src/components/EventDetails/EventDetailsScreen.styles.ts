import { StyleSheet } from 'react-native';
import { Colors } from '../../theme/theme';

export const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.white,
  },
  contentContainer: {
    flex: 1,
    padding: 20,
  },
  eventName: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  eventDescription: {
    fontSize: 16,
    marginBottom: 20,
  },
  eventDetailsSection: {
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  sectionValue: {
    fontSize: 16,
  },
  matchListContainer: {
    marginTop: 20,
  },
  matchListTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
});