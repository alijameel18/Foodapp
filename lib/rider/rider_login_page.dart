import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- UPDATE THESE IMPORTS TO MATCH YOUR FILES ---
import 'rider_home_page.dart';
import 'rider_register_upload.dart'; // Assuming you have/will create this

class RiderLoginPage extends StatefulWidget {
  const RiderLoginPage({super.key});

  @override
  State<RiderLoginPage> createState() => _RiderLoginPageState();
}

class _RiderLoginPageState extends State<RiderLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  // --- THEME COLOR (Delivery Blue) ---
  final Color themeColor = const Color(0xFF1E88E5);

  // ==========================================
  // LOGIC (ADAPTED FOR RIDERS)
  // ==========================================
  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passController.text.trim().isEmpty) {
      _showError("Please enter email and password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Auth Check
      UserCredential credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      User? user = credential.user;

      if (user != null) {
        // 2. Database Check (Collection: 'rider_requests')
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('rider_requests') // <--- Checking Rider Collection
            .doc(user.uid)
            .get();

        if (!doc.exists) {
          await FirebaseAuth.instance.signOut();
          throw Exception("No rider profile found. Please register first.");
        }

        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // 3. Status Check
        String status = (data['status'] ?? 'pending').toString().toLowerCase().trim();

        debugPrint("RIDER LOGIN STATUS: $status");

        if (status == 'pending') {
          await FirebaseAuth.instance.signOut();
          throw Exception("Your profile is under verification.");
        }
        else if (status == 'rejected') {
          await FirebaseAuth.instance.signOut();
          throw Exception("Your application was rejected.");
        }
        else if (status == 'approved') {
          // 4. Success -> Navigate to Rider Home
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const RiderHomePage()),
                  (route) => false,
            );
          }
        }
        else {
          await FirebaseAuth.instance.signOut();
          throw Exception("Unknown status: $status");
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Login failed");
    } catch (e) {
      _showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // ==========================================
  // UI BUILD (Delivery Theme)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER SECTION
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                      image: DecorationImage(
                        // A delivery rider checking their phone/app on a bike
                        image: NetworkImage('https://images.unsplash.com/photo-1526367790999-0150786686a2?q=80&w=1974&auto=format&fit=crop'),
                        fit: BoxFit.cover,
                      ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(60),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0D47A1).withOpacity(0.8), // Dark Blue Overlay
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(60),
                      ),
                    ),
                    padding: const EdgeInsets.only(bottom: 50, left: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Rider\nLogin",
                          style: TextStyle(
                            fontSize: 38,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: themeColor,
                                  borderRadius: BorderRadius.circular(20)
                              ),
                              child: const Text("Partner App", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Deliver & Earn",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 2. FORM SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // Floating Input Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _emailController,
                          hintText: "Rider Email",
                          icon: Icons.two_wheeler_rounded,
                          color: themeColor,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _passController,
                          hintText: "Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          color: themeColor,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("START RIDING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 3. REGISTER LINK
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Want to join? ", style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                      GestureDetector(
                        // Make sure you have this page created, or point it to a placeholder
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderRegisterWithImage())),
                        child: Text("Register Now", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 4. "WHY JOIN US" SECTION
                  const Divider(),
                  const SizedBox(height: 20),
                  Text(
                    "Be your own boss",
                    style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureItem(Icons.attach_money, "Daily\nEarnings", themeColor),
                      _buildFeatureItem(Icons.schedule, "Flexible\nHours", themeColor),
                      _buildFeatureItem(Icons.health_and_safety_outlined, "Accident\nCover", themeColor),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 5. FOOTER
                  Text(
                    "v1.0.2 • Delivery Partner",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER METHODS ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Color color,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: color),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600]),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.2, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------
// Placeholder for Rider Register Page if you don't have it yet
// Remove this class if you already have 'rider_register_upload.dart'
// -----------------------------------------------------------
