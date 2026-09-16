import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../admin/admin_home_screen.dart';
import '../admin/admin_login_screen.dart';


class AuthGateAdmin extends StatelessWidget {
  const AuthGateAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          // User is logged in, show Dashboard
          return const AdminHomePage();
        }

        // User is NOT logged in, show the new Login Page
        return const AdminLoginScreen();
      },
    );
  }
}