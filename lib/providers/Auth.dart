import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:teamtrack/models/AppModel.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;
  AuthenticationService(this._firebaseAuth);
  User? getUser() => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.idTokenChanges();

  Future<void> addToken() async {
    final docRef = firebaseFirestore
        .collection('users')
        .doc(_firebaseAuth.currentUser?.uid);
    await firebaseFirestore.runTransaction((t) async {
      var snapshot = await t.get(docRef);
      List newTokens = snapshot.data()?['FCMtokens'];
      if (!newTokens.contains(dataModel.token) && dataModel.token != null) {
        newTokens.add(dataModel.token!);
      }
      return t.update(docRef, {'FCMtokens': newTokens});
    });
  }

  Future<void> removeToken() async {
    final docRef = firebaseFirestore
        .collection('users')
        .doc(_firebaseAuth.currentUser?.uid);
    await firebaseFirestore.runTransaction((t) async {
      var snapshot = await t.get(docRef);
      List newTokens = snapshot.data()?['FCMtokens'];
      if (dataModel.token != null)
        newTokens.removeWhere((e) => e == dataModel.token);
      return t.update(docRef, {'FCMtokens': newTokens});
    });
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      addToken();
      return "Signed in";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> forgotPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return "sent";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (_firebaseAuth.currentUser?.isAnonymous ?? false) {
      AuthCredential credential =
          EmailAuthProvider.credential(email: email, password: password);
      try {
        await _firebaseAuth.currentUser?.linkWithCredential(credential);
        _firebaseAuth.currentUser?.updateDisplayName(displayName);
        _firebaseAuth.currentUser?.sendEmailVerification();
        return "Signed Up";
      } on FirebaseAuthException catch (e) {
        return e.message;
      }
    } else {
      try {
        await _firebaseAuth.createUserWithEmailAndPassword(
            email: email, password: password);
        _firebaseAuth.currentUser?.updateDisplayName(displayName);
        _firebaseAuth.currentUser?.sendEmailVerification();
        return "Signed up";
      } on FirebaseAuthException catch (e) {
        return e.message;
      }
    }
  }

  Future<void> signOut() async {
    await removeToken();
    await _firebaseAuth.signOut();
  }

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      if (_firebaseAuth.currentUser?.isAnonymous ?? false) {
        return _firebaseAuth.currentUser?.linkWithCredential(credential);
      }
      var result = await _firebaseAuth.signInWithCredential(credential);
      addToken();
      return result;
    }
    return null;
  }

  Future<UserCredential?> signInWithAnonymous() async {
    if (_firebaseAuth.currentUser?.isAnonymous ?? false) return null;
    return _firebaseAuth.signInAnonymously();
  }
}