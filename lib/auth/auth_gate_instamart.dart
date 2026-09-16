import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- IMPORTANT: Ensure these imports are correct for your project ---
import '../instamart/instamart_home_page.dart';
import '../instamart/instamart_login_page.dart';

class AuthGateInstamart extends StatelessWidget {
  const AuthGateInstamart({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // 1. Listen to Auth State
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // Waiting for Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Not Logged In -> Show Instamart Login Page
        if (!snapshot.hasData) {
          return const InstamartLoginPage();
        }

        // 3. Logged In -> Check Firestore Status
        User user = snapshot.data!;

        return StreamBuilder<DocumentSnapshot>(
          // --- CHANGE: Listen to 'instamart_requests' collection ---
          stream: FirebaseFirestore.instance
              .collection('instamart_requests')
              .doc(user.uid)
              .snapshots(),

          builder: (context, docSnapshot) {
            // Loading Database
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.pink)));
            }

            // Document doesn't exist
            if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
              return const InstamartLoginPage();
            }

            // 4. Robust Status Check
            Map<String, dynamic> data = docSnapshot.data!.data() as Map<String, dynamic>;
            String status = (data['status'] ?? 'pending').toString().toLowerCase().trim();

            // --- DECISION LOGIC ---
            if (status == 'approved') {
              return const InstamartHomePage(); // Go to Instamart Home
            }
            else if (status == 'rejected') {
              return const RejectedPopupHandler(); // Show Popup
            }
            else {
              // Default: Pending
              return const StatusScreen(
                title: "Under Review",
                message: "Your store application is pending approval by the Admin.\n\nThis screen will automatically update once approved.",
                icon: Icons.access_time,
                color: Colors.pink,
              );
            }
          },
        );
      },
    );
  }
}

// =========================================================
// Beautiful Rejection Popup (Same as Restaurant)
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBeautifulRejectionDialog();
    });
  }

  void _showBeautifulRejectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // White Card
              Container(
                padding: const EdgeInsets.only(left: 20, top: 65, right: 20, bottom: 20),
                margin: const EdgeInsets.only(top: 45),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 10))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Application Rejected",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "We are sorry, but your application to join as an Instamart Partner was not approved.",
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
                              "Please contact support for details.",
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text("Logout & Close", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              // Floating Icon
              Positioned(
                left: 20, right: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 45,
                  child: Container(
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))]
                    ),
                    child: const Center(child: Icon(Icons.close_rounded, size: 50, color: Colors.white)),
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
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
    );
  }
}

// =========================================================
// Status Screen (For Pending)
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
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: color),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                ),
                child: Text("Logout", style: TextStyle(color: color)),
              )
            ],
          ),
        ),
      ),
    );
  }
}