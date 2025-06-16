import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole {
  patient,
  doctor,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.patient:
        return 'patient';
      case UserRole.doctor:
        return 'doctor';
    }
  }
}

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthenticationService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Exposes a stream that notifies about authentication state changes.
  // Widgets or view models can listen to this stream to react to log-in or
  // log-out events in real time.
  Stream<User?> observeAuthState() => _firebaseAuth.authStateChanges();

  // Provides the currently signed-in user, or null if the user is not logged in.
  User? get currentUser => _firebaseAuth.currentUser;

  // Signs the user in using an email and password combination.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Creates a new account for either a doctor or a patient.
  // Additionally, the user document is stored inside the `users` collection
  // so that role information can be retrieved without custom Firebase claims.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required UserRole userRole,
    String? name,
  }) async {
    final UserCredential credential =
        await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User? user = credential.user;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set(<String, Object?>{
        'email': user.email,
        'role': userRole.value,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });

      if (name != null && name.trim().isNotEmpty) {
        await user.updateDisplayName(name.trim());
      }
    }

    return credential;
  }

  // Sends a password-reset email to the specified address.
  Future<void> sendPasswordReset({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  // Signs the current user out of the application.
  Future<void> signOut() => _firebaseAuth.signOut();

  /// Retrieves the saved display name of the **current** user from Firestore.
  /// Returns null if the user is not logged in or if the name hasn't been set.
  Future<String?> fetchDisplayName() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) return null;

    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final String? name = doc.data()?['name'] as String?;
    return (name != null && name.trim().isNotEmpty) ? name.trim() : null;
  }

  /// Updates the display name for the **current** user in both Firestore and
  /// the FirebaseAuth profile. When the user is not logged in, this is a no-op.
  Future<void> updateDisplayName(String newName) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) return;

    final String trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    // Update Firestore
    await _firestore.collection('users').doc(user.uid).set(
      {'name': trimmed},
      SetOptions(merge: true),
    );

    // Update FirebaseAuth user profile (non-blocking if failure)
    try {
      await user.updateDisplayName(trimmed);
    } catch (_) {}
  }
}
