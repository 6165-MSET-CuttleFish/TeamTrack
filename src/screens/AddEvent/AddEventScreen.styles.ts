import { StyleSheet } from 'react-native';
import { Colors, Fonts, Metrics } from '../../theme';

export default StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.white,
    paddingHorizontal: Metrics.baseMargin,
  },
  title: {
    fontSize: Fonts.size.h3,
    fontWeight: 'bold',
    color: Colors.black,
    marginBottom: Metrics.baseMargin,
  },
  form: {
    marginBottom: Metrics.baseMargin,
  },
  input: {
    borderWidth: 1,
    borderColor: Colors.lightGray,
    borderRadius: Metrics.smallRadius,
    padding: Metrics.baseMargin,
    marginBottom: Metrics.baseMargin,
  },
  button: {
    backgroundColor: Colors.primary,
    padding: Metrics.baseMargin,
    borderRadius: Metrics.smallRadius,
    alignItems: 'center',
    justifyContent: 'center',
  },
  buttonText: {
    color: Colors.white,
    fontSize: Fonts.size.medium,
    fontWeight: 'bold',
  },
  date: {
    borderWidth: 1,
    borderColor: Colors.lightGray,
    borderRadius: Metrics.smallRadius,
    padding: Metrics.baseMargin,
    marginBottom: Metrics.baseMargin,
  },
});