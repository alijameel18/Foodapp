import 'package:cloud_firestore/cloud_firestore.dart'; // Use Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthServiceRestaurant {
  Future<void> restaurantLogin(Map<String, String> data, BuildContext context) async {
    try {
      // 1. Sign in with Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data['email']!.trim(), // Added .trim() for safety
        password: data['password']!.trim(),
      );

      User? user = credential.user;

      if (user == null) {
        throw Exception("User not found after login");
      }

      // 2. Check if email is verified
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        await FirebaseAuth.instance.signOut(); // Sign out so AuthGate doesn't allow access
        throw Exception("Email not verified. Verification email sent.");
      }

      String userId = user.uid;

      // 3. --- CORRECTED --- Check Firestore for user data
      //    We are looking in 'restaurant_requests' and using the user.uid as the document ID
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('restaurant_requests')
          .doc(userId)
          .get();

      if (!docSnapshot.exists) {
        await FirebaseAuth.instance.signOut(); // Sign out if no profile found
        throw Exception("No restaurant account found. Please register.");
      }

      // 4. --- CORRECTED --- Check the status from Firestore
      Map<String, dynamic> userData = docSnapshot.data() as Map<String, dynamic>;
      String status = userData['status'] ?? 'pending'; // Get status, default to 'pending'

      if (status == 'pending') {
        await FirebaseAuth.instance.signOut();
        throw Exception("Account is still pending Admin approval.");
      } else if (status == 'rejected') {
        await FirebaseAuth.instance.signOut();
        throw Exception("Your application has been rejected.");
      }
      // If status is 'approved', we let the login proceed.
      // The AuthGate will then automatically navigate to the home page.

      // 5. Navigation is handled by AuthGate when the auth state changes and Firestore status is approved.
      // No manual navigation needed here if AuthGate is set up correctly.

    } catch (e) {
      // Show error to user
      if (context.mounted) { // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")), // Clean up error message
            backgroundColor: Colors.red,
          ),
        );
      }
      // Re-throw to be caught by the calling function (like AuthGate or the login page)
      rethrow;
    }
  }

  Future<void> sendVerificationEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      debugPrint("Verification email sent to ${user.email}");
    }
  }

  // Optional: Add a signOut function if you need to log out from anywhere else
  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // The AuthGate will automatically redirect to the login page.
  }
}