import { StyleSheet } from 'react-native';
import { Colors, Fonts, Sizes } from '../../theme';

export const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.white,
  },
  header: {
    padding: Sizes.padding.medium,
    backgroundColor: Colors.primary,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerTitle: {
    color: Colors.white,
    fontSize: Fonts.size.large,
    fontFamily: Fonts.type.regular,
  },
  matchInfoContainer: {
    padding: Sizes.padding.medium,
    backgroundColor: Colors.white,
  },
  matchInfoTitle: {
    fontSize: Fonts.size.medium,
    fontFamily: Fonts.type.bold,
    marginBottom: Sizes.margin.small,
  },
  matchInfoValue: {
    fontSize: Fonts.size.medium,
    fontFamily: Fonts.type.regular,
  },
  buttonContainer: {
    padding: Sizes.padding.medium,
    backgroundColor: Colors.white,
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  button: {
    backgroundColor: Colors.primary,
    padding: Sizes.padding.small,
    borderRadius: Sizes.radius.medium,
  },
  buttonText: {
    color: Colors.white,
    fontSize: Fonts.size.medium,
    fontFamily: Fonts.type.regular,
  },
});