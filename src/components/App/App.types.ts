import { EventType, Role } from '../../api/api.types';

export type AppNavigationProps = {
  navigation: {
    navigate: (screen: string) => void;
    goBack: () => void;
    push: (screen: string, params?: { [key: string]: any }) => void;
    replace: (screen: string, params?: { [key: string]: any }) => void;
  };
};

export type AppContextProps = {
  theme: {
    isDark: boolean;
    toggleTheme: () => void;
  };
  user: {
    isLoading: boolean;
    role: Role | null;
    email: string | null;
    displayName: string | null;
    photoURL: string | null;
    uid: string | null;
    signOut: () => void;
    signIn: () => Promise<void>;
    signInWithGoogle: () => Promise<void>;
    signInAnonymously: () => Promise<void>;
    signUp: ({
      email,
      password,
      displayName
    }: {
      email: string;
      password: string;
      displayName: string;
    }) => Promise<void>;
    sendPasswordResetEmail: (email: string) => Promise<void>;
  };
  event: {
    id: string;
    name: string;
    type: EventType;
    gameName: string;
    teams: { [key: string]: { name: string; number: string } };
    matches: { [key: string]: { red: { team1: string; team2: string }, blue: { team1: string; team2: string } } };
    shared: boolean;
    createEvent: (event: { name: string; type: EventType }) => Promise<void>;
    updateEvent: (event: { id: string; name: string; type: EventType }) => Promise<void>;
    deleteEvent: (id: string) => Promise<void>;
    createMatch: (match: { red: { team1: string; team2: string }, blue: { team1: string; team2: string } }) => Promise<void>;
    updateMatch: (match: { id: string; red: { team1: string; team2: string }, blue: { team1: string; team2: string } }) => Promise<void>;
    deleteMatch: (id: string) => Promise<void>;
    createTeam: (team: { name: string; number: string }) => Promise<void>;
    updateTeam: (team: { id: string; name: string; number: string }) => Promise<void>;
    deleteTeam: (id: string) => Promise<void>;
  };
  fcmToken: string | null;
};

export type AppProps = AppContextProps & AppNavigationProps;

export type AppState = {
  currentTab: Tab;
};

export enum Tab {
  EVENTS = 'Events',
  INBOX = 'Inbox',
  BLOCKED_USERS = 'Blocked Users',
  TEMPLATES = 'Templates',
}