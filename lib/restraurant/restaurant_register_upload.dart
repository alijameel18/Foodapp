import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RestaurantRegisterWithImage extends StatefulWidget {
  const RestaurantRegisterWithImage({super.key});

  @override
  State<RestaurantRegisterWithImage> createState() => _RestaurantRegisterWithImageState();
}

class _RestaurantRegisterWithImageState extends State<RestaurantRegisterWithImage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // State variables
  File? _selectedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // ==========================================
  // 1. CLOUDINARY CONFIGURATION
  // ==========================================
  final String cloudName = 'dd4ltmvcj';
  final String uploadPreset = 'restaurant_upload';

  // ==========================================
  // 2. LOGIC METHODS (Kept Original)
  // ==========================================
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        debugPrint("Cloudinary Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      _showError('Please upload a cover image for your restaurant.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Step A: Upload Image
      String? imageUrl = await _uploadImageToCloudinary(_selectedImage!);
      if (imageUrl == null) throw Exception("Image upload failed");

      // Step B: Create User in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user == null) throw Exception("Auth creation failed");

      // Step C: Send Verification
      await user.sendEmailVerification();

      // Step D: Save to Firestore
      await FirebaseFirestore.instance.collection('restaurant_requests').doc(user.uid).set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'imageUrl': imageUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration Successful! Please wait for Admin approval.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  // ==========================================
  // 3. NEW MODERN UI
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Stack(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          'https://images.unsplash.com/photo-1514933651103-005eec06c04b?q=80&w=1974&auto=format&fit=crop'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.6), // Dark overlay
                    padding: const EdgeInsets.only(left: 20, bottom: 50),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Become a Partner",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Fill details to list your restaurant",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- FORM SECTION (Overlapping Card) ---
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(25),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // --- IMAGE UPLOADER ---
                        const Text("Restaurant Cover Image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => _showImageSourceModal(context),
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey.shade300),
                              image: _selectedImage != null
                                  ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                                  : null,
                            ),
                            child: _selectedImage == null
                                ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 50, color: Colors.orange[300]),
                                const SizedBox(height: 8),
                                Text("Tap to upload image", style: TextStyle(color: Colors.grey[700])),
                              ],
                            )
                                : Container(
                              alignment: Alignment.topRight,
                              padding: const EdgeInsets.all(8),
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 18,
                                child: const Icon(Icons.edit, size: 18, color: Colors.orange),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // --- INPUT FIELDS ---
                        _buildLabel("Restaurant Name"),
                        _buildTextField(
                            controller: _nameController,
                            icon: Icons.store_mall_directory_outlined,
                            hint: "e.g. The Spicy Spoon"
                        ),

                        _buildLabel("Email Address"),
                        _buildTextField(
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            hint: "owner@example.com",
                            isEmail: true
                        ),

                        _buildLabel("Create Password"),
                        _buildTextField(
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            hint: "Min 6 characters",
                            isPassword: true
                        ),

                        _buildLabel("Phone Number"),
                        _buildTextField(
                            controller: _phoneController,
                            icon: Icons.phone_outlined,
                            hint: "+91 9876543210",
                            isNumber: true
                        ),

                        _buildLabel("Full Address"),
                        _buildTextField(
                            controller: _addressController,
                            icon: Icons.location_on_outlined,
                            hint: "Street, Area, City, Zip",
                            maxLines: 3
                        ),

                        const SizedBox(height: 30),

                        // --- SUBMIT BUTTON ---
                        SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isUploading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: Colors.orange.withOpacity(0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isUploading
                                ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                SizedBox(width: 15),
                                Text("Submitting...")
                              ],
                            )
                                : const Text("SUBMIT APPLICATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 15.0),
      child: Text(text, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool isEmail = false,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        maxLines: maxLines,
        keyboardType: isEmail ? TextInputType.emailAddress : (isNumber ? TextInputType.phone : TextInputType.text),
        validator: (val) => val!.isEmpty ? "This field is required" : (isPassword && val.length < 6 ? "Min 6 chars" : null),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.orange),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _showImageSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Image Source", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(Icons.photo_library, "Gallery", ImageSource.gallery),
                _buildSourceOption(Icons.camera_alt, "Camera", ImageSource.camera),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _pickImage(source);
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.orange.withOpacity(0.1),
            child: Icon(icon, size: 30, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}