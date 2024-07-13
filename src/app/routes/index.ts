typescript
import { NavigationContainer, useNavigation } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import React from 'react';
import { View, StyleSheet } from 'react-native';

import LoginView from '../screens/auth/Login';
import SignUpView from '../screens/auth/SignUp';
import VerifyView from '../screens/auth/Verify';
import LandingPage from '../screens/LandingPage';
import EventsListView from '../screens/home/events/EventsList';
import EventView from '../screens/home/events/EventView';
import TeamView from '../screens/home/team/TeamView';
import MatchView from '../screens/home/match/MatchView';
import MatchConfig from '../screens/home/match/MatchConfig';
import TeamList from '../screens/home/team/TeamList';
import TeamAllianceRecommend from '../screens/home/team/TeamAllianceRecommend';
import AllianceSimulator from '../screens/home/team/AllianceSimulator';
import Inbox from '../screens/inbox/Inbox';
import BlockList from '../screens/inbox/BlockList';
import TemplatesListView from '../screens/templates/TemplatesList';
import TemplateView from '../screens/templates/TemplateView';
import CameraView from '../screens/home/events/CameraView';

const Stack = createNativeStackNavigator();

const Routes: React.FC = () => {
  return (
    <NavigationContainer>
      <Stack.Navigator
        initialRouteName="Login"
        screenOptions={{
          headerShown: false,
        }}
      >
        <Stack.Screen name="Login" component={LoginView} />
        <Stack.Screen name="SignUp" component={SignUpView} />
        <Stack.Screen name="Verify" component={VerifyView} />
        <Stack.Screen name="LandingPage" component={LandingPage} />
        <Stack.Screen name="EventsList" component={EventsListView} />
        <Stack.Screen name="EventView" component={EventView} />
        <Stack.Screen name="TeamView" component={TeamView} />
        <Stack.Screen name="MatchView" component={MatchView} />
        <Stack.Screen name="MatchConfig" component={MatchConfig} />
        <Stack.Screen name="TeamList" component={TeamList} />
        <Stack.Screen name="TeamAllianceRecommend" component={TeamAllianceRecommend} />
        <Stack.Screen name="AllianceSimulator" component={AllianceSimulator} />
        <Stack.Screen name="Inbox" component={Inbox} />
        <Stack.Screen name="BlockList" component={BlockList} />
        <Stack.Screen name="TemplatesList" component={TemplatesListView} />
        <Stack.Screen name="TemplateView" component={TemplateView} />
        <Stack.Screen name="CameraView" component={CameraView} />
      </Stack.Navigator>
    </NavigationContainer>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
});

export default Routes;