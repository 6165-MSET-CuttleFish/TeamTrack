typescript
import { initializeApp } from 'firebase/app';
import { getAuth, onAuthStateChanged, signInWithEmailAndPassword, createUserWithEmailAndPassword, signOut, sendPasswordResetEmail, User, signInWithCredential, GoogleAuthProvider } from 'firebase/auth';
import { getFirestore, doc, setDoc, updateDoc, getDoc, collection, query, where, onSnapshot } from 'firebase/firestore';
import { getDatabase, ref, onValue, onDisconnect, set, update, push } from 'firebase/database';
import { getMessaging, getToken, onMessage, onBackgroundMessage } from 'firebase/messaging';
import { Platform, NativeModules } from 'react-native';

import { GoogleSignin } from '@react-native-google-signin/google-signin';
import { FIREBASE_CONFIG } from '../constants';

const { RNFiredatabase } = NativeModules;

const firebaseConfig = FIREBASE_CONFIG;

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const rtdb = getDatabase(app);
const messaging = getMessaging(app);

interface FirebaseUser {
  uid: string;
  displayName: string | null;
  email: string | null;
  photoURL: string | null;
}

export const firebaseService = {
  // Authentication

  currentUser: () => {
    return auth.currentUser;
  },

  signInWithEmailAndPassword: async (email: string, password: string) => {
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;
      return user;
    } catch (error) {
      console.error(error);
      return null;
    }
  },

  createUserWithEmailAndPassword: async (email: string, password: string, displayName: string) => {
    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;
      await user?.updateProfile({ displayName });
      return user;
    } catch (error) {
      console.error(error);
      return null;
    }
  },

  signOut: async () => {
    try {
      await signOut(auth);
    } catch (error) {
      console.error(error);
    }
  },

  sendPasswordResetEmail: async (email: string) => {
    try {
      await sendPasswordResetEmail(auth, email);
    } catch (error) {
      console.error(error);
    }
  },

  signInWithGoogle: async () => {
    try {
      await GoogleSignin.configure({
        webClientId: FIREBASE_CONFIG.webClientId,
      });
      const { idToken } = await GoogleSignin.signIn();
      const credential = GoogleAuthProvider.credential(idToken);
      const userCredential = await signInWithCredential(auth, credential);
      const user = userCredential.user;
      return user;
    } catch (error) {
      console.error(error);
      return null;
    }
  },

  // Firebase Firestore

  getUserData: async (uid: string) => {
    try {
      const docRef = doc(db, 'users', uid);
      const docSnap = await getDoc(docRef);
      if (docSnap.exists()) {
        return docSnap.data();
      } else {
        return null;
      }
    } catch (error) {
      console.error(error);
      return null;
    }
  },

  updateUserData: async (uid: string, data: any) => {
    try {
      const docRef = doc(db, 'users', uid);
      await updateDoc(docRef, data);
    } catch (error) {
      console.error(error);
    }
  },

  // Firebase Realtime Database

  getUserStatus: (uid: string) => {
    const userStatusRef = ref(rtdb, `userStatus/${uid}`);
    return onValue(userStatusRef, (snapshot) => {
      const data = snapshot.val();
      if (data) {
        return data;
      } else {
        return null;
      }
    });
  },

  updateUserStatus: async (uid: string, status: string) => {
    try {
      const userStatusRef = ref(rtdb, `userStatus/${uid}`);
      await set(userStatusRef, { status, lastSeen: ServerValue.TIMESTAMP });
    } catch (error) {
      console.error(error);
    }
  },

  // Firebase Messaging

  requestPermission: async () => {
    try {
      if (Platform.OS === 'android') {
        const granted = await messaging.requestPermission({
          alert: true,
          announcement: true,
          badge: true,
          sound: true,
        });
        if (granted.granted) {
          console.log('Notification permission granted.');
        } else {
          console.log('Notification permission denied.');
        }
      }
    } catch (error) {
      console.error(error);
    }
  },

  getToken: async () => {
    try {
      const token = await getToken(messaging);
      return token;
    } catch (error) {
      console.error(error);
      return null;
    }
  },

  onMessage: (callback: (message: any) => void) => {
    onMessage(messaging, (message) => {
      callback(message);
    });
  },

  onBackgroundMessage: (callback: (message: any) => void) => {
    onBackgroundMessage(messaging, callback);
  },
};