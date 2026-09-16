import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderDetailsPage extends StatelessWidget {
  final DocumentSnapshot orderDoc;

  const OrderDetailsPage({super.key, required this.orderDoc});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = orderDoc.data() as Map<String, dynamic>;
    List<dynamic> items = data['items'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${orderDoc.id.substring(0, 5)}"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Order Items Section
            const Text(
              "Order Items",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                var item = items[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                    child: Text("${item['quantity']}x", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ),
                  title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text("\$${item['price']}"),
                );
              },
            ),
            const Divider(),

            // 2. Customer Info
            const SizedBox(height: 10),
            const Text("Customer Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildRow(Icons.person, "Name", data['customerName'] ?? "Unknown"),
                  const SizedBox(height: 10),
                  _buildRow(Icons.phone, "Phone", data['customerPhone'] ?? "Unknown"),
                  const SizedBox(height: 10),
                  _buildRow(Icons.location_on, "Address", data['deliveryAddress'] ?? "Unknown"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Driver Info (If Assigned)
            if (data['driverId'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Delivery Partner", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('drivers').doc(data['driverId']).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text("Loading driver info...");
                      var driverData = snapshot.data!.data() as Map<String, dynamic>;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
                        child: Row(
                          children: [
                            const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.delivery_dining, color: Colors.white)),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(driverData['name'] ?? "Driver", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(driverData['phone'] ?? "", style: TextStyle(color: Colors.grey[700])),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        )
      ],
    );
  }
}