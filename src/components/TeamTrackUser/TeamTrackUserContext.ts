typescript
import React, { createContext, useContext, useState, useEffect } from 'react';
import { 
  getAuth, 
  createUserWithEmailAndPassword, 
  signInWithEmailAndPassword, 
  sendPasswordResetEmail, 
  signOut, 
  onAuthStateChanged,
  UserCredential,
  signInWithPopup,
  updateProfile,
  GoogleAuthProvider,
  signInAnonymously,
  linkWithCredential,
  updateEmail,
  updatePassword,
} from 'firebase/auth';
import { doc, getDoc, updateDoc } from 'firebase/firestore';
import { getFirestore } from 'firebase/firestore';
import {
  // @ts-ignore
  GoogleSignin,
} from '@react-native-google-signin/google-signin';
import {
  // @ts-ignore
  AppleAuth,
} from '@invertase/react-native-apple-authentication';
import { Platform } from 'react-native';
import { TeamTrackUser } from './TeamTrackUser';

const auth = getAuth();
const db = getFirestore();

const TeamTrackUserContext = createContext<TeamTrackUser>({} as TeamTrackUser);

interface TeamTrackUserProps {
  children: React.ReactNode;
}

export const TeamTrackUserProvider = ({ children }: TeamTrackUserProps) => {
  const [user, setUser] = useState<TeamTrackUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isAnonymous, setIsAnonymous] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Initialize Google Sign In
  useEffect(() => {
    GoogleSignin.configure({
      webClientId: 'YOUR_WEB_CLIENT_ID', // Replace with your web client ID
    });
  }, []);

  // Initialize Apple Sign In
  useEffect(() => {
    if (Platform.OS === 'ios') {
      AppleAuth.configure({
        // Replace with your Apple app client ID
        clientId: 'YOUR_APPLE_CLIENT_ID',
        // Replace with your Apple app team ID
        teamID: 'YOUR_APPLE_TEAM_ID',
      });
    }
  }, []);

  const signInWithEmail = async (email: string, password: string) => {
    try {
      const userCredential: UserCredential = await signInWithEmailAndPassword(
        auth,
        email,
        password,
      );
      const user = userCredential.user;
      if (user) {
        setUser({
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
          photoURL: user.photoURL,
          role: 'viewer',
          watchingTeam: null,
        });
        // Add token to firestore
        await addToken(user.uid);
      }
    } catch (error: any) {
      setError(error.message);
    }
  };

  const signUpWithEmail = async (email: string, password: string, displayName: string) => {
    try {
      const userCredential: UserCredential = await createUserWithEmailAndPassword(
        auth,
        email,
        password,
      );
      const user = userCredential.user;
      if (user) {
        // Update user profile with display name
        await updateProfile(user, { displayName });
        // Send email verification
        await user.sendEmailVerification();
        setUser({
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
          photoURL: user.photoURL,
          role: 'viewer',
          watchingTeam: null,
        });
        // Add token to firestore
        await addToken(user.uid);
      }
    } catch (error: any) {
      setError(error.message);
    }
  };

  const forgotPassword = async (email: string) => {
    try {
      await sendPasswordResetEmail(auth, email);
      setError(null);
    } catch (error: any) {
      setError(error.message);
    }
  };

  const signInWithGoogle = async () => {
    try {
      const { idToken } = await GoogleSignin.signIn();
      const credential = GoogleAuthProvider.credential(idToken);
      const userCredential: UserCredential = await signInWithPopup(auth, credential);
      const user = userCredential.user;
      if (user) {
        if (user.isAnonymous) {
          // Link with google account if user is anonymous
          await linkWithCredential(user, credential);
        }
        setUser({
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
          photoURL: user.photoURL,
          role: 'viewer',
          watchingTeam: null,
        });
        // Add token to firestore
        await addToken(user.uid);
      }
    } catch (error: any) {
      setError(error.message);
    }
  };

  const signInWithApple = async () => {
    try {
      const appleCredential = await AppleAuth.signInWithApple({
        scopes: [
          AppleAuth.Scope.EMAIL,
          AppleAuth.Scope.FULL_NAME,
        ],
      });
      const credential = AppleAuthProvider.credential(
        appleCredential.identityToken,
        appleCredential.nonce,
      );
      const userCredential: UserCredential = await signInWithPopup(auth, credential);
      const user = userCredential.user;
      if (user) {
        if (user.isAnonymous) {
          // Link with apple account if user is anonymous
          await linkWithCredential(user, credential);
        }
        setUser({
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
          photoURL: user.photoURL,
          role: 'viewer',
          watchingTeam: null,
        });
        // Add token to firestore
        await addToken(user.uid);
      }
    } catch (error: any) {
      setError(error.message);
    }
  };

  const signInAnonymously = async () => {
    try {
      const userCredential: UserCredential = await signInAnonymously(auth);
      const user = userCredential.user;
      if (user) {
        setIsAnonymous(true);
        setUser({
          uid: user.uid,
          displayName: null,
          email: null,
          photoURL: null,
          role: 'viewer',
          watchingTeam: null,
        });
      }
    } catch (error: any) {
      setError(error.message);
    }
  };

  const signOutUser = async () => {
    try {
      // Remove token from firestore
      if (user && user.uid) {
        await removeToken(user.uid);
      }
      await signOut(auth);
      setUser(null);
      setIsAnonymous(false);
      setError(null);
    } catch (error: any) {
      setError(error.message);
    }
  };

  const updateUser = async (
    displayName: string | null,
    email: string | null,
    password: string | null,
  ) => {
    try {
      const user = auth.currentUser;
      if (user) {
        if (displayName) {
          await updateProfile(user, { displayName });
        }
        if (email) {
          await updateEmail(user, email);
        }
        if (password) {
          await updatePassword(user, password);
        }
        // Update user in state
        setUser({
          ...user,
          displayName: displayName || user.displayName,
          email: email || user.email,
        });
      }
    } catch (error: any) {
      setError(error.message);
    }
  };

  const addToken = async (uid: string) => {
    try {
      const docRef = doc(db, 'users', uid);
      const docSnap = await getDoc(docRef);
      if (docSnap.exists()) {
        const data = docSnap.data();
        const tokens = data?.FCMtokens || [];
        if (!tokens.includes(await getFCMToken())) {
          await updateDoc(docRef, { FCMtokens: [...tokens, await getFCMToken()] });
        }
      }
    } catch (error: any) {
      setError(error.message);
    }
  };

  const removeToken = async (uid: string) => {
    try {
      const docRef = doc(db, 'users', uid);
      const docSnap = await getDoc(docRef);
      if (docSnap.exists()) {
        const data = docSnap.data();
        const tokens = data?.FCMtokens || [];
        const newTokens = tokens.filter((token: string) => token !== await getFCMToken());
        await updateDoc(docRef, { FCMtokens: newTokens });
      }
    } catch (error: any) {
      setError(error.message);
    }
  };

  const getFCMToken = async () => {
    // Implement logic to fetch FCM token
    // ...
  };

  // Listen for changes in authentication state
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      if (currentUser) {
        setUser({
          uid: currentUser.uid,
          displayName: currentUser.displayName,
          email: currentUser.email,
          photoURL: currentUser.photoURL,
          role: 'viewer',
          watchingTeam: null,
        });
        // Add token to firestore
        addToken(currentUser.uid);
        // Check if user is anonymous
        setIsAnonymous(currentUser.isAnonymous);
      } else {
        setUser(null);
        setIsAnonymous(false);
      }
      setIsLoading(false);
    });
    return () => unsubscribe();
  }, []);

  return (
    <TeamTrackUserContext.Provider
      value={{
        user,
        isLoading,
        isAnonymous,
        error,
        signInWithEmail,
        signUpWithEmail,
        forgotPassword,
        signInWithGoogle,
        signInWithApple,
        signInAnonymously,
        signOutUser,
        updateUser,
      }}
    >
      {children}
    </TeamTrackUserContext.Provider>
  );
};

export const useTeamTrackUser = () => {
  return useContext(TeamTrackUserContext);
};