import { NavigationActions } from './navigation.types';
import { useNavigation } from '@react-navigation/native';

export const navigationService = {
  navigate: (routeName: NavigationActions['navigate']['params']['routeName'], params?: NavigationActions['navigate']['params']['params']) => {
    const navigation = useNavigation();
    navigation.navigate(routeName, params);
  },
  goBack: () => {
    const navigation = useNavigation();
    navigation.goBack();
  },
};