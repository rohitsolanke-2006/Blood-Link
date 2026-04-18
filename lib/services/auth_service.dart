// auth_service.dart
// This file handles all authentication (login/register/logout)
// Uses Firebase Auth — Google's authentication service
//
// WHAT IS FIREBASE AUTH?
// Think of it like a security guard for your app.
// When a user registers, Firebase saves their email + password
// securely on Google's servers (not on the phone!).
// It gives each user a unique ID called 'uid' (like a membership card).
// Every time the app opens, Firebase checks if the uid is still valid.
//
// WHAT IS JWT TOKEN?
// Firebase Auth uses tokens internally — when you login,
// Firebase gives your phone a secret token (like a VIP pass).
// This token is sent with every request to prove "I am logged in".
// Firebase handles all of this automatically — we don't need to
// manage tokens manually!

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  // ── GET FIREBASE AUTH INSTANCE ──────────────────────────────────
  // FirebaseAuth.instance = the single auth object we use everywhere
  // 'static' = can be called as AuthService.xxx() without creating object
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── REGISTER ───────────────────────────────────────────────────
  // Creates a new user account with email and password
  // Returns the User object if successful
  // Throws error if email already exists or password too weak
  static Future<User?> register(String email, String password) async {
    try {
      // createUserWithEmailAndPassword = Firebase function that:
      // 1. Checks if email is valid
      // 2. Checks if email already registered
      // 3. Hashes the password (encrypts it)
      // 4. Saves to Firebase servers
      // 5. Returns a UserCredential with the new User
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // .trim() removes extra spaces from email
      return credential.user;
      // credential.user = the newly created User object
      // User has .uid, .email, .displayName etc.
    } on FirebaseAuthException catch (e) {
      // FirebaseAuthException = specific error from Firebase
      // e.message = human readable error like "Email already in use"
      throw e.message ?? 'Registration failed';
    }
  }

  // ── LOGIN ──────────────────────────────────────────────────────
  // Signs in existing user with email and password
  // Returns User if credentials match
  // Throws error if wrong email/password
  static Future<User?> login(String email, String password) async {
    try {
      final UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    }
  }

  // ── LOGOUT ─────────────────────────────────────────────────────
  // Signs out the current user
  // After this, getCurrentUser() returns null
  // and isLoggedIn() returns false
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ── GET CURRENT USER ───────────────────────────────────────────
  // Returns the currently logged-in User object
  // Returns null if no user is logged in
  // This works even after app restart! Firebase remembers the session.
  static User? getCurrentUser() {
    return _auth.currentUser;
    // currentUser = Firebase checks if a valid session exists
    // If yes → returns User object
    // If no → returns null
  }

  // ── IS LOGGED IN ───────────────────────────────────────────────
  // Quick check: is anyone logged in right now?
  // Used by splash screen to decide where to navigate
  static bool isLoggedIn() {
    return _auth.currentUser != null;
    // If currentUser is not null → someone is logged in → true
    // If currentUser is null → no one logged in → false
  }

  // ── GET UID ────────────────────────────────────────────────────
  // Returns the unique user ID of current user
  // This uid is used as the document ID in Firestore
  // Every user has a different uid — guaranteed unique by Firebase
  static String? getCurrentUid() {
    return _auth.currentUser?.uid;
    // ?. = if currentUser is null, return null (don't crash)
  }
}
