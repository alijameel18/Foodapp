import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_customer_service.dart';
import 'ProfileScreen.dart';
import 'customer_login_screen.dart';
import 'order_history_screen.dart';

// ==============================================================================
// 1. FOOD DELIVERY SCREEN (Updated with Products and Cart)
// ==============================================================================
class FoodDeliveryScreen extends StatefulWidget {
  const FoodDeliveryScreen({super.key});

  @override
  State<FoodDeliveryScreen> createState() => _FoodDeliveryScreenState();
}

class _FoodDeliveryScreenState extends State<FoodDeliveryScreen> {
  // State to track selected restaurant
  String? _selectedRestaurantId;
  String _selectedRestaurantName = "All Restaurants";
  String _deliveryAddress = "Loading address...";

  // Cart Data
  final List<Map<String, dynamic>> _cartItems = [];
  double _cartTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUserAddress();
  }

  Future<void> _fetchUserAddress() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _deliveryAddress = doc['address'] ?? "No address set";
        });
      }
    }
  }

  void _addToCart(Map<String, dynamic> product, String restaurantName) {
    setState(() {
      int index = _cartItems.indexWhere((item) => item["id"] == product["id"]);
      if (index != -1) {
        _cartItems[index]["quantity"] = (_cartItems[index]["quantity"] ?? 1) + 1;
      } else {
        _cartItems.add({
          ...product,
          "quantity": 1,
          "restaurant": restaurantName
        });
      }
      _calculateTotal();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${product["name"]} added"), duration: const Duration(milliseconds: 500)));
  }

  void _updateQuantity(String productId, int quantity) {
    setState(() {
      int index = _cartItems.indexWhere((item) => item["id"] == productId);
      if (index != -1) {
        if (quantity <= 0) {
          _cartItems.removeAt(index);
        } else {
          _cartItems[index]["quantity"] = quantity;
        }
        _calculateTotal();
      }
    });
  }

  void _calculateTotal() {
    double total = 0;
    for (var item in _cartItems) {
      total += (item["price"] * (item["quantity"] ?? 1));
    }
    setState(() => _cartTotal = total);
  }

  void _checkout() async {
    if (_cartItems.isEmpty) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Order", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total: ₹${_cartTotal.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFFF5200))),
            const SizedBox(height: 10),
            Text("Delivery Address:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            Text(_deliveryAddress, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5200)),
            child: const Text("Place Order"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('orders').add({
          'userId': user.uid,
          'userEmail': user.email,
          'items': _cartItems,
          'total': _cartTotal,
          'status': 'pending',
          'type': 'food',
          'address': _deliveryAddress,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      setState(() { _cartItems.clear(); _cartTotal = 0.0; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Placed Successfully!"), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Food Delivery", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // ✅ SINGLE STREAM: Fetches from 'restautfood_items' directly
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('restautfood_items')
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5200)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No food items available."));
          }

          var allItems = snapshot.data!.docs;

          // 1. EXTRACT UNIQUE RESTAURANTS
          // This logic matches Instamart: We look at the food items to find the shops.
          Map<String, Map<String, dynamic>> uniqueRestaurants = {};

          for (var doc in allItems) {
            var data = doc.data() as Map<String, dynamic>;
            String rId = data['restaurantId'] ?? 'unknown';
            String rName = data['restaurantName'] ?? 'Unknown Restaurant';

            // Use the food image as the restaurant image if specific logo missing
            String rImage = data['imageUrl'] ?? 'https://cdn-icons-png.flaticon.com/512/1404/1404945.png';

            if (!uniqueRestaurants.containsKey(rId)) {
              uniqueRestaurants[rId] = {
                'id': rId,
                'name': rName,
                'image': rImage, // Keeps it lively!
              };
            }
          }

          List<Map<String, dynamic>> restaurantList = uniqueRestaurants.values.toList();

          // 2. FILTER PRODUCTS BASED ON SELECTION
          // If _selectedRestaurantId is null, show ALL items. Otherwise filter.
          var displayProducts = _selectedRestaurantId == null
              ? allItems
              : allItems.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['restaurantId'] == _selectedRestaurantId;
          }).toList();

          return Column(
            children: [
              // --- HORIZONTAL RESTAURANT LIST (Instamart Style) ---
              SizedBox(
                height: 120, // Taller to fit the "Instamart-like" cards
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemCount: restaurantList.length + 1, // +1 for "All" button
                  itemBuilder: (context, index) {

                    // "All" Button
                    if (index == 0) {
                      bool isSelected = _selectedRestaurantId == null;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedRestaurantId = null;
                          _selectedRestaurantName = "All Restaurants";
                        }),
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFF5200) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: isSelected ? const Color(0xFFFF5200) : Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text(
                                "All",
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black
                                )
                            ),
                          ),
                        ),
                      );
                    }

                    // Restaurant Item
                    var rest = restaurantList[index - 1];
                    bool isSelected = _selectedRestaurantId == rest['id'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRestaurantId = rest['id'];
                          _selectedRestaurantName = rest['name'];
                        });
                      },
                      child: Container(
                        width: 100, // Wider for Instamart look
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: isSelected ? const Color(0xFFFF5200) : Colors.grey.shade300,
                                width: isSelected ? 2 : 1
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                            ]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image Part
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                  image: DecorationImage(
                                    image: NetworkImage(rest['image']),
                                    fit: BoxFit.cover, // Makes it look like Instamart card
                                  ),
                                ),
                              ),
                            ),
                            // Text Part
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    rest['name'],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? const Color(0xFFFF5200) : Colors.black87
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // --- MENU ITEMS LIST ---
              Expanded(
                child: displayProducts.isEmpty
                    ? const Center(child: Text("No items available."))
                    : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: displayProducts.length,
                  itemBuilder: (context, index) {
                    var doc = displayProducts[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String productId = doc.id;

                    int qty = 0;
                    var cartItem = _cartItems.where((element) => element['id'] == productId);
                    if(cartItem.isNotEmpty) qty = cartItem.first['quantity'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
                      ),
                      child: Row(
                        children: [
                          // Food Image
                          Container(
                            height: 80, width: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                  image: NetworkImage(data['imageUrl'] ?? 'https://via.placeholder.com/150'),
                                  fit: BoxFit.cover
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? 'Item', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(data['description'] ?? '', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10), maxLines: 2),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("₹${data['price']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFFF5200))),
                                    qty == 0
                                        ? SizedBox(
                                      height: 32,
                                      child: ElevatedButton(
                                        onPressed: () => _addToCart({
                                          "id": productId,
                                          "name": data['name'],
                                          "price": (data['price'] as num).toDouble(),
                                          "image": data['imageUrl']
                                        }, _selectedRestaurantName),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color(0xFFFF5200),
                                            elevation: 0,
                                            side: const BorderSide(color: Color(0xFFFF5200)),
                                            padding: const EdgeInsets.symmetric(horizontal: 15)
                                        ),
                                        child: const Text("ADD", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    )
                                        : Container(
                                      height: 32,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.grey.shade300)
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                              icon: const Icon(Icons.remove, size: 16),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _updateQuantity(productId, qty - 1)
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text("$qty", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                                          ),
                                          IconButton(
                                              icon: const Icon(Icons.add, size: 16, color: Color(0xFFFF5200)),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _updateQuantity(productId, qty + 1)
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _cartItems.isNotEmpty ? Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0,-5))]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${_cartItems.length} Items", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                Text("₹${_cartTotal.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            ElevatedButton(
              onPressed: _checkout,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5200),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              child: const Text("Checkout", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ) : null,
    );
  }
}

// ==============================================================================
// 2. INSTAMART SCREEN (Updated with Products and Cart)
// ==============================================================================
class InstamartScreen extends StatefulWidget {
  const InstamartScreen({super.key});

  @override
  State<InstamartScreen> createState() => _InstamartScreenState();
}

class _InstamartScreenState extends State<InstamartScreen> {
  // State for filtering
  String? _selectedStoreId;
  String _selectedStoreName = "All Items";

  // Cart
  final List<Map<String, dynamic>> _cartItems = [];
  double _cartTotal = 0.0;
  String _deliveryAddress = "Loading address...";

  @override
  void initState() {
    super.initState();
    _fetchUserAddress();
  }

  Future<void> _fetchUserAddress() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() => _deliveryAddress = doc['address'] ?? "No address set");
      }
    }
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      int index = _cartItems.indexWhere((item) => item["id"] == product["id"]);
      if (index != -1) {
        _cartItems[index]["quantity"] = (_cartItems[index]["quantity"] ?? 1) + 1;
      } else {
        _cartItems.add({...product, "quantity": 1});
      }
      _calculateTotal();
    });
  }

  void _updateQuantity(String productId, int quantity) {
    setState(() {
      int index = _cartItems.indexWhere((item) => item["id"] == productId);
      if (index != -1) {
        if (quantity <= 0) _cartItems.removeAt(index);
        else _cartItems[index]["quantity"] = quantity;
        _calculateTotal();
      }
    });
  }

  void _calculateTotal() {
    double total = 0;
    for (var item in _cartItems) total += (item["price"] * (item["quantity"] ?? 1));
    setState(() => _cartTotal = total);
  }

  void _checkout() async {
    if (_cartItems.isEmpty) return;
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Instamart Checkout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total: ₹${_cartTotal.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFE94E68))),
            const SizedBox(height: 10),
            Text("Delivery To:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            Text(_deliveryAddress, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94E68)),
            child: const Text("Order Now"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('orders').add({
          'userId': user.uid,
          'userEmail': user.email,
          'items': _cartItems,
          'total': _cartTotal,
          'status': 'pending',
          'type': 'grocery',
          'address': _deliveryAddress,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      setState(() { _cartItems.clear(); _cartTotal = 0.0; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Grocery Order Placed!"), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Instamart", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE94E68),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // UPDATED COLLECTION NAME BASED ON YOUR SCREENSHOT
          stream: FirebaseFirestore.instance
              .collection('instamartfood_items')
              .where('status', isEqualTo: 'approved')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFE94E68)));
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No items available"));

            var allItems = snapshot.data!.docs;

            // 1. EXTRACT UNIQUE MARTS (Optional: can be filtered by Category too)
            Map<String, String> uniqueMarts = {};
            for (var doc in allItems) {
              var data = doc.data() as Map<String, dynamic>;
              String mId = data['instamartId'] ?? 'unknown';
              String mName = data['instamartName'] ?? 'Store';
              uniqueMarts[mId] = mName;
            }

            // 2. Filter Items Logic
            var displayItems = _selectedStoreId == null
                ? allItems
                : allItems.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return data['instamartId'] == _selectedStoreId;
            }).toList();

            return Column(
              children: [
                // Store/Category Selector
                SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    children: [
                      // "All" Button
                      GestureDetector(
                        onTap: () => setState(() { _selectedStoreId = null; _selectedStoreName = "All Items"; }),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedStoreId == null ? const Color(0xFFE94E68) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(child: Text("All", style: GoogleFonts.poppins(color: _selectedStoreId == null ? Colors.white : Colors.black))),
                        ),
                      ),
                      // Dynamic Marts from DB
                      ...uniqueMarts.entries.map((entry) {
                        bool isSelected = _selectedStoreId == entry.key;
                        return GestureDetector(
                          onTap: () => setState(() { _selectedStoreId = entry.key; _selectedStoreName = entry.value; }),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE94E68) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(child: Text(entry.value, style: GoogleFonts.poppins(color: isSelected ? Colors.white : Colors.black))),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                // Items Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(15),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: displayItems.length,
                    itemBuilder: (context, index) {
                      var doc = displayItems[index];
                      var data = doc.data() as Map<String, dynamic>;
                      String productId = doc.id;

                      int qty = 0;
                      var cartItem = _cartItems.where((element) => element['id'] == productId);
                      if(cartItem.isNotEmpty) qty = cartItem.first['quantity'];

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: NetworkImage(data['imageUrl'] ?? 'https://via.placeholder.com/150'),
                                        fit: BoxFit.contain
                                    )
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['name'] ?? 'Item', style: GoogleFonts.poppins(fontWeight: FontWeight.bold), maxLines: 1),
                                  Text(data['instamartName'] ?? '', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey), maxLines: 1),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("₹${data['price']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFFE94E68))),
                                      qty == 0
                                          ? IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFFE94E68)), onPressed: () => _addToCart({
                                        "id": productId, "name": data['name'], "price": (data['price'] as num).toDouble(), "image": data['imageUrl']
                                      }))
                                          : Row(
                                        children: [
                                          GestureDetector(onTap: () => _updateQuantity(productId, qty - 1), child: const Icon(Icons.remove_circle_outline, size: 20)),
                                          Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: Text("$qty")),
                                          GestureDetector(onTap: () => _updateQuantity(productId, qty + 1), child: const Icon(Icons.add_circle, size: 20, color: Color(0xFFE94E68))),
                                        ],
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
      ),
      bottomNavigationBar: _cartItems.isNotEmpty ? Container(
        padding: const EdgeInsets.all(15),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Total: ₹${_cartTotal.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            ElevatedButton(
              onPressed: _checkout,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94E68)),
              child: const Text("Checkout"),
            )
          ],
        ),
      ) : null,
    );
  }
}


// ==============================================================================
// 3. MAIN HOME SCREEN
// ==============================================================================


class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      name: data['name'] ?? 'User',
      email: data['email'] ?? '',
      phone: data['phone'],
      address: data['address'],
      profileImage: data['profileImage'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'profileImage': profileImage,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}



// ==============================================================================
// MAIN HOME SCREEN WITH FIRESTORE DATA
// ==============================================================================



class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final Color _orangeColor = const Color(0xFFFF5200);
  final Color _pinkColor = const Color(0xFFE94E68);

  final AuthCustomerService _authService = AuthCustomerService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _currentUser;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchUserData();
  }

  void _getCurrentUser() {
    setState(() {
      _currentUser = _auth.currentUser;
    });
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const CustomerLoginScreen()),
            (route) => false,
      );
    }
  }

  // --- WIDGET BUILDERS ---

  // 1. UPDATED RESTAURANT CARD (Instamart Style)
  Widget _buildRestaurantCard(Map<String, dynamic> data) {
    // Logic: Use restaurant image if available, otherwise use the food image (imageUrl)
    // This makes it look like the Instamart items (Real images)
    String imageUrl = data['image'] ?? 'https://via.placeholder.com/150';
    String name = data['name'] ?? 'Restaurant';

    return Container(
      width: 140, // Slightly wider to fit image better
      margin: const EdgeInsets.only(right: 15, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Container(
            height: 90, // Taller image area
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              color: Colors.grey[50],
            ),
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover, // Cover fills the area nicely
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.restaurant, color: Colors.grey),
              ),
            ),
          ),

          // Text Details
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    Text(" 4.5 • 30 mins", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroceryItemCard(Map<String, dynamic> data) {
    String imageUrl = data['imageUrl'] ?? 'https://via.placeholder.com/150';
    String name = data['name'] ?? 'Item';
    String price = data['price']?.toString() ?? '0';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  height: 100,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Text(
                    "₹$price",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: _pinkColor)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.orange, size: 18),
                const SizedBox(width: 4),
                Text(
                  "Home",
                  style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Text(
              _userData?['address'] ?? "Add delivery address",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(radius: 15, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 18, color: Colors.white)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              height: 50,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[600]),
                  const SizedBox(width: 10),
                  Text("Search for food or groceries", style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Selection Cards
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FoodDeliveryScreen())),
                    child: Container(
                      height: 160,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_orangeColor, _orangeColor.withOpacity(0.8)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: _orangeColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Food\nDelivery", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Order from top\nrestaurants", style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 11)),
                          const Spacer(),
                          Align(alignment: Alignment.bottomRight, child: Image.network('https://cdn-icons-png.flaticon.com/512/2819/2819194.png', height: 50)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InstamartScreen())),
                    child: Container(
                      height: 160,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_pinkColor, _pinkColor.withOpacity(0.8)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: _pinkColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Instamart", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Instant Grocery\nDelivery", style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 11)),
                          const Spacer(),
                          Align(alignment: Alignment.bottomRight, child: Image.network('https://cdn-icons-png.flaticon.com/512/1261/1261163.png', height: 50)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- RESTAURANTS (Real-Time from restautfood_items) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Restaurants", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FoodDeliveryScreen())),
                  child: Text("SEE ALL", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: _orangeColor)),
                ),
              ],
            ),

            SizedBox(
              height: 165, // Increased height to fit new card style
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('restautfood_items') // Direct Fetch from Items
                    .where('status', isEqualTo: 'approved')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No restaurants found", style: GoogleFonts.poppins(color: Colors.grey)));
                  }

                  // 1. UNIQUE RESTAURANT LOGIC with IMAGE HANDLING
                  Map<String, Map<String, dynamic>> uniqueRestaurants = {};
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String rId = data['restaurantId'] ?? 'unknown';

                    // IF we haven't added this restaurant yet...
                    if (!uniqueRestaurants.containsKey(rId)) {
                      // Try to use the food item image as the restaurant image (like Instamart)
                      // OR fallback to a default logo if null
                      String displayImage = data['imageUrl'] ?? 'https://cdn-icons-png.flaticon.com/512/4039/4039232.png';

                      uniqueRestaurants[rId] = {
                        'id': rId,
                        'name': data['restaurantName'] ?? 'Restaurant',
                        'image': displayImage, // Use the FOOD image to make it look lively
                      };
                    }
                  }
                  var restaurants = uniqueRestaurants.values.toList();

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      return _buildRestaurantCard(restaurants[index]);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // --- GROCERY ITEMS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Grocery Items", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InstamartScreen())),
                  child: Text("SEE ALL", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: _pinkColor)),
                ),
              ],
            ),

            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('instamartfood_items')
                  .where('status', isEqualTo: 'approved')
                  .limit(6)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("No groceries found", style: GoogleFonts.poppins(color: Colors.grey))));
                }

                var items = snapshot.data!.docs;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var data = items[index].data() as Map<String, dynamic>;
                    return _buildGroceryItemCard(data);
                  },
                );
              },
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}