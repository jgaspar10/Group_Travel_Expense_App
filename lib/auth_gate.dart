// lib/auth_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'services/user_data_service.dart';

const Color darkBackgroundColor = Color(0xFF204051);

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the connection is still waiting, show a loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: darkBackgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If a user is logged in (snapshot has data)
        if (snapshot.hasData) {
          // Start the user data listener
          UserDataService().listenToUserData(snapshot.data!.uid);
          return const HomePage();
        }

        // If no user is logged in
        return const LoginPage();
      },
    );
  }
}