import { StyleSheet } from 'react-native';
import { theme } from '../../../theme/theme';

export const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
    color: theme.colors.text,
  },
  inputContainer: {
    marginBottom: 15,
  },
  input: {
    height: 40,
    borderColor: theme.colors.border,
    borderWidth: 1,
    padding: 10,
    borderRadius: 5,
    color: theme.colors.text,
  },
  button: {
    backgroundColor: theme.colors.primary,
    padding: 15,
    borderRadius: 5,
    alignItems: 'center',
    marginTop: 20,
  },
  buttonText: {
    color: theme.colors.white,
    fontWeight: 'bold',
  },
  privacyPolicyText: {
    fontSize: 14,
    color: theme.colors.text,
    marginBottom: 15,
  },
  privacyPolicyButton: {
    color: theme.colors.primary,
  },
  errorText: {
    color: theme.colors.error,
    marginBottom: 10,
  },
});