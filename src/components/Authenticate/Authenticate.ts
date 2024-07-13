typescript
import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TextInput, Button } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import auth from '@react-native-firebase/auth';
import { GoogleSignin } from '@react-native-google-signin/google-signin';
import { Platform } from 'react-native';

const Authenticate = () => {
  const navigation = useNavigation();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const signInWithEmailAndPassword = async () => {
    setLoading(true);
    setError('');
    try {
      await auth().signInWithEmailAndPassword(email, password);
      navigation.navigate('Home');
    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  const signUpWithEmailAndPassword = async () => {
    setLoading(true);
    setError('');
    try {
      await auth().createUserWithEmailAndPassword(email, password);
      await auth().currentUser?.updateProfile({ displayName });
      navigation.navigate('Home');
    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  const signInWithGoogle = async () => {
    setLoading(true);
    setError('');
    try {
      await GoogleSignin.configure({
        webClientId: 'YOUR_WEB_CLIENT_ID', // Replace with your web client ID
      });
      const { idToken } = await GoogleSignin.signIn();
      const googleCredential = auth.GoogleAuthProvider.credential(idToken);
      await auth().signInWithCredential(googleCredential);
      navigation.navigate('Home');
    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  const signInAnonymously = async () => {
    setLoading(true);
    setError('');
    try {
      await auth().signInAnonymously();
      navigation.navigate('Home');
    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = async () => {
    setLoading(true);
    setError('');
    try {
      await auth().sendPasswordResetEmail(email);
      setError('Password reset email sent.');
    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSignOut = async () => {
    setLoading(true);
    setError('');
    try {
      await auth().signOut();
      navigation.navigate('Auth'); // Navigate back to authentication screen
    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const unsubscribe = auth().onAuthStateChanged((user) => {
      if (user) {
        navigation.navigate('Home');
      }
    });
    return unsubscribe;
  }, []);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Authenticate</Text>
      {error && <Text style={styles.error}>{error}</Text>}
      <TextInput
        style={styles.input}
        placeholder="Email"
        value={email}
        onChangeText={setEmail}
      />
      <TextInput
        style={styles.input}
        placeholder="Password"
        value={password}
        onChangeText={setPassword}
        secureTextEntry={true}
      />
      {Platform.OS === 'android' && (
        <Button title="Sign In" onPress={signInWithEmailAndPassword} disabled={loading} />
      )}
      {Platform.OS === 'ios' && (
        <Button title="Sign In" color="blue" onPress={signInWithEmailAndPassword} disabled={loading} />
      )}
      {Platform.OS === 'android' && (
        <Button title="Sign Up" onPress={signUpWithEmailAndPassword} disabled={loading} />
      )}
      {Platform.OS === 'ios' && (
        <Button title="Sign Up" color="blue" onPress={signUpWithEmailAndPassword} disabled={loading} />
      )}
      <Button title="Forgot Password" onPress={handleForgotPassword} disabled={loading} />
      <Button title="Sign In with Google" onPress={signInWithGoogle} disabled={loading} />
      <Button title="Sign In Anonymously" onPress={signInAnonymously} disabled={loading} />
      {auth().currentUser && (
        <Button title="Sign Out" onPress={handleSignOut} disabled={loading} />
      )}
      {loading && <Text style={styles.loading}>Loading...</Text>}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    padding: 10,
    marginBottom: 10,
  },
  error: {
    color: 'red',
    marginBottom: 10,
  },
  loading: {
    marginTop: 20,
  },
});

export default Authenticate;