import { StyleSheet } from 'react-native';
import { COLORS } from '../../utils/theme/theme';

export const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.white,
  },
  header: {
    padding: 16,
    backgroundColor: COLORS.primary,
    flexDirection: 'row',
    alignItems: 'center',
  },
  teamName: {
    fontSize: 24,
    fontWeight: 'bold',
    color: COLORS.white,
  },
  teamNumber: {
    fontSize: 16,
    color: COLORS.white,
  },
  contentContainer: {
    padding: 16,
  },
  scoreCardContainer: {
    marginTop: 16,
  },
  scoreCardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  scoreCardValue: {
    fontSize: 16,
  },
  autonContainer: {
    marginTop: 16,
  },
  autonTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  autonDrawing: {
    height: 200,
  },
  matchListContainer: {
    marginTop: 16,
  },
  matchListTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  matchListItem: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.lightGray,
  },
  matchListItemText: {
    fontSize: 16,
  },
  targetScoreContainer: {
    marginTop: 16,
  },
  targetScoreTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  targetScoreValue: {
    fontSize: 16,
  },
  changeListContainer: {
    marginTop: 16,
  },
  changeListTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  changeListItem: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.lightGray,
  },
  changeListItemText: {
    fontSize: 16,
  },
});