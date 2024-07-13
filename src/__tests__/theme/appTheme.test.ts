typescript
import { DarkThemeProvider } from '../src/providers/Theme';
import { DarkThemePreference } from '../src/providers/Theme';
import AsyncStorage from '@react-native-async-storage/async-storage';

jest.mock('@react-native-async-storage/async-storage');

describe('DarkThemeProvider', () => {
  let provider: DarkThemeProvider;

  beforeEach(() => {
    provider = new DarkThemeProvider();
  });

  it('should initialize with darkTheme set to false', () => {
    expect(provider.darkTheme).toBe(false);
  });

  it('should update darkTheme and notify listeners', () => {
    const listener = jest.fn();
    provider.addListener(listener);

    provider.darkTheme = true;

    expect(provider.darkTheme).toBe(true);
    expect(listener).toHaveBeenCalled();
  });
});

describe('DarkThemePreference', () => {
  let preference: DarkThemePreference;

  beforeEach(() => {
    preference = new DarkThemePreference();
  });

  it('should set darkTheme in AsyncStorage', async () => {
    await preference.setDarkTheme(true);

    expect(AsyncStorage.setItem).toHaveBeenCalledWith(
      DarkThemePreference.THEME_STATUS,
      'true'
    );
  });

  it('should get darkTheme from AsyncStorage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue('true');

    const theme = await preference.getTheme();

    expect(theme).toBe(true);
  });

  it('should return false if no theme is found in AsyncStorage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const theme = await preference.getTheme();

    expect(theme).toBe(false);
  });
});