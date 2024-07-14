import {
  CollectionReference,
  DocumentData,
  DocumentReference,
  FirestoreDataConverter,
  QuerySnapshot,
  SnapshotOptions,
  WriteBatch,
} from 'firebase/firestore';
import {
  getDatabase,
  orderByChild,
  Query,
  ref,
  set,
  onValue,
  onDisconnect,
  update,
  remove,
  DataSnapshot,
  off,
} from 'firebase/database';
import { User } from 'firebase/auth';
import {
  FirebaseMessagingTypes,
  Notification,
  Messaging,
  RemoteMessage,
} from 'firebase/messaging';
import {
  getDownloadURL,
  getStorage,
  ref as storageRef,
  uploadBytesResumable,
} from 'firebase/storage';

export type FirebaseFirestoreTypes = {
  firestore: {
    collection: <T extends DocumentData>(
      path: string,
      converter?: FirestoreDataConverter<T>,
    ) => CollectionReference<T>;
    doc: <T extends DocumentData>(
      path: string,
      converter?: FirestoreDataConverter<T>,
    ) => DocumentReference<T>;
    collectionGroup: <T extends DocumentData>(
      collectionId: string,
      converter?: FirestoreDataConverter<T>,
    ) => CollectionReference<T>;
    runTransaction: <T>(
      updateFunction: (transaction: WriteBatch) => Promise<T>,
      options?: SnapshotOptions,
    ) => Promise<T>;
  };
  writeBatch: () => WriteBatch;
  FieldValue: {
    serverTimestamp: () => any;
  };
};

export type FirebaseDatabaseTypes = {
  database: {
    ref: (path: string) => Query;
    orderByChild: (key: string) => Query;
    set: (ref: Query, data: any) => Promise<void>;
    update: (ref: Query, data: any) => Promise<void>;
    onValue: (
      ref: Query,
      callback: (snapshot: DataSnapshot) => void,
      options?: {
        onlyOnce?: boolean;
        cancelCallback?: () => void;
      },
    ) => off;
    onDisconnect: (ref: Query) => Query;
    remove: (ref: Query) => Promise<void>;
    child: (path: string) => Query;
  };
};

export type FirebaseMessagingTypes = {
  messaging: {
    getToken: () => Promise<string | null>;
    onMessage: (
      callback: (message: RemoteMessage) => void,
    ) => void;
    onTokenRefresh: (callback: (token: string) => void) => void;
    onNotificationOpenedApp: (
      callback: (message: RemoteMessage) => void,
    ) => void;
    onBackgroundMessage: (
      callback: (message: RemoteMessage) => Promise<void>,
    ) => void;
    deleteToken: () => Promise<void>;
    requestPermission: () => Promise<PermissionStatus>;
    getInitialNotification: () => Promise<RemoteMessage | null>;
    registerForRemoteNotifications: () => Promise<void>;
  };
};

export type FirebaseStorageTypes = {
  storage: {
    ref: (path: string) => any;
    uploadBytesResumable: (
      ref: any,
      data: any,
      metadata?: any,
    ) => Promise<any>;
    getDownloadURL: (ref: any) => Promise<string>;
  };
};

export type FirebaseAuthenticationTypes = {
  auth: {
    signInWithEmailAndPassword: (
      email: string,
      password: string,
    ) => Promise<UserCredential>;
    createUserWithEmailAndPassword: (
      email: string,
      password: string,
    ) => Promise<UserCredential>;
    signOut: () => Promise<void>;
    currentUser: User | null;
    onAuthStateChanged: (callback: (user: User | null) => void) => void;
    signInWithPopup: (provider: any) => Promise<UserCredential>;
    signInWithRedirect: (provider: any) => Promise<void>;
    signInAnonymously: () => Promise<UserCredential>;
    sendPasswordResetEmail: (email: string) => Promise<void>;
    confirmPasswordReset: (code: string, newPassword: string) => Promise<void>;
    updatePassword: (newPassword: string) => Promise<void>;
    updateEmail: (newEmail: string) => Promise<void>;
    updateProfile: (profile: { displayName?: string; photoURL?: string }) => Promise<void>;
    linkWithCredential: (credential: any) => Promise<UserCredential>;
    unlink: (providerId: string) => Promise<void>;
    reauthenticateWithCredential: (credential: any) => Promise<void>;
  };
};

export type FirebaseTypes = {
  firestore: FirebaseFirestoreTypes['firestore'];
  database: FirebaseDatabaseTypes['database'];
  messaging: FirebaseMessagingTypes['messaging'];
  storage: FirebaseStorageTypes['storage'];
  auth: FirebaseAuthenticationTypes['auth'];
  FieldValue: FirebaseFirestoreTypes['FieldValue'];
};