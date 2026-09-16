import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_admin_services.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final AuthServiceAdmin _authService = AuthServiceAdmin();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // --- LOGIN LOGIC ---
  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter details'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Call the service (The Service handles the Navigation to HomePage)
    await _authService.adminLogin(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      context: context,
    );

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Stack(
            children: [
              // 1. TOP HEADER IMAGE
              Positioned(
                top: 0, left: 0, right: 0,
                height: size.height * 0.45,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/images/3.jpg', fit: BoxFit.cover), // Ensure this image exists
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.8)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 32),
                          ),
                          const Spacer(),
                          Text("FoodMart\nAdmin Portal", style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
                          const SizedBox(height: 10),
                          Text("Manage Orders, Inventory & Staff", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. BOTTOM WHITE CONTAINER
              Positioned(
                top: size.height * 0.40,
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 30),

                      Text("Login", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
                      const SizedBox(height: 30),

                      _buildModernTextField(controller: _emailController, hint: "Email Address", icon: Icons.email_outlined),
                      const SizedBox(height: 20),
                      _buildModernTextField(controller: _passwordController, hint: "Password", icon: Icons.lock_outline, isPassword: true, isObscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),

                      // Align(
                      //   alignment: Alignment.centerRight,
                      //   child: TextButton(onPressed: () {}, child: Text("Forgot Password?", style: GoogleFonts.poppins(color: const Color(0xFFFF5200), fontWeight: FontWeight.w600, fontSize: 13))),
                      // ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5200),
                            elevation: 8,
                            shadowColor: const Color(0xFFFF5200).withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text("Secure Login", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),

                      const SizedBox(height: 40),

                      Center(
                        child: Column(
                          children: [
                            Text("Need help? Contact IT Support", style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.verified_user, color: Colors.green, size: 14),
                                const SizedBox(width: 5),
                                Text("System Operational v1.0.4", style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 11)),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, bool isObscure = false, VoidCallback? onToggle}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: GoogleFonts.poppins(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFFFF5200)),
          suffixIcon: isPassword ? IconButton(icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: onToggle) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}