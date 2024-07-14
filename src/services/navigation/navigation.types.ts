import { StackNavigationProp } from '@react-navigation/stack';
import { BottomTabNavigationProp } from '@react-navigation/bottom-tabs';
import { RouteProp } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RootStackParamList } from '../../App.types';
import { AuthStackParamList } from '../../components/Auth/AuthStack.types';
import { HomeScreenParamList } from '../../components/Home/HomeScreen.types';
import { EventListScreenParamList } from '../../components/EventList/EventListScreen.types';
import { TeamListScreenParamList } from '../../components/TeamList/TeamListScreen.types';
import { MatchListScreenParamList } from '../../components/MatchList/MatchListScreen.types';
import { TeamDetailsScreenParamList } from '../../components/TeamDetails/TeamDetailsScreen.types';
import { EventDetailsScreenParamList } from '../../components/EventDetails/EventDetailsScreen.types';
import { MatchDetailsScreenParamList } from '../../components/MatchDetails/MatchDetailsScreen.types';
import { AddEventScreenParamList } from '../../components/AddEvent/AddEventScreen.types';

export type RootNavigationProps = {
  navigation: NativeStackNavigationProp<RootStackParamList>;
  route: RouteProp<RootStackParamList>;
};

export type AuthNavigationProps = {
  navigation: StackNavigationProp<AuthStackParamList>;
  route: RouteProp<AuthStackParamList>;
};

export type HomeNavigationProps = {
  navigation: BottomTabNavigationProp<HomeScreenParamList>;
  route: RouteProp<HomeScreenParamList>;
};

export type EventListNavigationProps = {
  navigation: StackNavigationProp<EventListScreenParamList>;
  route: RouteProp<EventListScreenParamList>;
};

export type TeamListNavigationProps = {
  navigation: StackNavigationProp<TeamListScreenParamList>;
  route: RouteProp<TeamListScreenParamList>;
};

export type MatchListNavigationProps = {
  navigation: StackNavigationProp<MatchListScreenParamList>;
  route: RouteProp<MatchListScreenParamList>;
};

export type TeamDetailsNavigationProps = {
  navigation: StackNavigationProp<TeamDetailsScreenParamList>;
  route: RouteProp<TeamDetailsScreenParamList>;
};

export type EventDetailsNavigationProps = {
  navigation: StackNavigationProp<EventDetailsScreenParamList>;
  route: RouteProp<EventDetailsScreenParamList>;
};

export type MatchDetailsNavigationProps = {
  navigation: StackNavigationProp<MatchDetailsScreenParamList>;
  route: RouteProp<MatchDetailsScreenParamList>;
};

export type AddEventNavigationProps = {
  navigation: StackNavigationProp<AddEventScreenParamList>;
  route: RouteProp<AddEventScreenParamList>;
};