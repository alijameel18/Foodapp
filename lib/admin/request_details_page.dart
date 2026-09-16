import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class RequestDetailsPage extends StatefulWidget {
  final String collectionName;
  final String docId;
  final Map<String, dynamic> data;
  final String typeLabel; // e.g. "Restaurant", "Instamart", "Rider", "Food Item"

  const RequestDetailsPage({
    super.key,
    required this.collectionName,
    required this.docId,
    required this.data,
    required this.typeLabel,
  });

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  bool _isLoading = false;

  // --- 1. DYNAMIC THEME COLOR HELPER ---
  Color get _themeColor {
    String label = widget.typeLabel.toLowerCase();
    if (label.contains('instamart')) return const Color(0xFFD81B60); // Pink
    if (label.contains('rider') || label.contains('delivery')) return const Color(0xFF1E88E5); // Blue
    return const Color(0xFFFF5200); // Orange (Restaurant/Food)
  }

  // --- 2. EMAIL FUNCTION ---
  Future<void> _sendEmailNotification(String recipientEmail, String recipientName, String status) async {
    String username = 'alijameel2325@gmail.com';
    String password = 'gicw qynv gnkg znsp';
    final smtpServer = gmail(username, password);

    String subjectText = "Update on ${widget.typeLabel} Request - FoodMart";

    // Custom body based on Approval/Rejection
    String bodyText = status == 'approved'
        ? "<h3>Congratulations $recipientName!</h3><p>Your application for <b>${widget.typeLabel}</b> has been <b>APPROVED</b>.</p><p>You can now log in to the dashboard.</p>"
        : "<h3>Hello $recipientName,</h3><p>We regret to inform you that your application for <b>${widget.typeLabel}</b> has been <b>REJECTED</b>.</p>";

    try {
      final message = Message()
        ..from = Address(username, 'FoodMart Admin')
        ..recipients.add(recipientEmail)
        ..subject = subjectText
        ..html = bodyText;
      await send(message, smtpServer);
    } catch (e) {
      debugPrint("Email error: $e");
    }
  }

  // --- 3. UPDATE STATUS ---
  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);

    // Determine email address (Food Items store it differently than Partners)
    String emailToSend = (widget.typeLabel == 'Food Item')
        ? (widget.data['restaurantEmail'] ?? '')
        : (widget.data['email'] ?? '');

    try {
      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.docId)
          .update({
        'status': newStatus,
        'adminActionDate': FieldValue.serverTimestamp(),
      });

      await _sendEmailNotification(emailToSend, widget.data['name'], newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${widget.typeLabel} $newStatus successfully!"),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
          ),
        );
        Navigator.pop(context); // Go back to list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isFoodOrProduct = widget.typeLabel == 'Food Item' || widget.typeLabel == 'Product';

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: Text("${widget.typeLabel} Details"),
        backgroundColor: _themeColor, // Dynamic Color
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HERO IMAGE ---
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                image: widget.data['imageUrl'] != null && widget.data['imageUrl'].isNotEmpty
                    ? DecorationImage(image: NetworkImage(widget.data['imageUrl']), fit: BoxFit.cover)
                    : null,
              ),
              child: widget.data['imageUrl'] == null
                  ? Icon(isFoodOrProduct ? Icons.fastfood : Icons.store, size: 60, color: Colors.grey[300])
                  : null,
            ),
            const SizedBox(height: 25),

            // --- DETAILS CARD ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  const Divider(height: 30),

                  _buildInfoTile(Icons.label, "Name", widget.data['name']),

                  if (isFoodOrProduct) ...[
                    _buildInfoTile(Icons.attach_money, "Price", "₹${widget.data['price']}"),
                    _buildInfoTile(Icons.description, "Description", widget.data['description']),
                    _buildInfoTile(Icons.store, "Store/Restaurant", widget.data['restaurantName']),
                  ] else ...[
                    _buildInfoTile(Icons.email, "Email", widget.data['email']),
                    _buildInfoTile(Icons.phone, "Phone", widget.data['phone']),
                    _buildInfoTile(Icons.location_on, "Address", widget.data['address']),
                    if (widget.typeLabel == 'Rider')
                      _buildInfoTile(Icons.badge, "UID", widget.docId),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- ACTION BUTTONS ---
            if (_isLoading)
              Center(child: CircularProgressIndicator(color: _themeColor))
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus('rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus('approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      child: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGET ---
  Widget _buildInfoTile(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _themeColor.withOpacity(0.1), // Uses dynamic theme color
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _themeColor, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value ?? "N/A",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}