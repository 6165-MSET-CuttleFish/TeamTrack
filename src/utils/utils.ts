import { Platform } from 'react-native';

export const isAndroid = Platform.OS === 'android';
export const isIOS = Platform.OS === 'ios';

export const getPlatformPageRoute = (builder: any) => ({
  // TODO: implement platform specific route
  // for now, just return the builder
  builder,
});

export const getDiceFromString = (statusAsString: string) => {
  // TODO: implement
  return null;
};

export const getRoleFromString = (role: string) => {
  switch (role) {
    case 'viewer':
      return 'viewer';
    case 'editor':
      return 'editor';
    case 'admin':
      return 'admin';
    default:
      return 'viewer';
  }
};