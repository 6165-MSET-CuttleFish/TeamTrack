import React, { useState, useEffect } from 'react';
import { NavigationContainer, useNavigation } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { SignInScreen } from '../../screens/Auth/SignInScreen/SignInScreen';
import { ForgotPasswordScreen } from '../../screens/Auth/ForgotPasswordScreen/ForgotPasswordScreen';
import { SignUpScreen } from '../../screens/Auth/SignUpScreen/SignUpScreen';
import { useFirebaseAuth } from '../../hooks/useFirebaseAuth';
import { AuthStackProps, AuthStackNavigationProps } from './AuthStack.types';

const Stack = createNativeStackNavigator();

export const AuthStack: React.FC<AuthStackProps> = ({ children }) => {
  const [isLoading, setIsLoading] = useState(true);
  const { user, isLoading: authLoading } = useFirebaseAuth();
  const navigation = useNavigation<AuthStackNavigationProps>();

  useEffect(() => {
    setIsLoading(authLoading);
  }, [authLoading]);

  useEffect(() => {
    if (user) {
      navigation.navigate('Home');
    }
  }, [user, navigation]);

  if (isLoading) {
    return null;
  }

  return (
    <NavigationContainer independent={true}>
      <Stack.Navigator
        screenOptions={{
          headerShown: false,
        }}
      >
        <Stack.Screen name="SignIn" component={SignInScreen} />
        <Stack.Screen name="SignUp" component={SignUpScreen} />
        <Stack.Screen name="ForgotPassword" component={ForgotPasswordScreen} />
        {children}
      </Stack.Navigator>
    </NavigationContainer>
  );
};