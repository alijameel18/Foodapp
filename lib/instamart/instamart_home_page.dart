import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- IMPORTS ---
import '../restraurant/order_details_page.dart';
import 'instamart_menu_page.dart';

class InstamartHomePage extends StatefulWidget {
  const InstamartHomePage({super.key});

  @override
  State<InstamartHomePage> createState() => _InstamartHomePageState();
}

class _InstamartHomePageState extends State<InstamartHomePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final Color themeColor = const Color(0xFFE91E63); // Pink

  // ==========================================
  // 1. MARK NOTIFICATIONS AS READ
  // ==========================================
  Future<void> _markNotificationsAsRead() async {
    if (currentUser == null) return;

    // Get all documents that are approved/rejected but NOT read yet
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('instamartfood_items')
        .where('instamartId', isEqualTo: currentUser!.uid)
        .where('status', whereIn: ['approved', 'rejected'])
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();
    bool needsUpdate = false;

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      // If 'isRead' is missing or false, update it
      if (data['isRead'] != true) {
        batch.update(doc.reference, {'isRead': true});
        needsUpdate = true;
      }
    }

    if (needsUpdate) {
      await batch.commit(); // Update all at once
      debugPrint("Notifications marked as read.");
    }
  }

// ==========================================
  // 2. MODERN NOTIFICATION POPUP
  // ==========================================
  void _showNotificationPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Transparent to show rounded corners
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75, // Taller popup
          decoration: const BoxDecoration(
            color: Color(0xFFF5F7FA), // Light Grey Background
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // --- Custom Header ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: Color(0xFFE91E63)),
                        const SizedBox(width: 10),
                        const Text(
                          "Updates",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),

              // --- Notification List ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('instamartfood_items')
                      .where('instamartId', isEqualTo: currentUser?.uid)
                      .where('status', whereIn: ['approved', 'rejected'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 15),
                            Text("You're all caught up!", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                        String status = data['status'] ?? 'unknown';
                        String name = data['name'] ?? 'Product';
                        String? imageUrl = data['imageUrl'];
                        bool isApproved = status == 'approved';

                        // --- MODERN CARD DESIGN ---
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                            border: Border.all(
                                color: isApproved ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                width: 1.5
                            ),
                          ),
                          child: Row(
                            children: [
                              // 1. Product Image or Status Icon
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  image: imageUrl != null && imageUrl.isNotEmpty
                                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: imageUrl == null || imageUrl.isEmpty
                                    ? Icon(
                                  isApproved ? Icons.check_circle : Icons.cancel,
                                  color: isApproved ? Colors.green : Colors.red,
                                )
                                    : null,
                              ),

                              const SizedBox(width: 15),

                              // 2. Text Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          isApproved ? "Request Approved" : "Request Rejected",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isApproved ? Colors.green[700] : Colors.red[700],
                                          ),
                                        ),
                                        // Optional: Add a 'New' badge if unread
                                        if (data['isRead'] != true)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                            child: const Text("NEW", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                          )
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isApproved
                                          ? "'$name' is now live in your store."
                                          : "'$name' violated our policies.",
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),

                              // 3. Status Icon on the far right
                              Icon(
                                isApproved ? Icons.check_circle_outline : Icons.highlight_off,
                                color: isApproved ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4),
                                size: 28,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // Mark as read when the popup closes
      _markNotificationsAsRead();
    });
  }

  // --- ORDER LOGIC ---
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _assignDriver(String orderId) async {
    // ... Keep your existing driver assignment logic ...
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Driver assigned successfully!"), backgroundColor: Colors.green));
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': newStatus});
  }

  // ==========================================
  // 3. UI BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Instamart Dashboard"),
        backgroundColor: themeColor,
        actions: [

          // --- SMART NOTIFICATION BELL ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('instamartfood_items')
                .where('instamartId', isEqualTo: currentUser?.uid)
                .where('status', whereIn: ['approved', 'rejected'])
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;

              // Calculate Unread Count locally
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (data['isRead'] != true) {
                    unreadCount++;
                  }
                }
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: _showNotificationPopup, // Opens popup & clears count
                  ),

                  // NUMBER BADGE (Only shows if count > 0)
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Center(
                          child: Text(
                            "$unreadCount", // Shows 1, 2, 3...
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // ---------------------------------

          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: "Manage Inventory",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InstamartMenuPage())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text("Active Orders", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            _buildActiveOrdersList(),

            const Divider(thickness: 2),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text("Store Inventory (Live)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            _buildApprovedInventoryList(),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS (Unchanged) ---

  Widget _buildActiveOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('storeId', isEqualTo: currentUser?.uid)
          .where('status', whereIn: ['placed', 'preparing', 'ready', 'on_way'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No Active Orders")));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var orderDoc = snapshot.data!.docs[index];
            var order = orderDoc.data() as Map<String, dynamic>;
            String status = order['status'] ?? 'placed';

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Order #${orderDoc.id.substring(0, 5).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const Divider(),
                    Text("${(order['items'] as List).length} Items • Total: \$${order['totalPrice']}", style: TextStyle(color: Colors.grey[700], fontSize: 15)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailsPage(orderDoc: orderDoc))), child: const Text("View Details"))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildActionButton(status, orderDoc.id)),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildApprovedInventoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('instamartfood_items')
          .where('instamartId', isEqualTo: currentUser?.uid)
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No products live yet.")));

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        image: DecorationImage(image: NetworkImage(data['imageUrl'] ?? ''), fit: BoxFit.cover, onError: (_,__) => {}),
                        color: Colors.grey[200],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text("\$${data['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'placed': color = Colors.blue; break;
      case 'preparing': color = Colors.orange; break;
      case 'ready': color = Colors.purple; break;
      case 'on_way': color = Colors.green; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildActionButton(String status, String orderId) {
    switch (status) {
      case 'placed': return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: themeColor), onPressed: () => _updateOrderStatus(orderId, 'preparing'), child: const Text("Start Packing", style: TextStyle(color: Colors.white)));
      case 'preparing': return ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), icon: const Icon(Icons.check_circle, color: Colors.white), label: const Text("Order Packed", style: TextStyle(color: Colors.white)), onPressed: () => _assignDriver(orderId));
      case 'ready': return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.grey), onPressed: null, child: const Text("Waiting for Driver...", style: TextStyle(color: Colors.white)));
      case 'on_way': return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), onPressed: () => _updateOrderStatus(orderId, 'delivering'), child: const Text("Handover Order", style: TextStyle(color: Colors.white)));
      default: return const SizedBox();
    }
  }
}