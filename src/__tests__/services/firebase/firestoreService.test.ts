typescript
import { initializeApp } from 'firebase/app';
import { getFirestore, doc, setDoc, getDoc, updateDoc, deleteDoc, collection, query, where, getDocs, onSnapshot, QuerySnapshot, DocumentSnapshot } from 'firebase/firestore';
import { mockFirestore } from '../../../__mocks__/firestore';
import { mockFirebaseApp } from '../../../__mocks__/firebase';
import { FirebaseFirestoreService } from './firestoreService';

describe('FirestoreService', () => {
  let firestoreService: FirebaseFirestoreService;
  let firestore: FirebaseFirestore;

  beforeEach(() => {
    initializeApp(mockFirebaseApp);
    firestore = getFirestore();
    firestoreService = new FirebaseFirestoreService(firestore);
  });

  describe('CRUD Operations', () => {
    const testCollection = 'testCollection';
    const testDocumentId = 'testDocumentId';
    const testDocumentData = {
      name: 'Test Document',
      field1: 'value1',
      field2: 'value2',
    };

    it('should create a document', async () => {
      await firestoreService.createDocument(testCollection, testDocumentId, testDocumentData);
      const docRef = doc(firestore, testCollection, testDocumentId);
      const docSnapshot = await getDoc(docRef);
      expect(docSnapshot.data()).toEqual(testDocumentData);
    });

    it('should get a document', async () => {
      await setDoc(doc(firestore, testCollection, testDocumentId), testDocumentData);
      const document = await firestoreService.getDocument(testCollection, testDocumentId);
      expect(document).toEqual(testDocumentData);
    });

    it('should update a document', async () => {
      await setDoc(doc(firestore, testCollection, testDocumentId), testDocumentData);
      const updateData = {
        field1: 'updatedValue1',
      };
      await firestoreService.updateDocument(testCollection, testDocumentId, updateData);
      const docRef = doc(firestore, testCollection, testDocumentId);
      const docSnapshot = await getDoc(docRef);
      expect(docSnapshot.data()).toEqual({ ...testDocumentData, ...updateData });
    });

    it('should delete a document', async () => {
      await setDoc(doc(firestore, testCollection, testDocumentId), testDocumentData);
      await firestoreService.deleteDocument(testCollection, testDocumentId);
      const docRef = doc(firestore, testCollection, testDocumentId);
      const docSnapshot = await getDoc(docRef);
      expect(docSnapshot.exists()).toBe(false);
    });
  });

  describe('Query Operations', () => {
    const testCollection = 'testCollection';
    const testDocumentData1 = {
      name: 'Test Document 1',
      field1: 'value1',
      field2: 'value1',
    };
    const testDocumentData2 = {
      name: 'Test Document 2',
      field1: 'value2',
      field2: 'value2',
    };
    const testDocumentData3 = {
      name: 'Test Document 3',
      field1: 'value1',
      field2: 'value3',
    };

    beforeEach(async () => {
      await setDoc(doc(firestore, testCollection, 'doc1'), testDocumentData1);
      await setDoc(doc(firestore, testCollection, 'doc2'), testDocumentData2);
      await setDoc(doc(firestore, testCollection, 'doc3'), testDocumentData3);
    });

    it('should get all documents in a collection', async () => {
      const documents = await firestoreService.getAllDocuments(testCollection);
      expect(documents.length).toBe(3);
    });

    it('should get documents matching a query', async () => {
      const querySnapshot = await firestoreService.getDocumentsByQuery(testCollection, 'field1', '==', 'value1');
      expect(querySnapshot.docs.length).toBe(2);
    });

    it('should listen to changes in a collection', async () => {
      const unsubscribe = firestoreService.listenToCollectionChanges(testCollection, (snapshot) => {
        expect(snapshot.docs.length).toBeGreaterThanOrEqual(3);
      });
      await setDoc(doc(firestore, testCollection, 'doc4'), { name: 'Test Document 4' });
      await new Promise((resolve) => {
        setTimeout(resolve, 1000);
      });
      unsubscribe();
    });

    it('should listen to changes in a document', async () => {
      const unsubscribe = firestoreService.listenToDocumentChanges(testCollection, 'doc1', (snapshot) => {
        expect(snapshot.data()).toEqual(testDocumentData1);
      });
      await updateDoc(doc(firestore, testCollection, 'doc1'), { field1: 'updatedValue1' });
      await new Promise((resolve) => {
        setTimeout(resolve, 1000);
      });
      unsubscribe();
    });
  });

  describe('Batch Operations', () => {
    const testCollection = 'testCollection';
    const testDocumentData1 = {
      name: 'Test Document 1',
      field1: 'value1',
      field2: 'value1',
    };
    const testDocumentData2 = {
      name: 'Test Document 2',
      field1: 'value2',
      field2: 'value2',
    };

    it('should perform a batch write', async () => {
      const batch = firestoreService.createBatch();
      batch.createDocument(testCollection, 'doc1', testDocumentData1);
      batch.updateDocument(testCollection, 'doc2', { field1: 'updatedValue2' });
      await batch.commit();
      const docRef1 = doc(firestore, testCollection, 'doc1');
      const docSnapshot1 = await getDoc(docRef1);
      expect(docSnapshot1.data()).toEqual(testDocumentData1);
      const docRef2 = doc(firestore, testCollection, 'doc2');
      const docSnapshot2 = await getDoc(docRef2);
      expect(docSnapshot2.data()).toEqual({ ...testDocumentData2, field1: 'updatedValue2' });
    });
  });
});