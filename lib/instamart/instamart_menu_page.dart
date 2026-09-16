import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class InstamartMenuPage extends StatefulWidget {
  const InstamartMenuPage({super.key});

  @override
  State<InstamartMenuPage> createState() => _InstamartMenuPageState();
}

class _InstamartMenuPageState extends State<InstamartMenuPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // State
  File? _selectedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // --- THEME COLOR ---
  final Color themeColor = const Color(0xFFE91E63); // Pink

  // --- CLOUDINARY CONFIG ---
  final String cloudName = 'dd4ltmvcj';
  final String uploadPreset = 'restaurant_upload'; // Reusing preset is fine

  // ==========================================
  // 1. IMAGE & UPLOAD LOGIC
  // ==========================================
  Future<void> _pickImage(StateSetter setDialogState) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
      if (pickedFile != null) {
        setDialogState(() => _selectedImage = File(pickedFile.path));
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
        final jsonMap = jsonDecode(String.fromCharCodes(responseData));
        return jsonMap['secure_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // 2. CRUD OPERATIONS
  // ==========================================

  // --- SAVE ITEM ---
  Future<void> _saveItem({String? docId, String? currentImageUrl, required StateSetter setDialogState}) async {
    if (!_formKey.currentState!.validate()) return;
    if (docId == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a product image.')));
      return;
    }

    setDialogState(() => _isUploading = true);

    try {
      String imageUrl = currentImageUrl ?? '';

      // Upload new image if selected
      if (_selectedImage != null) {
        String? newUrl = await _uploadImageToCloudinary(_selectedImage!);
        if (newUrl == null) throw Exception("Image upload failed");
        imageUrl = newUrl;
      }

      // Fetch Store Details from 'instamart_requests'
      DocumentSnapshot storeDoc = await FirebaseFirestore.instance.collection('instamart_requests').doc(currentUser!.uid).get();
      String storeName = storeDoc.get('name') ?? 'Instamart Store';
      String storeEmail = storeDoc.get('email') ?? currentUser!.email;

      Map<String, dynamic> itemData = {
        'instamartId': currentUser!.uid, // Using generic ID field for consistency with Admin
        'instamartName': storeName,      // Mapped to restaurantName so Admin panel works
        'instamartEmail': storeEmail,
        'itemType': 'grocery',            // Tag to distinguish from food
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'description': _descController.text.trim(),
        'imageUrl': imageUrl,
        'status': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (docId == null) {
        // ADD NEW
        itemData['createdAt'] = FieldValue.serverTimestamp();
        // Saving to 'food_items' so it shows up in your existing Admin Panel
        await FirebaseFirestore.instance.collection('instamartfood_items').add(itemData);
      } else {
        // EDIT EXISTING
        await FirebaseFirestore.instance.collection('instamartfood_items').doc(docId).update(itemData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(docId == null ? "Product Added! Sent to Admin." : "Product Updated! Sent to Admin."),
          backgroundColor: Colors.green,
        ));
        _clearControllers();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        try { setDialogState(() => _isUploading = false); } catch (_) {}
      }
    }
  }

  // --- DELETE ITEM ---
  Future<void> _deleteItem(String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('instamartfood_items').doc(docId).delete();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Deleted"), backgroundColor: Colors.red));
      }
    }
  }

  void _clearControllers() {
    _nameController.clear();
    _priceController.clear();
    _descController.clear();
    setState(() => _selectedImage = null);
  }

  // ==========================================
  // 3. DIALOG UI
  // ==========================================
  void _showItemDialog({String? docId, Map<String, dynamic>? data}) {
    if (docId != null && data != null) {
      _nameController.text = data['name'];
      _priceController.text = data['price'].toString();
      _descController.text = data['description'];
    } else {
      _clearControllers();
    }
    _selectedImage = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(docId == null ? "Add Product" : "Edit Product"),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _pickImage(setDialogState),
                        child: Container(
                          height: 150, width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                            image: _selectedImage != null
                                ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                                : (docId != null && data!['imageUrl'] != null
                                ? DecorationImage(image: NetworkImage(data['imageUrl']), fit: BoxFit.cover)
                                : null),
                          ),
                          child: (_selectedImage == null && (docId == null || data!['imageUrl'] == null))
                              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: themeColor.withOpacity(0.5)), const Text("Tap to add Image", style: TextStyle(color: Colors.grey))])
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Required" : null),
                      const SizedBox(height: 10),
                      TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: "Price", border: OutlineInputBorder(), prefixText: "\$ "), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? "Required" : null),
                      const SizedBox(height: 10),
                      TextFormField(controller: _descController, decoration: const InputDecoration(labelText: "Description (e.g. Weight, Brand)", border: OutlineInputBorder()), maxLines: 2),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: _isUploading ? null : () => _saveItem(docId: docId, currentImageUrl: data?['imageUrl'], setDialogState: setDialogState),
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                  child: _isUploading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(docId == null ? "Add" : "Update", style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 4. MAIN BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Inventory"), backgroundColor: themeColor),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(),
        label: const Text("Add Product"),
        icon: const Icon(Icons.add),
        backgroundColor: themeColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('instamartfood_items')
            .where('instamartId', isEqualTo: currentUser?.uid) // Fetches this user's items
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No products added yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(image: NetworkImage(data['imageUrl']), fit: BoxFit.cover),
                      color: Colors.grey[200],
                    ),
                  ),
                  title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("\$${data['price']} • ${data['description']}"),
                      Text(status.toUpperCase(), style: TextStyle(color: status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showItemDialog(docId: doc.id, data: data)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteItem(doc.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}