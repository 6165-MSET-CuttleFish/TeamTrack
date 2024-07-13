typescript
import { Platform } from 'react-native';

export const appTheme = {
  light: {
    primary: '#504099',
    secondary: '#974EBF',
    background: '#F5F5F5',
    text: '#000000',
    shadowColor: '#000000',
    splashColor: Platform.OS === 'android' ? '#00BCD4' : 'transparent',
    canvasColor: '#FFFFFF',
  },
  dark: {
    primary: '#19A7CE',
    secondary: '#673AB7',
    background: '#121212',
    text: '#FFFFFF',
    shadowColor: '#FFFFFF',
    splashColor: Platform.OS === 'android' ? '#673AB7' : 'transparent',
    canvasColor: '#000000',
  },
};