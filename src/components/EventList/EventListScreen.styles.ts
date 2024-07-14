import { StyleSheet } from 'react-native';
import { Colors, Fonts, Metrics } from '../../theme';

export default StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  titleContainer: {
    paddingHorizontal: Metrics.section,
    paddingTop: Metrics.baseMargin,
    paddingBottom: Metrics.doubleBaseMargin,
    backgroundColor: Colors.primary,
  },
  titleText: {
    fontSize: Fonts.size.h3,
    fontWeight: 'bold',
    color: Colors.white,
  },
  listContainer: {
    paddingHorizontal: Metrics.section,
  },
  listItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Metrics.baseMargin,
    borderBottomWidth: 1,
    borderBottomColor: Colors.borderColor,
  },
  listItemText: {
    fontSize: Fonts.size.regular,
    color: Colors.black,
  },
  listItemDate: {
    fontSize: Fonts.size.small,
    color: Colors.gray,
  },
  addButton: {
    backgroundColor: Colors.primary,
    paddingHorizontal: Metrics.doubleBaseMargin,
    paddingVertical: Metrics.baseMargin,
    borderRadius: Metrics.smallRadius,
    marginBottom: Metrics.baseMargin,
  },
  addButtonText: {
    color: Colors.white,
    fontSize: Fonts.size.regular,
  },
});