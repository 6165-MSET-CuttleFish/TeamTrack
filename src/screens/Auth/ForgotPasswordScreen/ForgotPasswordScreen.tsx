import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useForgotPassword } from '../../hooks/useForgotPassword';
import { COLORS, SIZES } from '../../theme/theme';

const ForgotPasswordScreen: React.FC = () => {
  const navigation = useNavigation();
  const [email, setEmail] = useState('');
  const { forgotPassword, isLoading, error } = useForgotPassword();

  const handleForgotPassword = async () => {
    await forgotPassword(email);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Forgot Password</Text>

      <Text style={styles.label}>Email</Text>
      <TextInput
        style={styles.input}
        value={email}
        onChangeText={setEmail}
        keyboardType="email-address"
        placeholder="Enter your email"
      />

      {error && <Text style={styles.error}>{error}</Text>}

      <TouchableOpacity
        style={[styles.button, isLoading && { opacity: 0.5 }]}
        disabled={isLoading}
        onPress={handleForgotPassword}
      >
        <Text style={styles.buttonText}>Send Reset Link</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={styles.link}
        onPress={() => navigation.navigate('SignIn')}
      >
        <Text style={styles.linkText}>Back to Sign In</Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: SIZES.padding,
    backgroundColor: COLORS.white,
  },
  title: {
    fontSize: SIZES.h2,
    fontWeight: 'bold',
    marginBottom: SIZES.padding,
  },
  label: {
    fontSize: SIZES.h4,
    marginBottom: SIZES.base,
  },
  input: {
    borderWidth: 1,
    borderColor: COLORS.gray,
    padding: SIZES.base,
    borderRadius: SIZES.radius,
    marginBottom: SIZES.padding,
  },
  error: {
    color: COLORS.red,
    marginBottom: SIZES.base,
  },
  button: {
    backgroundColor: COLORS.primary,
    padding: SIZES.padding,
    borderRadius: SIZES.radius,
  },
  buttonText: {
    color: COLORS.white,
    fontSize: SIZES.h4,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  link: {
    marginTop: SIZES.padding,
  },
  linkText: {
    color: COLORS.primary,
    textAlign: 'center',
  },
});

export default ForgotPasswordScreen;