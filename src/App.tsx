import React, { useState, useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { ThemeProvider } from 'styled-components/native';

import { AuthStack } from 'components/Auth';
import { BottomTabNavigation } from 'components/Navigation';
import { RootNavigation } from 'components/Navigation';
import { useFirebaseAuth } from 'hooks/useFirebaseAuth';
import { theme } from 'theme/theme';

const Stack = createNativeStackNavigator();

const App: React.FC = () => {
  const [isAppInitialized, setIsAppInitialized] = useState(false);
  const { user, isLoading } = useFirebaseAuth();

  useEffect(() => {
    // Handle Firebase initialization and user state changes here
    // For example:
    // setIsAppInitialized(true);
    // ...
  }, []);

  if (isLoading) {
    return null;
  }

  if (!isAppInitialized) {
    return null;
  }

  return (
    <ThemeProvider theme={theme}>
      <NavigationContainer>
        {user ? (
          <Stack.Navigator
            screenOptions={{
              headerShown: false,
            }}
          >
            <Stack.Screen name="RootNavigation" component={RootNavigation} />
            <Stack.Screen
              name="BottomTabNavigation"
              component={BottomTabNavigation}
            />
          </Stack.Navigator>
        ) : (
          <AuthStack />
        )}
      </NavigationContainer>
    </ThemeProvider>
  );
};

export default App;