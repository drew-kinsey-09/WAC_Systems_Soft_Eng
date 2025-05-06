//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: auth_gate.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// FILES this is referenced in: main.dart

// this file is used to determine if a user is authenticated or not and show the appropriate screen

// uses the auth_provider.dart to check if the user is authenticated or not

// imports for this file:
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_app_ver4/providers/auth_provider.dart';
import 'package:stock_app_ver4/screens/login_screen.dart';
import 'package:stock_app_ver4/screens/home_screen.dart';

// initializing the AuthGate widget
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // most of the doucmentation is in the auth_provider.dart file
  // so if you're curious about how this works, check that
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Show loading indicator while checking auth state initially or during sign-in/out
    // Helpful source: https://stackoverflow.com/questions/70609895/flutter-how-to-show-loading-indicator-while-checking-auth-state-in-provider
    if (authProvider.isLoading && authProvider.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If authenticated, show the main app screen
    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
