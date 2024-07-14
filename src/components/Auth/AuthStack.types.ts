import { NavigationProps } from '../../services/navigation/navigation.types';
import { User } from '../../services/firebase/firebase.types';
import { Theme } from '../../theme/theme.types';
import { AuthStackProps } from './AuthStack.tsx';

export interface AuthStackNavigationProps extends NavigationProps {
  user: User | null;
  theme: Theme;
}

export type AuthStackState = {
  user: User | null;
  theme: Theme;
};

export type AuthStackContextProps = {
  state: AuthStackState;
  dispatch: React.Dispatch<AuthStackProps>;
};