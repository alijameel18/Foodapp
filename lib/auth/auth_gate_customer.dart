import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../customer/customer_homepage.dart';
import '../customer/customer_login_screen.dart';
// REPLACE with your actual file paths

class AuthGateCustomer extends StatelessWidget {
  const AuthGateCustomer({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. User is logged in
        if (snapshot.hasData) {
          return const CustomerHomeScreen(); // Your Main Customer Dashboard
        }

        // 2. User is NOT logged in
        return const CustomerLoginScreen();
      },
    );
  }
}