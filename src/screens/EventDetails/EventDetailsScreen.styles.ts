import { StyleSheet } from 'react-native';
import { Colors, Fonts, Metrics } from '../../theme';

export default StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: Metrics.baseMargin,
    backgroundColor: Colors.primary,
  },
  title: {
    fontSize: Fonts.size.h3,
    fontWeight: 'bold',
    color: Colors.white,
  },
  backIcon: {
    marginLeft: Metrics.baseMargin,
  },
  eventDetails: {
    padding: Metrics.baseMargin,
    flex: 1,
  },
  sectionTitle: {
    fontSize: Fonts.size.h4,
    fontWeight: 'bold',
    marginBottom: Metrics.smallMargin,
  },
  sectionValue: {
    fontSize: Fonts.size.h5,
    marginBottom: Metrics.baseMargin,
  },
  buttonContainer: {
    padding: Metrics.baseMargin,
  },
  button: {
    backgroundColor: Colors.primary,
    padding: Metrics.baseMargin,
    borderRadius: Metrics.borderRadius,
  },
  buttonText: {
    color: Colors.white,
    fontSize: Fonts.size.h5,
    fontWeight: 'bold',
  },
});