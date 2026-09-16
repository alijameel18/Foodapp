import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Order History", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: user != null
            ? FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
        // Temporarily remove orderBy while index is building
        // .orderBy('createdAt', descending: true)
            .snapshots()
            : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 10),
                  Text("Error loading orders", style: GoogleFonts.poppins(color: Colors.red)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: Text("Retry", style: GoogleFonts.poppins()),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text("No orders yet", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 18)),
                  const SizedBox(height: 10),
                  Text("Your orders will appear here", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          // Client-side sorting as temporary workaround
          var docs = snapshot.data!.docs;
          docs.sort((a, b) {
            var aDate = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            var bDate = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            return bDate?.compareTo(aDate ?? Timestamp.now()) ?? 0;
          });

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var order = docs[index];
              var data = order.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Order #${order.id.substring(0, 8)}",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(data['status'] ?? 'pending'),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (data['status'] ?? 'pending').toUpperCase(),
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "${data['type'] == 'food' ? 'Food Delivery' : 'Grocery'} Order",
                      style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          _formatDate(data['createdAt']),
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Items summary
                    if (data['items'] != null && (data['items'] as List).isNotEmpty)
                      Text(
                        "${(data['items'] as List).length} items • ₹${data['total'].toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                      ),

                    const SizedBox(height: 10),

                    // View details button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF5200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFFF5200), width: 1),
                          ),
                        ),
                        onPressed: () {
                          _showOrderDetails(data, order.id);
                        },
                        child: Text("View Details", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'preparing':
        return Colors.orange;
      case 'on the way':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Date not available";
    DateTime date = timestamp.toDate();
    String minute = date.minute.toString().padLeft(2, '0');
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour}:$minute";
  }

  void _showOrderDetails(Map<String, dynamic> order, String orderId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Order Details", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const Divider(),
              const SizedBox(height: 10),

              Text("Order ID: ${orderId.substring(0, 12)}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),

              const SizedBox(height: 20),

              // Order Items
              Expanded(
                child: ListView.builder(
                  itemCount: (order['items'] as List).length,
                  itemBuilder: (context, index) {
                    var item = order['items'][index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 5),
                                Text("Qty: ${item['quantity']} × ₹${item['price']}", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text("₹${(item['price'] * item['quantity']).toStringAsFixed(2)}",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Order Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Subtotal", style: GoogleFonts.poppins(color: Colors.grey)),
                        Text("₹${order['total'].toStringAsFixed(2)}", style: GoogleFonts.poppins()),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Delivery Fee", style: GoogleFonts.poppins(color: Colors.grey)),
                        Text("₹${order['deliveryFee']?.toStringAsFixed(2) ?? '0.00'}", style: GoogleFonts.poppins()),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tax", style: GoogleFonts.poppins(color: Colors.grey)),
                        Text("₹${order['tax']?.toStringAsFixed(2) ?? '0.00'}", style: GoogleFonts.poppins()),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // Total
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Amount", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("₹${order['total'].toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFFF5200))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}