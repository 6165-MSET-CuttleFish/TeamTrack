import { NavigationProps } from './navigation.types';
import { AuthStackProps } from '../Auth/AuthStack.types';
import { BottomTabNavigationProps } from './BottomTabNavigation.types';

export type RootNavigationProps = NavigationProps & {
  authStack: AuthStackProps;
  bottomTabNavigation: BottomTabNavigationProps;
};