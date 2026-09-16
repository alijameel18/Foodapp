// auth_customer_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthCustomerService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Updated signUpWithEmailPassword to include user details
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String mobile,
    required String address,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Update the user's display name in Auth
      await userCredential.user!.updateDisplayName(name);

      // 3. Send email verification
      await userCredential.user!.sendEmailVerification();

      // 4. Save additional user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'mobile': mobile,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Add to your existing AuthCustomerService class
  Future<void> updateUserProfile(String name, String? phone, String? address) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Update in Firebase Auth
        await user.updateDisplayName(name);

        // Update in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'name': name,
          'phone': phone,
          'address': address,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Sign in method
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}