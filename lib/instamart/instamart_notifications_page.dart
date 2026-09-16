import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InstamartNotificationsPage extends StatelessWidget {
  const InstamartNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFFE91E63), // Pink Theme
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('instafood_items')
            .where('restaurantId', isEqualTo: user?.uid)
        // Filter: Show only processed items (not pending)
            .where('status', whereIn: ['approved', 'rejected'])
        // Note: You might need to create a Firestore Index for this query to work with orderBy
        // If it crashes, remove .orderBy or create the index in Firebase Console
        // .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.pink));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text("No notifications yet", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String status = data['status'] ?? 'unknown';
              String name = data['name'] ?? 'Product';
              bool isApproved = status == 'approved';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isApproved ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  child: Icon(
                    isApproved ? Icons.check_circle : Icons.cancel,
                    color: isApproved ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  isApproved ? "Product Approved" : "Product Rejected",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isApproved
                      ? "Your product '$name' is now live in the store."
                      : "Your product '$name' was rejected by Admin.",
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: data['imageUrl'] != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(data['imageUrl'], width: 40, height: 40, fit: BoxFit.cover),
                )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}