import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RestaurantNotificationsPage extends StatefulWidget {
  const RestaurantNotificationsPage({super.key});

  @override
  State<RestaurantNotificationsPage> createState() => _RestaurantNotificationsPageState();
}

class _RestaurantNotificationsPageState extends State<RestaurantNotificationsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Automatically mark notifications as read when this page opens
    _markNotificationsAsRead();
  }

  // --- LOGIC: MARK AS READ ---
  Future<void> _markNotificationsAsRead() async {
    if (currentUser == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('food_items')
        .where('restaurantId', isEqualTo: currentUser!.uid)
        .where('status', whereIn: ['approved', 'rejected'])
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();
    bool needsUpdate = false;

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      // If isRead is missing or false, update it
      if (data['isRead'] != true) {
        batch.update(doc.reference, {'isRead': true});
        needsUpdate = true;
      }
    }

    if (needsUpdate) {
      await batch.commit();
      debugPrint("All notifications marked as read.");
    }
  }

  // ==========================================
  // UI BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light Grey Background
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange, // Restaurant Theme
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('food_items')
            .where('restaurantId', isEqualTo: currentUser?.uid)
            .where('status', whereIn: ['approved', 'rejected'])
        // Optional: Add .orderBy('updatedAt', descending: true) if you have created the index
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          // 2. Empty State
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 15),
                  const Text("No notifications yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          // 3. List Data
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

              String status = data['status'] ?? 'unknown';
              String name = data['name'] ?? 'Menu Item';
              String? imageUrl = data['imageUrl'];
              bool isApproved = status == 'approved';

              // --- CARD DESIGN ---
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                  border: Border(
                    left: BorderSide(
                      color: isApproved ? Colors.green : Colors.red,
                      width: 4,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Item Image
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        image: imageUrl != null && imageUrl.isNotEmpty
                            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: imageUrl == null || imageUrl.isEmpty
                          ? Icon(Icons.fastfood, color: Colors.grey[400])
                          : null,
                    ),
                    const SizedBox(width: 15),

                    // Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isApproved ? "Request Approved" : "Request Rejected",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isApproved ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isApproved
                                ? "'$name' is now visible to customers."
                                : "'$name' was rejected by Admin.",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    // Status Icon
                    Icon(
                      isApproved ? Icons.check_circle_outline : Icons.highlight_off,
                      color: isApproved ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                      size: 24,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}