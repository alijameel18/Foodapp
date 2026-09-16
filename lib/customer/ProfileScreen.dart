import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_history_screen.dart'; // Import your order history screen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;

    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
          _nameController.text = _userData['name'] ?? '';
          _emailController.text = _userData['email'] ?? _currentUser!.email ?? '';
          _phoneController.text = _userData['phone'] ?? '';
          _addressController.text = _userData['address'] ?? '';
          _isLoading = false;
        });
      } else {
        // Create user document if it doesn't exist
        await _createUserDocument();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createUserDocument() async {
    if (_currentUser == null) return;

    _userData = {
      'uid': _currentUser!.uid,
      'name': _currentUser!.displayName ?? 'User',
      'email': _currentUser!.email,
      'phone': '',
      'address': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .set(_userData, SetOptions(merge: true));

    setState(() {
      _nameController.text = _userData['name'];
      _emailController.text = _userData['email'] ?? '';
    });
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;

    if (_nameController.text.isEmpty) {
      _showSnackBar("Please enter your name");
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update email in Firebase Auth if changed
      if (_emailController.text != _currentUser!.email) {
        try {
          await _currentUser!.verifyBeforeUpdateEmail(_emailController.text.trim());
          updatedData['email'] = _emailController.text.trim();
        } catch (e) {
          print("Error updating email: $e");
          _showSnackBar("Email verification sent. Please check your inbox.");
        }
      }

      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update(updatedData);

      // Update display name in Firebase Auth
      await _currentUser!.updateDisplayName(_nameController.text.trim());

      setState(() {
        _userData = {..._userData, ...updatedData};
        _isEditing = false;
        _isLoading = false;
      });

      _showSnackBar("Profile updated successfully");
    } catch (e) {
      print("Error saving profile: $e");
      _showSnackBar("Failed to update profile");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers to original values
        _nameController.text = _userData['name'] ?? '';
        _phoneController.text = _userData['phone'] ?? '';
        _addressController.text = _userData['address'] ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _toggleEditMode,
              icon: Icon(_isEditing ? Icons.close : Icons.edit, color: const Color(0xFFFF5200)),
              tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5200)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                border: Border.all(color: const Color(0xFFFF5200), width: 3),
              ),
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            // User Name
            Text(
              _userData['name'] ?? 'User',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              _userData['email'] ?? '',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            // Profile Form
            _buildFormField(
              label: "Full Name",
              icon: Icons.person_outline,
              controller: _nameController,
              enabled: _isEditing,
            ),

            const SizedBox(height: 15),

            _buildFormField(
              label: "Email Address",
              icon: Icons.email_outlined,
              controller: _emailController,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 15),

            _buildFormField(
              label: "Phone Number",
              icon: Icons.phone_outlined,
              controller: _phoneController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 15),

            _buildFormField(
              label: "Delivery Address",
              icon: Icons.location_on_outlined,
              controller: _addressController,
              enabled: _isEditing,
              maxLines: 2,
            ),

            const SizedBox(height: 30),

            // Save Button (only shown in edit mode)
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    "Save Changes",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Divider
            const Divider(height: 40, thickness: 1),

            // Additional Options
            _buildOptionTile(
              icon: Icons.history_outlined,
              title: "Order History",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen(),
                  ),
                );
              },
            ),

            _buildOptionTile(
              icon: Icons.payment_outlined,
              title: "Payment Methods",
              onTap: () {
                // Navigate to payment methods screen
                _showSnackBar("Payment methods feature coming soon!");
              },
            ),

            _buildOptionTile(
              icon: Icons.notifications_outlined,
              title: "Notifications",
              onTap: () {
                // Navigate to notifications screen
                _showSnackBar("Notifications feature coming soon!");
              },
            ),

            _buildOptionTile(
              icon: Icons.help_outline,
              title: "Help & Support",
              onTap: () {
                // Navigate to help screen
                _showSnackBar("Help & support feature coming soon!");
              },
            ),

            _buildOptionTile(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              onTap: () {
                // Navigate to privacy policy
                _showSnackBar("Privacy policy feature coming soon!");
              },
            ),

            const SizedBox(height: 10),

            // Logout Button
            Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Colors.red.shade600,
                ),
                title: Text(
                  "Logout",
                  style: GoogleFonts.poppins(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: Colors.red.shade600,
                ),
                onTap: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (enabled)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: enabled ? Colors.black : Colors.grey.shade600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey.shade600,
          ),
          prefixIcon: Icon(
            icon,
            color: enabled ? const Color(0xFFFF5200) : Colors.grey.shade400,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF5200), width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFFFF5200),
          size: 24,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Logout",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          "Are you sure you want to logout?",
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                // Navigate to login screen and clear all routes
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                      (route) => false,
                );
              } catch (e) {
                print("Error logging out: $e");
                _showSnackBar("Error logging out. Please try again.");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Logout",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}