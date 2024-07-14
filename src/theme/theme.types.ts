import { ColorSchemeName } from 'react-native';

export type ThemeType = {
  colors: {
    primary: string;
    secondary: string;
    background: string;
    text: string;
    surface: string;
    error: string;
    onPrimary: string;
    onSecondary: string;
    onBackground: string;
    onSurface: string;
    onError: string;
    [key: string]: string;
  };
  darkMode: boolean;
  colorScheme: ColorSchemeName;
};