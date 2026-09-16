import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this to pubspec.yaml for maps

class RiderHomePage extends StatefulWidget {
  const RiderHomePage({super.key});

  @override
  State<RiderHomePage> createState() => _RiderHomePageState();
}

class _RiderHomePageState extends State<RiderHomePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _checkOnlineStatus();
  }

  // --- 1. CHECK & TOGGLE ONLINE STATUS ---
  Future<void> _checkOnlineStatus() async {
    if (currentUser == null) return;
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('drivers') // Ensure this collection exists or use 'rider_requests'
        .doc(currentUser!.uid)
        .get();

    if (doc.exists && mounted) {
      setState(() {
        _isOnline = doc.get('isOnline') ?? false;
      });
    }
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    setState(() => _isOnline = value);
    // Create/Update the driver document for real-time tracking
    await FirebaseFirestore.instance.collection('drivers').doc(currentUser!.uid).set({
      'uid': currentUser!.uid,
      'isOnline': value,
      'lastActive': FieldValue.serverTimestamp(),
      'activeOrders': 0, // Reset or keep track separately
      // In a real app, you would update Lat/Lng here using Geolocation
    }, SetOptions(merge: true));
  }

  // --- 2. ORDER ACTIONS ---
  Future<void> _updateOrderStatus(String orderId, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': status,
    });
  }

  Future<void> _openMap(String address) async {
    // Simple URL launcher for Google Maps
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$address");
    if (!await launchUrl(url)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open maps")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC), // Light Blue-Grey
      appBar: AppBar(
        title: const Text("Rider Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E88E5), // Delivery Blue
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Column(
        children: [
          // --- TOP STATUS BAR ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E88E5),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isOnline ? "You are ONLINE" : "You are OFFLINE",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _isOnline,
                  onChanged: _toggleOnlineStatus,
                  activeColor: Colors.greenAccent,
                  activeTrackColor: Colors.white24,
                  inactiveThumbColor: Colors.redAccent,
                  inactiveTrackColor: Colors.white24,
                ),
              ],
            ),
          ),

          // --- STATS CARDS ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildStatCard("Earnings", "\$120.50", Icons.attach_money),
                const SizedBox(width: 15),
                _buildStatCard("Rides", "12", Icons.two_wheeler),
              ],
            ),
          ),

          // --- ORDERS LIST HEADER ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "New Assignments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ),

          // --- ORDERS LIST ---
          Expanded(
            child: !_isOnline
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text("Go Online to receive orders", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('driverId', isEqualTo: currentUser?.uid) // Orders assigned to ME
                  .where('status', whereIn: ['ready', 'on_way']) // Only active tasks
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 60, color: Colors.green[200]),
                        const SizedBox(height: 10),
                        const Text("No active orders right now.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var orderDoc = snapshot.data!.docs[index];
                    var data = orderDoc.data() as Map<String, dynamic>;

                    return _buildOrderCard(orderDoc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: STAT CARD ---
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF1E88E5), size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: ORDER CARD ---
  Widget _buildOrderCard(String orderId, Map<String, dynamic> data) {
    String status = data['status'] ?? 'ready';
    bool isPickedUp = status == 'on_way';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isPickedUp ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Order #${orderId.substring(0, 5).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  isPickedUp ? "ON THE WAY" : "PICKUP PENDING",
                  style: TextStyle(
                    color: isPickedUp ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Pickup Location (Restaurant)
                Row(
                  children: [
                    const Icon(Icons.store, color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Pickup From", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text("Restaurant / Store", style: const TextStyle(fontWeight: FontWeight.w600)), // You can fetch real name via ID
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.map, color: Colors.blue),
                      onPressed: () => _openMap("Restaurant Location Here"), // Replace with lat/lng
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Drop Location (Customer)
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Deliver To", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(data['deliveryAddress'] ?? "Unknown Address", style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.directions, color: Colors.blue),
                      onPressed: () => _openMap(data['deliveryAddress'] ?? ""),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (!isPickedUp) {
                    // Step 1: Rider Picks up food
                    _updateOrderStatus(orderId, 'on_way');
                  } else {
                    // Step 2: Rider Delivers food (Order Complete)
                    _updateOrderStatus(orderId, 'delivered');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPickedUp ? Colors.green : const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isPickedUp ? "MARK AS DELIVERED" : "CONFIRM PICKUP",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}