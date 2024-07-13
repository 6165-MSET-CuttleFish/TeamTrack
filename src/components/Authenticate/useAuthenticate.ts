typescript
import { useState, useEffect } from 'react';
import {
  getAuth,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  sendPasswordResetEmail,
  signOut,
  signInWithPopup,
  GoogleAuthProvider,
  updateProfile,
  signInAnonymously,
  onAuthStateChanged,
  User,
  UserCredential,
} from 'firebase/auth';
import {
  getFirestore,
  doc,
  getDoc,
  updateDoc,
  runTransaction,
} from 'firebase/firestore';

export const useAuthenticate = () => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [token, setToken] = useState<string | null>(null);

  const auth = getAuth();
  const firestore = getFirestore();

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setUser(user);
      setIsLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const addToken = async () => {
    try {
      const docRef = doc(firestore, 'users', auth.currentUser?.uid ?? '');
      await runTransaction(firestore, async (transaction) => {
        const snapshot = await transaction.get(docRef);
        let newTokens = snapshot.data()?.FCMtokens || [];
        if (!newTokens.includes(token) && token) {
          newTokens.push(token);
        }
        await transaction.update(docRef, { FCMtokens: newTokens });
      });
    } catch (error) {
      setError(error.message);
    }
  };

  const removeToken = async () => {
    try {
      const docRef = doc(firestore, 'users', auth.currentUser?.uid ?? '');
      await runTransaction(firestore, async (transaction) => {
        const snapshot = await transaction.get(docRef);
        let newTokens = snapshot.data()?.FCMtokens || [];
        if (token) {
          newTokens = newTokens.filter((e) => e !== token);
        }
        await transaction.update(docRef, { FCMtokens: newTokens });
      });
    } catch (error) {
      setError(error.message);
    }
  };

  const signIn = async (email: string, password: string) => {
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      addToken();
      return 'Signed in';
    } catch (error) {
      return error.message;
    }
  };

  const forgotPassword = async (email: string) => {
    try {
      await sendPasswordResetEmail(auth, email);
      return 'sent';
    } catch (error) {
      return error.message;
    }
  };

  const signUp = async (
    email: string,
    password: string,
    displayName: string
  ) => {
    try {
      const userCredential = await createUserWithEmailAndPassword(
        auth,
        email,
        password
      );
      await updateProfile(auth.currentUser, { displayName });
      await auth.currentUser?.sendEmailVerification();
      return 'Signed up';
    } catch (error) {
      return error.message;
    }
  };

  const signOutUser = async () => {
    await removeToken();
    await signOut(auth);
  };

  const signInWithGoogle = async () => {
    try {
      const provider = new GoogleAuthProvider();
      provider.addScope('https://www.googleapis.com/auth/contacts.readonly');
      provider.setCustomParameters({ login_hint: 'user@example.com' });
      const userCredential = await signInWithPopup(auth, provider);
      addToken();
      return userCredential;
    } catch (error) {
      setError(error.message);
    }
  };

  const signInWithAnonymous = async () => {
    try {
      const userCredential = await signInAnonymously(auth);
      return userCredential;
    } catch (error) {
      setError(error.message);
    }
  };

  return {
    user,
    isLoading,
    error,
    signIn,
    forgotPassword,
    signUp,
    signOut: signOutUser,
    signInWithGoogle,
    signInWithAnonymous,
    setToken,
  };
};