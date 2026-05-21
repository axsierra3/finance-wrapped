import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'nav_tab_manager.dart';
import 'user_handling/signup_page.dart';

// AuthWrapper sits between the splash intro pafe and the rest of the app
// it watches Firebase auth state via StreamBuilder
// logged in go to NavTabManager, logged out go to SignUpPage
// this means logout auto-redirects without manual navigation code
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // authStateChanges() is a stream that fires whenever
      // login or logout happens — StreamBuilder rebuilds automatically
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // still connecting to Firebase — show blank mint screen
        // so there's no flash of white before content loads
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFB5F5D8),
          );
        }
        // snapshot.hasData means there's a logged in user
        if (snapshot.hasData) {
          return const NavTabManager();
        }

        // no user — show signup
        return const SignUpPage();
      },
    );
  }
}