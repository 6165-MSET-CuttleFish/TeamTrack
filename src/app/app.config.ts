typescript
import { useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

const THEME_STATUS = 'THEMESTATUS';

export const useDarkTheme = () => {
  const [darkTheme, setDarkTheme] = useState(false);

  useEffect(() => {
    const loadTheme = async () => {
      try {
        const themeStatus = await AsyncStorage.getItem(THEME_STATUS);
        setDarkTheme(themeStatus === 'true');
      } catch (e) {
        console.error('Error loading theme:', e);
      }
    };

    loadTheme();
  }, []);

  const toggleDarkTheme = async () => {
    try {
      const newTheme = !darkTheme;
      await AsyncStorage.setItem(THEME_STATUS, newTheme.toString());
      setDarkTheme(newTheme);
    } catch (e) {
      console.error('Error saving theme:', e);
    }
  };

  return { darkTheme, toggleDarkTheme };
};