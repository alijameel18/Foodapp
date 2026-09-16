import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- UPDATE THESE IMPORTS WITH YOUR ACTUAL FILES ---
import 'instamart_home_page.dart';
import 'instamart_register_upload.dart';

class InstamartLoginPage extends StatefulWidget {
  const InstamartLoginPage({super.key});

  @override
  State<InstamartLoginPage> createState() => _InstamartLoginPageState();
}

class _InstamartLoginPageState extends State<InstamartLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  // ==========================================
  // LOGIC (SAME AS RESTAURANT, DIFFERENT COLLECTION)
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
        // 2. Database Check (Checking 'instamart_requests' collection)
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('instamart_requests') // <--- CHANGED COLLECTION NAME
            .doc(user.uid)
            .get();

        if (!doc.exists) {
          await FirebaseAuth.instance.signOut();
          throw Exception("No store profile found. Please register first.");
        }

        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // 3. Status Check
        String status = (data['status'] ?? 'pending').toString().toLowerCase().trim();

        debugPrint("INSTAMART STATUS: $status");

        if (status == 'pending') {
          await FirebaseAuth.instance.signOut();
          throw Exception("Your store is pending approval.");
        } else if (status == 'rejected') {
          await FirebaseAuth.instance.signOut();
          throw Exception("Your application was rejected.");
        } else if (status == 'approved') {
          // 4. Success -> Navigate to Instamart Home
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const InstamartHomePage()),
                  (route) => false,
            );
          }
        } else {
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
        backgroundColor: Colors.pinkAccent, // Pink for Instamart
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // ==========================================
  // UI BUILD (Grocery Theme)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    // Define Theme Color for consistency
    const Color themeColor = Color(0xFFE91E63); // Pink/Magenta

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
                      // Grocery / Supermarket Image
                      image: NetworkImage('https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=1974&auto=format&fit=crop'),
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
                          Colors.black.withOpacity(0.8),
                          Colors.black.withOpacity(0.3),
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
                          "Instamart\nPartner",
                          style: TextStyle(
                            fontSize: 36,
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
                              child: const Text("Grocery App", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Manage inventory & orders",
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
                          color: themeColor.withOpacity(0.08),
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
                          hintText: "Store Email",
                          icon: Icons.storefront_rounded,
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
                                : const Text("LOGIN TO STORE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                      Text("New Store? ", style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstamartRegisterWithImage())),
                        child: Text("Partner with us", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 4. "WHY PARTNER WITH US"
                  const Divider(),
                  const SizedBox(height: 20),
                  Text(
                    "Grow your grocery business",
                    style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureItem(Icons.flash_on, "10 min\nDelivery", themeColor),
                      _buildFeatureItem(Icons.inventory_2_outlined, "Smart\nInventory", themeColor),
                      _buildFeatureItem(Icons.account_balance_wallet_outlined, "Weekly\nPayouts", themeColor),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 5. FOOTER
                  Text(
                    "v1.0.2 • Instamart Partner",
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
        border: Border.all(color: Colors.grey.shade200),
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