import { StackNavigationProp, BottomTabNavigationProp } from '@react-navigation/native-stack';
import { BottomTabNavigationOptions } from '@react-navigation/bottom-tabs';
import { RouteProp } from '@react-navigation/native';
import { HomeScreenParams } from '../../screens/Home/HomeScreen.types';
import { EventListScreenParams } from '../../screens/EventList/EventListScreen.types';
import { TeamListScreenParams } from '../../screens/TeamList/TeamListScreen.types';
import { MatchListScreenParams } from '../../screens/MatchList/MatchListScreen.types';

export type RootStackParams = {
  AuthStack: undefined;
  HomeStack: { screen: 'Home'; params: HomeScreenParams };
  EventListStack: { screen: 'EventList'; params: EventListScreenParams };
  TeamListStack: { screen: 'TeamList'; params: TeamListScreenParams };
  MatchListStack: { screen: 'MatchList'; params: MatchListScreenParams };
};

export type RootStackNavigationProp = StackNavigationProp<RootStackParams>;

export type RootStackRouteProp<T extends keyof RootStackParams> = RouteProp<
  RootStackParams,
  T
>;

export type BottomTabNavigationParams = {
  Home: undefined;
  EventList: undefined;
  TeamList: undefined;
  MatchList: undefined;
};

export type BottomTabNavigationProp = BottomTabNavigationProp<
  BottomTabNavigationParams
>;

export type BottomTabNavigationRouteProp<T extends keyof BottomTabNavigationParams> =
  RouteProp<BottomTabNavigationParams, T>;

export type BottomTabNavigationOptions = BottomTabNavigationOptions;