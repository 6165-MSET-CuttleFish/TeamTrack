typescript
import Toast from 'react-native-toast-message';

export default function useToast() {
  const showToast = (type: 'success' | 'error' | 'info' | 'warning', text1: string, text2?: string) => {
    Toast.show({
      type,
      text1,
      text2,
      bottomOffset: 20,
      autoHide: true,
      visibilityTime: 3000,
    });
  };

  return {
    showToast,
  };
}