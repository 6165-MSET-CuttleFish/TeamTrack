typescript
import { initializeApp } from "firebase/app";
import { getFirestore, collection, query, getDocs, doc, setDoc, getDoc, updateDoc, deleteDoc } from "firebase/firestore";
import { getAuth, onAuthStateChanged, signOut } from "firebase/auth";
import { firebaseConfig } from "../../config";
import { User } from "../models/user.model";

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

export const firestoreService = {
  // Authentication
  currentUser: null,
  authStateListener: null,
  // FIRESTORE
  // Users
  users: collection(db, "users"),
  getUserById: async (id: string) => {
    const docRef = doc(this.users, id);
    const docSnap = await getDoc(docRef);
    if (docSnap.exists()) {
      return docSnap.data() as User;
    } else {
      return null;
    }
  },
  createUser: async (user: User) => {
    const docRef = doc(this.users, user.id);
    await setDoc(docRef, user);
  },
  updateUser: async (user: User) => {
    const docRef = doc(this.users, user.id);
    await updateDoc(docRef, user);
  },
  deleteUser: async (id: string) => {
    const docRef = doc(this.users, id);
    await deleteDoc(docRef);
  },
  // GENERAL
  // Create a new document
  createDocument: async (collectionName: string, documentData: any) => {
    const docRef = doc(collection(db, collectionName));
    await setDoc(docRef, documentData);
  },
  // Update a document
  updateDocument: async (collectionName: string, documentId: string, documentData: any) => {
    const docRef = doc(collection(db, collectionName), documentId);
    await updateDoc(docRef, documentData);
  },
  // Delete a document
  deleteDocument: async (collectionName: string, documentId: string) => {
    const docRef = doc(collection(db, collectionName), documentId);
    await deleteDoc(docRef);
  },
  // Get all documents in a collection
  getAllDocuments: async (collectionName: string) => {
    const querySnapshot = await getDocs(collection(db, collectionName));
    return querySnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  },
  // Get documents matching a query
  getDocumentsByQuery: async (collectionName: string, queryOptions: any) => {
    const q = query(collection(db, collectionName), ...queryOptions);
    const querySnapshot = await getDocs(q);
    return querySnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  },
  // Listen for changes to a document
  onDocumentChange: async (collectionName: string, documentId: string, callback: (data: any) => void) => {
    const docRef = doc(collection(db, collectionName), documentId);
    const unsubscribe = onSnapshot(docRef, (docSnap) => {
      if (docSnap.exists()) {
        callback(docSnap.data());
      }
    });
    return unsubscribe;
  },
  // Listen for changes to a collection
  onCollectionChange: async (collectionName: string, callback: (data: any[]) => void) => {
    const unsubscribe = onSnapshot(collection(db, collectionName), (querySnapshot) => {
      const data = querySnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
      callback(data);
    });
    return unsubscribe;
  },
  // Authentication
  signIn: async (email: string, password: string) => {
    return await auth.signInWithEmailAndPassword(email, password);
  },
  signOut: async () => {
    return await signOut(auth);
  },
  // Set up Authentication state listener
  setupAuthStateListener: (callback: (user: any | null) => void) => {
    this.authStateListener = onAuthStateChanged(auth, (user) => {
      this.currentUser = user;
      callback(user);
    });
  },
  // Remove Authentication state listener
  removeAuthStateListener: () => {
    if (this.authStateListener) {
      this.authStateListener();
      this.authStateListener = null;
    }
  },
};

export const authFunctions = {
  createUserWithEmailAndPassword: async (email: string, password: string) => {
    return await auth.createUserWithEmailAndPassword(email, password);
  },
  signInWithEmailAndPassword: async (email: string, password: string) => {
    return await auth.signInWithEmailAndPassword(email, password);
  },
  signInWithPopup: async (provider: any) => {
    return await auth.signInWithPopup(provider);
  },
  sendPasswordResetEmail: async (email: string) => {
    return await auth.sendPasswordResetEmail(email);
  },
  currentUser: () => {
    return auth.currentUser;
  },
};