import { StyleSheet } from 'react-native';
import { Colors } from '../../theme/theme';

export const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.primary,
  },
  contentContainer: {
    flex: 1,
    padding: 20,
    backgroundColor: Colors.secondary,
    borderRadius: 10,
    margin: 10,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 10,
    color: Colors.text,
  },
  subtitle: {
    fontSize: 18,
    marginBottom: 10,
    color: Colors.text,
  },
  matchInfoContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  matchInfo: {
    fontSize: 16,
    color: Colors.text,
  },
  teamContainer: {
    marginTop: 10,
  },
  teamTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 5,
    color: Colors.text,
  },
  teamInfo: {
    fontSize: 16,
    color: Colors.text,
  },
  scoresContainer: {
    marginTop: 10,
  },
  scoreTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 5,
    color: Colors.text,
  },
  scoreValue: {
    fontSize: 16,
    color: Colors.text,
  },
});