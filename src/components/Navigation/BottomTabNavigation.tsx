import React, { useState } from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import {
  HomeScreen,
  MatchListScreen,
  TeamListScreen,
} from '../../screens';
import { useFirebaseAuth } from '../../hooks';
import {
  BottomTabNavigationProps,
  BottomTabNavigationScreenProps,
} from './BottomTabNavigation.types';
import { BottomTabNavigationStyles } from './BottomTabNavigation.styles';
import {
  EventsTabIcon,
  MatchesTabIcon,
  TeamsTabIcon,
} from '../../components/Icons';

const Tab = createBottomTabNavigator();

const BottomTabNavigation: React.FC<BottomTabNavigationProps> = () => {
  const [showHome, setShowHome] = useState(true);
  const { isAuthenticated } = useFirebaseAuth();

  if (!isAuthenticated) {
    return null;
  }

  return (
    <Tab.Navigator
      initialRouteName={showHome ? 'Home' : 'Matches'}
      screenOptions={{
        headerShown: false,
        tabBarStyle: BottomTabNavigationStyles.tabBar,
        tabBarShowLabel: false,
      }}
    >
      {showHome && (
        <Tab.Screen
          name="Home"
          component={HomeScreen}
          options={{
            tabBarIcon: ({ focused }) => (
              <EventsTabIcon focused={focused} />
            ),
          }}
        />
      )}
      <Tab.Screen
        name="Matches"
        component={MatchListScreen}
        options={{
          tabBarIcon: ({ focused }) => (
            <MatchesTabIcon focused={focused} />
          ),
        }}
      />
      <Tab.Screen
        name="Teams"
        component={TeamListScreen}
        options={{
          tabBarIcon: ({ focused }) => (
            <TeamsTabIcon focused={focused} />
          ),
        }}
      />
    </Tab.Navigator>
  );
};

export default BottomTabNavigation;