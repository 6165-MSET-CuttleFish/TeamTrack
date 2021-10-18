import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/providers/Auth.dart';

class UserPresence {
  static final _app = Firebase.app();
  static rtdbAndLocalFsPresence(app) async {
    final uid = AuthenticationService(FirebaseAuth.instance).getUser()?.uid;
    final userStatusDatabaseRef =
        firebaseDatabase.reference().child('userStatus/$uid');
    final userStatusFirestoreRef =
        firebaseFirestore.collection('userStatus').doc(uid);

    final isOfflineForDatabase = {
      'status': 'offline',
      'lastSeen': ServerValue.timestamp,
    };

    final isOnlineForDatabase = {
      'status': 'online',
      'lastSeen': ServerValue.timestamp,
    };

    final isOfflineForFirestore = {
      'status': 'offline',
      'lastSeen': FieldValue.serverTimestamp(),
    };

    final isOnlineForFirestore = {
      'status': 'online',
      'lastSeen': FieldValue.serverTimestamp(),
    };

    firebaseDatabase
        .reference()
        .child('.info/connected')
        .onValue
        .listen((event) async {
      if (!event.snapshot.value) {
        userStatusFirestoreRef.update(isOfflineForFirestore);
        return;
      }
      await userStatusDatabaseRef
          .onDisconnect()
          .update(isOfflineForDatabase)
          .then((value) {
        userStatusDatabaseRef.set(isOnlineForDatabase);
        userStatusFirestoreRef.update(isOnlineForFirestore);
      });
    });
  }
}
