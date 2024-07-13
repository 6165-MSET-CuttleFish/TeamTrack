typescript
import React, { createContext, useContext, useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

const ThemeContext = createContext({
  darkTheme: false,
  toggleTheme: () => {},
});

export const useTheme = () => useContext(ThemeContext);

export const ThemeProvider = ({ children }) => {
  const [darkTheme, setDarkTheme] = useState(false);

  useEffect(() => {
    const loadTheme = async () => {
      try {
        const theme = await AsyncStorage.getItem('THEME_STATUS');
        setDarkTheme(theme === 'true');
      } catch (error) {
        console.error('Error loading theme:', error);
      }
    };

    loadTheme();
  }, []);

  const toggleTheme = async () => {
    const newTheme = !darkTheme;
    setDarkTheme(newTheme);
    try {
      await AsyncStorage.setItem('THEME_STATUS', newTheme.toString());
    } catch (error) {
      console.error('Error saving theme:', error);
    }
  };

  return (
    <ThemeContext.Provider value={{ darkTheme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
};