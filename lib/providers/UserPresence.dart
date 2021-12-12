import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/providers/Auth.dart';

class UserPresence {
  static rtdbAndLocalFsPresence(app) async {
    final uid = AuthenticationService(firebaseAuth).getUser()?.uid;
    final userStatusDatabaseRef =
        firebaseDatabase.ref().child('userStatus/$uid');
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

    firebaseDatabase.ref().child('.info/connected').onValue.listen(
      (event) async {
        if (!(event.snapshot.value as bool)) {
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
      },
    );
  }
}
