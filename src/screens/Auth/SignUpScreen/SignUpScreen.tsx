import React, { useState } from 'react';
import { View, Text, TextInput, Button, Alert } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useCreateTeam, useFirebaseAuth } from '../../../hooks';
import { SignUpScreenStyles } from './SignUpScreen.styles';
import { useForm } from 'react-hook-form';

const SignUpScreen: React.FC = () => {
  const { register, handleSubmit, formState: { errors } } = useForm();
  const [isLoading, setIsLoading] = useState(false);
  const navigation = useNavigation();
  const { signUp } = useFirebaseAuth();
  const { createTeam } = useCreateTeam();

  const onSubmit = async (data: any) => {
    setIsLoading(true);
    try {
      await signUp(data.email, data.password);
      await createTeam({
        name: data.displayName,
        owner: data.email,
      });
      navigation.navigate('Home');
    } catch (error) {
      Alert.alert('Error', (error as Error).message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <View style={SignUpScreenStyles.container}>
      <Text style={SignUpScreenStyles.title}>Sign Up</Text>
      <View style={SignUpScreenStyles.form}>
        <TextInput
          style={SignUpScreenStyles.input}
          placeholder="Name"
          {...register('displayName', { required: true })}
          error={!!errors.displayName}
        />
        {errors.displayName && (
          <Text style={SignUpScreenStyles.error}>
            This field is required
          </Text>
        )}
        <TextInput
          style={SignUpScreenStyles.input}
          placeholder="Email"
          keyboardType="email-address"
          {...register('email', { required: true })}
          error={!!errors.email}
        />
        {errors.email && (
          <Text style={SignUpScreenStyles.error}>This field is required</Text>
        )}
        <TextInput
          style={SignUpScreenStyles.input}
          placeholder="Password"
          secureTextEntry
          {...register('password', { required: true })}
          error={!!errors.password}
        />
        {errors.password && (
          <Text style={SignUpScreenStyles.error}>
            This field is required
          </Text>
        )}
        <TextInput
          style={SignUpScreenStyles.input}
          placeholder="Confirm Password"
          secureTextEntry
          {...register('passwordConfirm', {
            required: true,
            validate: (value) =>
              value === data.password || 'Passwords do not match',
          })}
          error={!!errors.passwordConfirm}
        />
        {errors.passwordConfirm && (
          <Text style={SignUpScreenStyles.error}>
            {errors.passwordConfirm.message}
          </Text>
        )}
        <Button title="Sign Up" onPress={handleSubmit(onSubmit)} disabled={isLoading} />
      </View>
    </View>
  );
};

export default SignUpScreen;