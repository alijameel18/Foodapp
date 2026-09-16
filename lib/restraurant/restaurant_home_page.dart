import 'dart:async'; // Required for StreamSubscription
import 'dart:math' show cos, sqrt, asin;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- IMPORTS ---
import 'order_details_page.dart';
import 'restaurant_menu_page.dart';

class RestaurantHomePage extends StatefulWidget {
  const RestaurantHomePage({super.key});

  @override
  State<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends State<RestaurantHomePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Notification Listener Variable
  StreamSubscription? _itemStatusSubscription;

  @override
  void initState() {
    super.initState();
    // Start listening for real-time notifications (SnackBar)
    _listenForItemUpdates();
  }

  @override
  void dispose() {
    _itemStatusSubscription?.cancel(); // Clean up listener
    super.dispose();
  }

  // ==========================================
  // 1. REAL-TIME SNACKBAR LISTENER
  // ==========================================
  void _listenForItemUpdates() {
    if (currentUser == null) return;

    _itemStatusSubscription = FirebaseFirestore.instance
        .collection('restautfood_items')
        .where('restaurantId', isEqualTo: currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          var data = change.doc.data() as Map<String, dynamic>;
          String itemName = data['name'] ?? 'Item';
          String newStatus = data['status'] ?? 'pending';

          if (newStatus == 'approved') {
            _showSnackBar("✅ Approved: '$itemName' is live!");
          } else if (newStatus == 'rejected') {
            _showSnackBar("❌ Rejected: '$itemName' was declined.");
          }
        }
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: message.contains("Approved") ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ==========================================
  // 2. MARK AS READ LOGIC
  // ==========================================
  Future<void> _markNotificationsAsRead() async {
    if (currentUser == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('restautfood_items')
        .where('restaurantId', isEqualTo: currentUser!.uid)
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
      await batch.commit();
      debugPrint("Notifications marked as read.");
    }
  }

  // ==========================================
  // 3. NOTIFICATION POPUP (MODERN UI)
  // ==========================================
  void _showNotificationPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F7FA), // Light Grey Background
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications_active_rounded, color: Colors.orange),
                        SizedBox(width: 10),
                        Text(
                          "Updates",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),

              // List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('restautfood_items')
                      .where('restaurantId', isEqualTo: currentUser?.uid)
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
                            const Text("No notifications yet", style: TextStyle(color: Colors.grey)),
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
                        String name = data['name'] ?? 'Item';
                        String? imageUrl = data['imageUrl'];
                        bool isApproved = status == 'approved';
                        bool isRead = data['isRead'] == true;

                        // Modern Card UI
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                            border: Border.all(
                              color: isApproved ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  image: imageUrl != null
                                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: imageUrl == null
                                    ? Icon(
                                  isApproved ? Icons.check_circle : Icons.cancel,
                                  color: isApproved ? Colors.green : Colors.red,
                                )
                                    : null,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          isApproved ? "Approved" : "Rejected",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isApproved ? Colors.green[700] : Colors.red[700],
                                          ),
                                        ),
                                        // NEW BADGE logic
                                        if (!isRead)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              "NEW",
                                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                            ),
                                          )
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isApproved ? "'$name' is now live." : "'$name' violated policies.",
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                  ],
                                ),
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
      // Mark notifications as read when popup closes
      _markNotificationsAsRead();
    });
  }

  // --- EXISTING LOGIC (Distance, Driver, Status) ---
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _assignDriver(String orderId) async {
    // ... (Your Existing Driver Assignment Code) ...
    // Placeholder for brevity:
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Driver assigned successfully!"), backgroundColor: Colors.green));
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': newStatus});
  }

  // ==========================================
  // 4. MAIN BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chef Dashboard"),
        backgroundColor: Colors.orange,
        actions: [
          // --- SMART NOTIFICATION BELL ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('restautfood_items')
                .where('restaurantId', isEqualTo: currentUser?.uid)
                .where('status', whereIn: ['approved', 'rejected'])
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  // Count items where isRead is not true
                  if ((doc.data() as Map<String, dynamic>)['isRead'] != true) {
                    unreadCount++;
                  }
                }
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: _showNotificationPopup, // Opens popup
                  ),
                  // RED DOT BADGE
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
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "$unreadCount",
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // ------------------------------



          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: "Manage Menu",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RestaurantMenuPage())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Active Orders", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            _buildActiveOrdersList(),
            const Divider(thickness: 2),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("My Live Menu", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            _buildApprovedMenuList(),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS (Active Orders & Menu) ---
  Widget _buildActiveOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('restaurantId', isEqualTo: currentUser?.uid)
          .where('status', whereIn: ['placed', 'preparing', 'ready', 'on_way'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No Active Orders")));
        }
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Order #${orderDoc.id.substring(0, 5)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        _buildStatusBadge(status)
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => OrderDetailsPage(orderDoc: orderDoc))),
                            child: const Text("View Details"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _buildActionButton(status, orderDoc.id))
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

  Widget _buildApprovedMenuList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restautfood_items')
          .where('restaurantId', isEqualTo: currentUser?.uid)
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No items in menu.")));
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              child: Column(
                children: [
                  Expanded(
                    child: Image.network(
                      data['imageUrl'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("\$${data['price']}", style: const TextStyle(color: Colors.green)),
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

  Widget _buildStatusBadge(String status) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
    child: Text(status.toUpperCase()),
  );

  Widget _buildActionButton(String status, String orderId) {
    switch (status) {
      case 'placed':
        return ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () => _updateOrderStatus(orderId, 'preparing'),
          child: const Text("Start Cooking"),
        );
      case 'preparing':
        return ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => _assignDriver(orderId),
          child: const Text("Food Ready"),
        );
      default:
        return const SizedBox();
    }
  }
}