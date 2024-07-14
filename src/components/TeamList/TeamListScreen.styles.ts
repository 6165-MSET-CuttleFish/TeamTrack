import { StyleSheet } from 'react-native';
import { Theme } from '../../theme/theme.types';

export const styles = (theme: Theme) =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.colors.background,
    },
    list: {
      paddingHorizontal: theme.spacing.medium,
    },
    search: {
      paddingHorizontal: theme.spacing.medium,
      marginBottom: theme.spacing.medium,
    },
    teamRow: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      paddingVertical: theme.spacing.medium,
      paddingHorizontal: theme.spacing.medium,
      borderBottomWidth: 1,
      borderBottomColor: theme.colors.border,
    },
    teamNumber: {
      fontSize: theme.fontSizes.medium,
      fontWeight: 'bold',
    },
    teamName: {
      fontSize: theme.fontSizes.medium,
    },
    statistic: {
      fontSize: theme.fontSizes.medium,
      fontWeight: 'bold',
    },
  });