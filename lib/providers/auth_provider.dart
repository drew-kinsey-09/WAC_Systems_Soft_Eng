//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart: auth_provider.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// this file is used to manage authentication using Firebase Auth

// imports for this file:
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

//initializing the AuthProvider class
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;

  // using firebase auth to listen to auth state changes
  // firebase auth source: https://firebase.google.com/docs
  AuthProvider() {
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  // getters from the AuthProvider class
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Clears the error message if it exists.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
    }
  }

  // Listens to Firebase Auth state changes and updates the provider state.
  // source: https://firebase.google.com/docs
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _user = firebaseUser;
    clearError();
    _setLoading(false);
    print(
      "Auth State Changed: User is ${firebaseUser == null ? 'null' : firebaseUser.uid}",
    );
    notifyListeners();
  }

  // Attempts to sign up a new user with email and password.
  // Returns true on success, false on failure.
  // making a firebase auth
  // helpful sources: https://firebase.google.com/docs/build
  // video that helped: https://www.youtube.com/watch?v=k7TVYn5jwQk
  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    clearError();
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "An unknown sign-up error occurred.";
      _setLoading(false);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "An unexpected error occurred during sign-up: $e";
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Attempts to sign in an existing user with email and password.
  /// Returns true on success, false on failure.
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    clearError(); // <--- Update internal call
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "An unknown login error occurred.";
      _setLoading(false);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "An unexpected error occurred during login: $e";
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    clearError(); // <--- Update internal call
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      _errorMessage = "Error signing out: $e";
      _setLoading(false);
      notifyListeners();
    }
  }
}
