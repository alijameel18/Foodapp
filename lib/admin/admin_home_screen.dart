import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../services/auth_admin_services.dart';
import 'request_details_page.dart'; // Ensure this file exists

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final AuthServiceAdmin _authService = AuthServiceAdmin();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- NAVIGATION STATE ---
  int _selectedIndex = 0; // 0: Dashboard, 1: Restaurants, 2: Instamart, 3: Riders, 4: Orders
  String _pageTitle = "Admin Dashboard";

  // --- COLORS ---
  final Color kPrimaryColor = const Color(0xFFFF5200);
  final Color kBackgroundColor = const Color(0xFFF4F6F8);
  final Color kTextDark = const Color(0xFF1A1D26);
  final Color kTextGrey = const Color(0xFFA0AEC0);
  final Color kSuccessColor = const Color(0xFF48BB78);

  // ==========================================
  // 1. NAVIGATION LOGIC
  // ==========================================
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0: _pageTitle = "Admin Dashboard"; break;
        case 1: _pageTitle = "All Restaurants"; break;
        case 2: _pageTitle = "All Instamart Stores"; break;
        case 3: _pageTitle = "Delivery Partners"; break;
        case 4: _pageTitle = "Recent Orders"; break;
      }
    });
    // Close drawer if open
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      Navigator.pop(context);
    }
  }

  // ==========================================
  // 2. EMAIL & UPDATE LOGIC (For Dashboard)
  // ==========================================
  Future<void> _sendEmailNotification(String recipientEmail, String recipientName, String status, String type) async {
    String username = 'alijameel2325@gmail.com';
    String password = 'gicw qynv gnkg znsp';
    final smtpServer = gmail(username, password);

    String subjectText = "Update on $type - FoodMart";
    String bodyText = status == 'approved'
        ? "<h3>Hello $recipientName,</h3><p>Your $type application is <b>APPROVED</b>.</p>"
        : "<h3>Hello $recipientName,</h3><p>Your $type application was <b>REJECTED</b>.</p>";

    try {
      final message = Message()..from = Address(username, 'FoodMart Admin')..recipients.add(recipientEmail)..subject = subjectText..html = bodyText;
      await send(message, smtpServer);
    } catch (e) {
      debugPrint("Email error: $e");
    }
  }

  Future<void> _updateStatus(String collectionName, String docId, String newStatus, String email, String name, String type) async {
    try {
      await FirebaseFirestore.instance.collection(collectionName).doc(docId).update({
        'status': newStatus,
        'adminActionDate': FieldValue.serverTimestamp(),
      });
      await _sendEmailNotification(email, name, newStatus, type);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$type $newStatus!"), backgroundColor: kSuccessColor));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout(context);
  }

  // ==========================================
  // 3. MAIN SCAFFOLD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBackgroundColor,

      // --- APP BAR ---
      appBar: AppBar(
        title: Text(_pageTitle, style: TextStyle(color: kTextDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: kTextDark),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(onPressed: _handleLogout, icon: const Icon(Icons.logout, color: Colors.red)),
        ],
      ),

      // --- SIDEBAR DRAWER ---
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1D26),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              color: Colors.black26,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 30, backgroundColor: Colors.white24, child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 30)),
                  SizedBox(height: 15),
                  Text("Admin Portal", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _buildDrawerItem(0, "Dashboard", Icons.dashboard),
            _buildDrawerItem(1, "Restaurants", Icons.store),
            _buildDrawerItem(2, "Instamart", Icons.shopping_basket),
            _buildDrawerItem(3, "Riders", Icons.two_wheeler),
            _buildDrawerItem(4, "Orders", Icons.receipt_long),
          ],
        ),
      ),

      // --- BODY SWITCHER ---
      body: _buildBody(),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? kPrimaryColor : Colors.white70),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      tileColor: isSelected ? Colors.white.withOpacity(0.05) : null,
      onTap: () => _onItemTapped(index),
    );
  }

  // --- VIEW CONTROLLER ---
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildDashboardView(); // The Main Dashboard
      case 1: return _buildDataView('restaurant_requests', 'approved', Icons.store);
      case 2: return _buildDataView('instamart_requests', 'approved', Icons.shopping_basket);
      case 3: return _buildDataView('rider_requests', 'approved', Icons.two_wheeler);
      case 4: return _buildOrderListView();
      default: return const Center(child: Text("Error"));
    }
  }

  // ==========================================
  // VIEW 1: DASHBOARD (Stats + Pending)
  // ==========================================
  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 15),

          // CLICKABLE STAT CARDS
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard("Total Restaurants", Icons.store, Colors.orange, 'restaurant_requests', 1),
              _buildStatCard("Total Instamart", Icons.shopping_basket, Colors.pink, 'instamart_requests', 2),
              _buildStatCard("Total Riders", Icons.two_wheeler, Colors.blue, 'rider_requests', 3),
              _buildStatCard("Total Orders", Icons.receipt, Colors.green, 'orders', 4),
            ],
          ),

          const SizedBox(height: 30),
          const Divider(thickness: 2),
          const SizedBox(height: 20),

          // PENDING APPROVALS LISTS
          _buildSectionHeader("Pending Restaurants", Icons.restaurant),
          _buildRequestSection(collectionName: 'restaurant_requests', typeLabel: 'Restaurant'),

          const SizedBox(height: 30),
          _buildSectionHeader("Pending Instamart", Icons.storefront),
          _buildRequestSection(collectionName: 'instamart_requests', typeLabel: 'Instamart'),

          const SizedBox(height: 30),
          _buildSectionHeader("Pending Riders", Icons.motorcycle),
          _buildRequestSection(collectionName: 'rider_requests', typeLabel: 'Rider'),

          const SizedBox(height: 30),
          _buildSectionHeader("Menu & Product Approvals", Icons.fastfood),
          _buildFoodItemSection(),

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 2: GENERIC DATA VIEW (Restaurants/Riders/Instamart)
  // ==========================================
  Widget _buildDataView(String collection, String status, IconData icon) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).where('status', isEqualTo: status).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No Data Found"));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_,__) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (data['imageUrl'] != null) ? NetworkImage(data['imageUrl']) : null,
                  child: data['imageUrl'] == null ? Icon(icon, color: Colors.grey) : null,
                ),
                title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['address'] ?? 'No Address'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // VIEW 3: ORDERS VIEW
  // ==========================================
  Widget _buildOrderListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_,__) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.receipt, color: Colors.green)),
                title: Text("Order \$${data['totalPrice']}", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Status: ${data['status']?.toUpperCase()}"),
              ),
            );
          },
        );
      },
    );
  }

  // --- HELPERS FOR DASHBOARD ---

  Widget _buildStatCard(String title, IconData icon, Color color, String collection, int targetIndex) {
    return GestureDetector(
      onTap: () => _onItemTapped(targetIndex), // Switch View on Click
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (context, snapshot) {
          String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [Icon(icon, color: color, size: 24), const Spacer(), Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextDark))]),
                const SizedBox(height: 8),
                Text(title, style: TextStyle(fontSize: 13, color: kTextGrey, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [Icon(icon, size: 20, color: kTextDark), const SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark))]),
    );
  }

  Widget _buildRequestSection({required String collectionName, required String typeLabel}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState("No pending requests.");
        return ListView.separated(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return _buildCard(context, doc, data, collectionName, typeLabel, false);
          },
        );
      },
    );
  }

  Widget _buildFoodItemSection() {
    return StreamBuilder<QuerySnapshot>(
      // 1. Stream from Restaurant Food Items
      stream: FirebaseFirestore.instance
          .collection('restautfood_items')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, foodSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          // 2. Stream from Instamart Grocery Items
          stream: FirebaseFirestore.instance
              .collection('instamartfood_items')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, instaSnapshot) {

            // Loading State
            if (foodSnapshot.connectionState == ConnectionState.waiting &&
                instaSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Get documents from both collections
            final foodDocs = foodSnapshot.hasData ? foodSnapshot.data!.docs : [];
            final instaDocs = instaSnapshot.hasData ? instaSnapshot.data!.docs : [];

            // Combine them into one list
            final allDocs = [...foodDocs, ...instaDocs];

            if (allDocs.isEmpty) return _buildEmptyState("No pending items.");

            // Optional: Sort by time (Newest first)
            // allDocs.sort((a, b) {
            //   Timestamp t1 = (a.data() as Map)['createdAt'] ?? Timestamp.now();
            //   Timestamp t2 = (b.data() as Map)['createdAt'] ?? Timestamp.now();
            //   return t2.compareTo(t1);
            // });

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allDocs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                var doc = allDocs[index];
                var data = doc.data() as Map<String, dynamic>;

                // 3. Identify which collection this document belongs to
                // We use doc.reference.parent.id to get the collection name accurately
                String collectionName = doc.reference.parent.id;

                // 4. Determine Type & Normalize Data for Display
                String type;
                String vendorName; // To handle restaurantName vs instamartName

                if (collectionName == 'instamartfood_items') {
                  type = 'Grocery Product';
                  // Use 'instamartName' from your screenshot
                  vendorName = data['instamartName'] ?? 'Unknown Mart';
                } else {
                  type = 'Food Item';
                  // Use 'restaurantName' from your screenshot
                  vendorName = data['restaurantName'] ?? 'Unknown Restaurant';
                }

                // Inject the normalized vendor name into data so _buildCard can use it easily
                // (Optional, depends on how your _buildCard is written)
                data['displayVendor'] = vendorName;

                // 5. Pass the specific collection name so Approve/Delete works correctly
                return _buildCard(context, doc, data, collectionName, type, true);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: Center(child: Text(text, style: TextStyle(color: kTextGrey))));
  }

  Widget _buildCard(BuildContext context, DocumentSnapshot doc, Map<String, dynamic> data, String collection, String typeLabel, bool isItem) {
    String name = data['name'] ?? 'Unknown';
    String subText = isItem ? "Price: ₹${data['price']}" : (data['address'] ?? 'No Address');
    String email = isItem ? (data['restaurantEmail'] ?? '') : (data['email'] ?? '');
    String? imageUrl = data['imageUrl'];

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => RequestDetailsPage(collectionName: collection, docId: doc.id, data: data, typeLabel: typeLabel))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
        child: Row(
          children: [
            Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null), child: imageUrl == null ? Icon(Icons.store, color: Colors.grey) : null),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)), Text(subText, style: TextStyle(fontSize: 12, color: kTextGrey))])),
            Row(children: [
              IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _updateStatus(collection, doc.id, 'rejected', email, name, typeLabel)),
              IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _updateStatus(collection, doc.id, 'approved', email, name, typeLabel)),
            ])
          ],
        ),
      ),
    );
  }
}