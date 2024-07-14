import { StyleSheet } from 'react-native';
import { Theme } from '../../theme/theme.types';

export const getSignInScreenStyles = (theme: Theme) =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.colors.background,
      padding: 20,
    },
    header: {
      marginBottom: 20,
    },
    headerText: {
      fontSize: 24,
      fontWeight: 'bold',
      color: theme.colors.text,
      textAlign: 'center',
    },
    formContainer: {
      marginBottom: 20,
    },
    input: {
      borderWidth: 1,
      borderColor: theme.colors.border,
      borderRadius: 5,
      padding: 10,
      marginBottom: 10,
    },
    button: {
      backgroundColor: theme.colors.primary,
      padding: 10,
      borderRadius: 5,
      alignItems: 'center',
    },
    buttonText: {
      color: theme.colors.white,
      fontSize: 16,
      fontWeight: 'bold',
    },
    forgotPasswordText: {
      textAlign: 'center',
      marginTop: 10,
    },
    signUpText: {
      textAlign: 'center',
      marginTop: 20,
    },
    signUpLink: {
      color: theme.colors.primary,
    },
    errorText: {
      color: theme.colors.error,
      textAlign: 'center',
      marginBottom: 10,
    },
  });