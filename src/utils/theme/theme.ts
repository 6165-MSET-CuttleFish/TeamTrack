import { DefaultTheme, Theme } from '@react-navigation/native';
import { Platform, StatusBar } from 'react-native';

export const isIOS = Platform.OS === 'ios';

export const lightTheme: Theme = {
  ...DefaultTheme,
  dark: false,
  colors: {
    ...DefaultTheme.colors,
    primary: '#FFC107',
    background: '#FFFFFF',
    card: '#FFFFFF',
    text: '#000000',
    border: '#EEEEEE',
    notification: '#FF69B4',
  },
  statusBar: {
    backgroundColor: '#FFFFFF',
    barStyle: isIOS ? 'dark-content' : 'light-content',
  },
};

export const darkTheme: Theme = {
  ...DefaultTheme,
  dark: true,
  colors: {
    ...DefaultTheme.colors,
    primary: '#FFC107',
    background: '#212121',
    card: '#303030',
    text: '#FFFFFF',
    border: '#333333',
    notification: '#FF69B4',
  },
  statusBar: {
    backgroundColor: '#212121',
    barStyle: isIOS ? 'light-content' : 'light-content',
  },
};

export type ThemeType = {
  light: Theme;
  dark: Theme;
};

const useCustomTheme: ThemeType = {
  light: lightTheme,
  dark: darkTheme,
};

export default useCustomTheme;