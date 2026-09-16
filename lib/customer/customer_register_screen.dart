import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for Status Bar control
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_customer_service.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  // 1. Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 2. Service & State
  final AuthCustomerService _authService = AuthCustomerService();
  bool _isLoading = false;
  bool _agreeToTerms = false;
  final Color _primaryColor = const Color(0xFFFF4B3A);

  // 3. THE FULL REGISTER LOGIC
  void register() async {
    // 1. Validate Inputs
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. Validate Terms
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please agree to the Terms and Privacy Policy"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 3. Call Firebase Service
      await _authService.signUpWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (mounted) {
        // 4. SHOW MODERN "FLOATING ICON" DIALOG
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return Dialog(
              backgroundColor: Colors.transparent, // Transparent for custom shapes
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // --- 1. THE WHITE CARD ---
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 40), // Push down for icon
                    padding: const EdgeInsets.fromLTRB(25, 55, 25, 25), // Padding for content
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Account Created!",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Your account has been successfully registered.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                        ),

                        const SizedBox(height: 20),

                        // --- HIGHLIGHTED EMAIL BOX ---
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2ED), // Light orange background
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: _primaryColor.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Verification link sent to:",
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _emailController.text,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text(
                          "Please check your inbox and verify your email before logging in.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                        ),

                        const SizedBox(height: 25),

                        // --- BUTTON ---
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              elevation: 5,
                              shadowColor: _primaryColor.withOpacity(0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            child: Text(
                              "Login Now",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- 2. THE FLOATING SUCCESS ICON ---
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white, // White border effect
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(4), // Thickness of white border
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF27AE60), // Nice Success Green
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 45,
                          color: Colors.white,
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll("Exception:", "").trim()),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white,
        body: SizedBox(
          height: size.height,
          child: Stack(
            children: [
              // --- 1. HEADER IMAGE ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: size.height * 0.40,
                child: Image.asset(
                  'assets/images/logo.jpg',
                  fit: BoxFit.cover,
                ),
              ),

              // --- 2. DARK OVERLAY ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: size.height * 0.40,
                child: Container(color: Colors.black.withOpacity(0.1)),
              ),

              // --- 3. WHITE CONTAINER ---
              Positioned(
                top: size.height * 0.30,
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(30, 30, 30, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- TOGGLE SWITCH ---
                        Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              // Register (Active)
                              Expanded(
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: _primaryColor,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                  ),
                                  child: Text("Register", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              // Login (Navigates Back)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    color: Colors.transparent,
                                    alignment: Alignment.center,
                                    child: Text("Log In", style: GoogleFonts.poppins(color: Colors.grey[500], fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // --- HEADER TEXT ---
                        Text("Create Account",
                            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text("Sign up to get started.",
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),

                        const SizedBox(height: 25),

                        _buildLabel("Full Name"),
                        const SizedBox(height: 8),
                        _buildInputField(_nameController, "Your Full Name", Icons.person_outline),

                        const SizedBox(height: 15),
                        _buildLabel("Email Address"),
                        const SizedBox(height: 8),
                        _buildInputField(_emailController, "example@gmail.com", Icons.email_outlined, type: TextInputType.emailAddress),

                        const SizedBox(height: 15),
                        _buildLabel("Mobile Number"),
                        const SizedBox(height: 8),
                        _buildInputField(_mobileController, "+91 9876543210", Icons.phone_outlined, type: TextInputType.phone),

                        const SizedBox(height: 15),
                        _buildLabel("Delivery Address"),
                        const SizedBox(height: 8),
                        _buildInputField(_addressController, "Street, City, Zip", Icons.location_on_outlined, maxLines: 2),

                        const SizedBox(height: 15),
                        _buildLabel("Password"),
                        const SizedBox(height: 8),
                        _buildInputField(_passwordController, "••••••", Icons.lock_outline, isObscure: true),

                        const SizedBox(height: 20),

                        // Terms
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreeToTerms,
                                activeColor: _primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (v) => setState(() => _agreeToTerms = v!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text("I agree to the Terms of Service and Privacy Policy",
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // --- GET STARTED BUTTON ---
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            // 4. IMPORTANT: Link the function correctly here!
                            onPressed: _isLoading ? null : register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text("Get Started", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Footer
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                  text: "Already have an account? ",
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
                                  children: [
                                    TextSpan(
                                      text: "Log In",
                                      style: GoogleFonts.poppins(fontSize: 12, color: _primaryColor, fontWeight: FontWeight.bold),
                                    )
                                  ]
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87));
  }

  Widget _buildInputField(TextEditingController controller, String hint, IconData icon, {bool isObscure = false, TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}