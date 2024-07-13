typescript
export enum AuthState {
  SignedOut = 'SignedOut',
  SignedIn = 'SignedIn',
  EmailNotVerified = 'EmailNotVerified',
}

export enum AuthProvider {
  EmailPassword = 'EmailPassword',
  Google = 'Google',
  Anonymous = 'Anonymous',
}

export interface AuthUser {
  uid: string;
  email: string;
  displayName: string;
  photoURL: string | null;
  emailVerified: boolean;
  isAnonymous: boolean;
  FCMtokens: string[];
}

export interface LoginError {
  code: string;
  message: string;
}

export interface AuthContextProps {
  authState: AuthState;
  user: AuthUser | null;
  signInWithEmailAndPassword: (email: string, password: string) => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  signInAnonymously: () => Promise<void>;
  signUpWithEmailAndPassword: (email: string, password: string, displayName: string) => Promise<void>;
  sendEmailVerification: () => Promise<void>;
  signOut: () => Promise<void>;
  forgotPassword: (email: string) => Promise<void>;
}