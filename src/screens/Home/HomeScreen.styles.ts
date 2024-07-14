import { StyleSheet } from 'react-native';
import { Theme } from '../../theme/theme';

export const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Theme.colors.primary,
  },
  contentContainer: {
    backgroundColor: Theme.colors.background,
    padding: 16,
    borderRadius: 12,
    marginTop: 20,
    marginHorizontal: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: Theme.colors.text,
    marginBottom: 16,
  },
  addEventButton: {
    backgroundColor: Theme.colors.primary,
    padding: 12,
    borderRadius: 8,
    marginTop: 16,
  },
  addEventButtonText: {
    color: Theme.colors.text,
    fontSize: 16,
    fontWeight: 'bold',
  },
  eventList: {
    marginTop: 16,
  },
});