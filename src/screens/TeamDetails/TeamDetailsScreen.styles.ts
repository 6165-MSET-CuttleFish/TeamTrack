import { StyleSheet } from 'react-native';
import { COLORS } from '../../utils/theme/theme';

export const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.white,
  },
  headerContainer: {
    padding: 20,
    backgroundColor: COLORS.primary,
    borderBottomLeftRadius: 20,
    borderBottomRightRadius: 20,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: COLORS.white,
  },
  teamNumber: {
    fontSize: 16,
    color: COLORS.white,
  },
  teamName: {
    fontSize: 18,
    color: COLORS.white,
  },
  contentContainer: {
    padding: 20,
  },
  matchListTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  matchListItem: {
    padding: 15,
    marginBottom: 10,
    backgroundColor: COLORS.lightGray,
    borderRadius: 10,
  },
  matchListItemText: {
    fontSize: 16,
  },
  matchListButton: {
    backgroundColor: COLORS.primary,
    padding: 10,
    borderRadius: 5,
  },
  matchListButtonText: {
    color: COLORS.white,
    fontSize: 16,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    fontSize: 18,
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorText: {
    fontSize: 18,
    color: COLORS.error,
  },
});