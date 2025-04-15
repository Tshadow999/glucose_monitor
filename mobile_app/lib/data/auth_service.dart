import "package:firebase_auth/firebase_auth.dart";

class AuthService {
  final FirebaseAuth fbAuth = FirebaseAuth.instance;

  User? get currentUser => fbAuth.currentUser;

  Stream<User?> get authStateChanges => fbAuth.authStateChanges();

  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await fbAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await fbAuth.signOut();
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await fbAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await fbAuth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    await fbAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updatePassword({
    required String email,
    required String password,
    required String newPassword,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }
}
