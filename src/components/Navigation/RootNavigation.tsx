import React from 'react';
import { NavigationContainer, StackRouter, useNavigation } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { RootNavigationProps, RootNavigationParamList } from './RootNavigation.types';
import { BottomTabNavigation } from '../Navigation/BottomTabNavigation';
import { AuthStack } from '../Auth/AuthStack';

const Stack = createNativeStackNavigator<RootNavigationParamList>();

export const RootNavigation: React.FC<RootNavigationProps> = () => {
  const navigation = useNavigation();
  
  return (
    <NavigationContainer
      ref={navigation}
      independent={true}
      router={StackRouter}
    >
      <Stack.Navigator
        initialRouteName="AuthStack"
        screenOptions={{
          headerShown: false,
        }}
      >
        <Stack.Screen
          name="AuthStack"
          component={AuthStack}
        />
        <Stack.Screen
          name="BottomTabNavigation"
          component={BottomTabNavigation}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
};