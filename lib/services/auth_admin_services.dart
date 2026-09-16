import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ⚠️ Check this import path matches your project structure exactly
import '../admin/admin_home_screen.dart';


class AuthServiceAdmin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // 🔧 MANUAL PASSWORD CONFIGURATION
  // ---------------------------------------------------------------------------
  static const String masterAdminEmail = "admin@foodmart.com";
  static const String masterAdminManualPassword = "123456";
  // ---------------------------------------------------------------------------

  // --- Admin Login Logic ---
  Future<void> adminLogin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // 1. Attempt to Authenticate
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Success? Check Database Role
      await _checkRoleAndNavigate(userCredential.user!, context);

    } on FirebaseAuthException catch (e) {

      // -----------------------------------------------------------------------
      // 🚀 ROBUST AUTO-CREATE MASTER ADMIN LOGIC
      // -----------------------------------------------------------------------
      if (email == masterAdminEmail) {
        // If login failed for the Master Admin, try to CREATE it.
        // This handles cases where Firebase hides the 'user-not-found' error.
        try {
          UserCredential newUser = await _auth.createUserWithEmailAndPassword(
            email: masterAdminEmail,
            password: masterAdminManualPassword, // Uses your manual password
          );

          // If creation succeeded, set up Firestore
          await _createAdminInFirestore(newUser.user!);

          if (context.mounted) {
            _showSuccessDialog(context, "Master Admin Created!\nPassword: $masterAdminManualPassword");

            // Navigate to Home
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomePage()),
            );
          }
          return; // Stop here, we are logged in.

        } on FirebaseAuthException catch (createError) {
          // If create failed because email exists, the original login failure was a WRONG PASSWORD.
          if (createError.code == 'email-already-in-use') {
            _showErrorDialog(context, "Login Failed", "Incorrect password for Master Admin.");
            return;
          }
        }
      }
      // -----------------------------------------------------------------------

      // Handle standard errors for other users
      String errorMessage = 'An error occurred (${e.code})';

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address format.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This admin account has been disabled.';
      } else if (e.code == 'user-not-found') {
        errorMessage = 'No admin account found with this email.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many attempts. Please try again later.';
      }

      if (context.mounted) {
        _showErrorDialog(context, "Login Error", errorMessage);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, "Unexpected Error", e.toString());
      }
    }
  }

  // --- Helper: Check Role & Navigate ---
  Future<void> _checkRoleAndNavigate(User user, BuildContext context) async {
    // Check 'users' collection (Ensure this matches your database setup)
    // Note: Some setups use 'admin' collection, others use 'users' with role 'admin'
    // I will check 'users' based on your previous code.
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String userRole = userData['role']?.toString() ?? '';

      if (userRole == 'admin') {
        // Success: Update Last Login
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome back, Admin!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminHomePage()),
          );
        }
      } else {
        await _auth.signOut();
        if (context.mounted) {
          _showErrorDialog(context, "Access Denied", "This account is not authorized as an Admin.");
        }
      }
    } else {
      // User exists in Auth but not in DB (Fix for Master Admin)
      if (user.email == masterAdminEmail) {
        await _createAdminInFirestore(user);
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminHomePage()),
          );
        }
      } else {
        await _auth.signOut();
        if (context.mounted) {
          _showErrorDialog(context, "Profile Error", "User profile not found in database.");
        }
      }
    }
  }

  // --- Helper: Create Admin Data in Firestore ---
  Future<void> _createAdminInFirestore(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'role': 'admin',
        'name': 'FoodMart Administrator',
        'branch': 'Head Office',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error creating Admin data: $e');
      throw Exception('Failed to create Admin data');
    }
  }

  // --- Logout ---
  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
  }

  // --- Helper Dialogs ---
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Success", style: TextStyle(color: Colors.green)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}