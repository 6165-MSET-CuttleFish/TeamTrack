typescript
import React, { useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

const THEME_STATUS = 'THEMESTATUS';

export const useUserPreferences = () => {
  const [darkTheme, setDarkTheme] = useState(false);

  useEffect(() => {
    const getTheme = async () => {
      try {
        const theme = await AsyncStorage.getItem(THEME_STATUS);
        setDarkTheme(theme === 'true');
      } catch (error) {
        console.error('Error fetching theme:', error);
      }
    };

    getTheme();
  }, []);

  const setTheme = async (value: boolean) => {
    try {
      await AsyncStorage.setItem(THEME_STATUS, value.toString());
      setDarkTheme(value);
    } catch (error) {
      console.error('Error setting theme:', error);
    }
  };

  return { darkTheme, setTheme };
};