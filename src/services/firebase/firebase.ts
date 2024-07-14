import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getMessaging } from 'firebase/messaging';
import { getStorage } from 'firebase/storage';
import { firebaseConfig } from '../../utils/constants/constants';
import { FirebaseProps } from './firebase.types';

const app = initializeApp(firebaseConfig);

const auth = getAuth(app);
const firestore = getFirestore(app);
const messaging = getMessaging(app);
const storage = getStorage(app);

const firebase: FirebaseProps = {
  auth,
  firestore,
  messaging,
  storage,
};

export default firebase;