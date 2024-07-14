import { StyleSheet } from 'react-native';
import { theme } from '../../theme/theme';

export const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: theme.colors.text,
    marginTop: 30,
    marginBottom: 20,
    textAlign: 'center',
  },
  eventsList: {
    flex: 1,
    padding: 20,
  },
  addEventButton: {
    backgroundColor: theme.colors.primary,
    padding: 15,
    borderRadius: 10,
    position: 'absolute',
    bottom: 20,
    right: 20,
  },
  addEventButtonText: {
    color: theme.colors.white,
    fontSize: 16,
    fontWeight: 'bold',
  },
});