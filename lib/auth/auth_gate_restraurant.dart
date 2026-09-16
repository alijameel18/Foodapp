import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../restraurant/restaurant_home_page.dart';
import '../restraurant/restraurant_login.dart';

class AuthGateRestaurant extends StatelessWidget {
  const AuthGateRestaurant({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Waiting for Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Not Logged In -> Show Login Page
        if (!snapshot.hasData) {
          return const RestaurantLoginPage();
        }

        // 3. Logged In -> Check Firestore Status
        User user = snapshot.data!;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('restaurant_requests')
              .doc(user.uid)
              .snapshots(),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
            }

            if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
              return const RestaurantLoginPage();
            }

            // Robust Status Check
            Map<String, dynamic> data = docSnapshot.data!.data() as Map<String, dynamic>;
            String status = (data['status'] ?? 'pending').toString().toLowerCase().trim();

            // --- DECISION LOGIC ---

            if (status == 'approved') {
              return const RestaurantHomePage();
            }
            else if (status == 'rejected') {
              // CHANGE: Call the Popup Handler instead of a static screen
              return const RejectedPopupHandler();
            }
            else {
              // Pending: Keep as full screen so they know they are waiting
              return const StatusScreen(
                title: "Under Review",
                message: "Your application is currently pending approval by the Admin.\n\nThis screen will automatically update once you are approved.",
                icon: Icons.access_time,
                color: Colors.orange,
              );
            }
          },
        );
      },
    );
  }
}

// =========================================================
// NEW: Widget to handle the Pop-up logic
// =========================================================
// =========================================================
// NEW: Beautiful Widget to handle the Pop-up logic
// =========================================================
class RejectedPopupHandler extends StatefulWidget {
  const RejectedPopupHandler({super.key});

  @override
  State<RejectedPopupHandler> createState() => _RejectedPopupHandlerState();
}

class _RejectedPopupHandlerState extends State<RejectedPopupHandler> {
  @override
  void initState() {
    super.initState();
    // Trigger the dialog immediately after the widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBeautifulRejectionDialog();
    });
  }

  void _showBeautifulRejectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User MUST click Logout
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // 1. The White Card Content
              Container(
                padding: const EdgeInsets.only(
                  left: 20,
                  top: 45 + 20, // Padding for the floating icon
                  right: 20,
                  bottom: 20,
                ),
                margin: const EdgeInsets.only(top: 45), // Margin for the floating icon
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Application Rejected",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "We are sorry, but your application to join as a restaurant partner was not approved by the Admin.",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.1))
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Please contact support for more details regarding this decision.",
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop(); // Close Dialog
                          await FirebaseAuth.instance.signOut(); // Sign Out
                        },
                        child: const Text(
                          "Logout & Close",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. The Floating Icon (Top Center)
              Positioned(
                left: 20,
                right: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.white, // White rim
                  radius: 45,
                  child: Container(
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                        ]
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Background behind the dialog
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      ),
    );
  }
}

// =========================================================
// Status Screen (Used for Pending only now)
// =========================================================
class StatusScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const StatusScreen({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 20),
              Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text("Logout"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

