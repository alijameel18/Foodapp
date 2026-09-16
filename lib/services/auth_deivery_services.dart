import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthServiceRider {

  // Login function specifically for Delivery Partners (Riders)
  Future<void> riderLogin(Map<String, String> data, BuildContext context) async {
    try {
      // 1. Sign in with Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data['email']!.trim(),
        password: data['password']!.trim(),
      );

      User? user = credential.user;

      if (user == null) {
        throw Exception("User not found after login");
      }

      // 2. Check if email is verified
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        await FirebaseAuth.instance.signOut(); // Force logout
        throw Exception("Email not verified. Verification email sent.");
      }

      String userId = user.uid;

      // 3. --- Check Firestore for RIDER data ---
      // We look in 'rider_requests' collection
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('rider_requests') // <--- Changing collection to riders
          .doc(userId)
          .get();

      if (!docSnapshot.exists) {
        await FirebaseAuth.instance.signOut(); // Sign out if no profile found
        throw Exception("No delivery partner account found. Please register first.");
      }

      // 4. --- Check the status from Firestore ---
      Map<String, dynamic> userData = docSnapshot.data() as Map<String, dynamic>;
      // Convert to lowercase and trim to be safe (e.g. "Approved" vs "approved")
      String status = (userData['status'] ?? 'pending').toString().toLowerCase().trim();

      if (status == 'pending') {
        await FirebaseAuth.instance.signOut();
        throw Exception("Your account is still under review by Admin.");
      }
      else if (status == 'rejected') {
        await FirebaseAuth.instance.signOut();
        throw Exception("Your application has been rejected.");
      }

      // If status is 'approved', the function completes successfully.
      // The AuthGateRider or Login Page navigation logic will take over.

    } catch (e) {
      // Show error to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // Re-throw to be caught by the calling function
      rethrow;
    }
  }

  // Helper to resend verification email
  Future<void> sendVerificationEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      debugPrint("Verification email sent to ${user.email}");
    }
  }

  // Logout function
  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }
}