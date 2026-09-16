import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth/auth_gate_admin.dart';
import 'auth/auth_gate_customer.dart';
import 'auth/auth_gate_delivery_partner.dart';
import 'auth/auth_gate_instamart.dart';
import 'auth/auth_gate_restraurant.dart';

// -----------------------------------------------------------------------------
// IMPORTS
// Un-comment these lines when you have linked your real files.
// -----------------------------------------------------------------------------
// import 'auth_gate_customer.dart';
// import 'auth_gate_instamart.dart';
// import 'auth_gate_partner.dart';
// import 'auth_gate_rider.dart';
// import 'auth_gate_admin.dart';

void main() async { // 3. Make main async
  // 4. Initialize Firebase BEFORE running the app
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // Uncomment if using flutterfire CLI
  );

  runApp(const FoodMartApp());
}

class FoodMartApp extends StatelessWidget {
  const FoodMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodMart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7), // Light Grey Background
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF5200)), // Swiggy Orange
        textTheme: GoogleFonts.poppinsTextTheme(), // Modern Font
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  // State for the scrolling banner
  int _currentBannerIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Gradient (Header Fade)
          Container(
            height: 400,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE5E5), // Light Orange/Pink fade
                  Color(0xFFF5F5F7),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Custom Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFFF5200), size: 28),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("FoodMart", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("Select Role", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: const CircleAvatar(
                            backgroundColor: Colors.black,
                            radius: 16,
                            child: Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text("Search for modules...", style: TextStyle(color: Colors.grey[400])),
                          const Spacer(),
                          Container(width: 1, height: 20, color: Colors.grey[300]),
                          const SizedBox(width: 12),
                          const Icon(Icons.mic, color: Color(0xFFFF5200)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // -----------------------------------------------------------
                  // 4. NEW: SCROLLING AD (CAROUSEL)
                  // -----------------------------------------------------------
                  SizedBox(
                    height: 180,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentBannerIndex = index);
                      },
                      children: [
                        _buildPromoBanner(
                          "Welcome to FoodMart",
                          "Super App for Everyone",
                          Colors.deepOrangeAccent,
                          Icons.celebration,
                        ),
                        _buildPromoBanner(
                          "Instamart is Live!",
                          "Groceries in 10 mins",
                          const Color(0xFFD81B60),
                          Icons.shopping_bag,
                        ),
                        _buildPromoBanner(
                          "Join as Partner",
                          "Grow your business",
                          const Color(0xFF43A047),
                          Icons.store,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Dot Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _currentBannerIndex == index ? 20 : 6,
                        decoration: BoxDecoration(
                          color: _currentBannerIndex == index ? const Color(0xFFFF5200) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // -----------------------------------------------------------
                  // 5. NEW: "WHAT'S ON YOUR MIND?" (Horizontal Scroll)
                  // -----------------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "WHAT'S ON YOUR MIND?",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        _buildCategoryItem("Burger", Icons.lunch_dining),
                        _buildCategoryItem("Pizza", Icons.local_pizza),
                        _buildCategoryItem("Grocery", Icons.shopping_basket),
                        _buildCategoryItem("Healthy", Icons.spa),
                        _buildCategoryItem("Cake", Icons.cake),
                        _buildCategoryItem("Paratha", Icons.breakfast_dining),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 6. Hero Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // const Text(
                        //   "ALL MODULES",
                        //   style: TextStyle(
                        //     fontSize: 24,
                        //     fontWeight: FontWeight.w900,
                        //     color: Color(0xFF3D4152),
                        //   ),
                        // ),
                        Text(
                          "Access your dashboard below",
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // -----------------------------------------------------------
                  // 7. BENTO GRID (MODULES)
                  // -----------------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        // A. Wide Card for Main Customer App
                        _buildWideModuleCard(
                          context,
                          title: "FOOD & PRODUCTS",
                          subtitle: "Customer App",
                          tag: "FLAT 50% OFF",
                          icon: Icons.fastfood_rounded,
                          color: const Color(0xFFFF5200),
                          targetPage: const AuthGateCustomer(),
                        ),

                        const SizedBox(height: 16),

                        // B. Grid for other modules
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- LEFT COLUMN ---
                            Expanded(
                              child: Column(
                                children: [
                                  // INSTAMART
                                  _buildModuleCard(
                                    context,
                                    title: "INSTAMART",
                                    subtitle: "Grocery & Needs",
                                    tag: "10 MINS",
                                    icon: Icons.flash_on_rounded, // Changed icon
                                    color: const Color(0xFFD81B60), // Pinkish Red
                                    height: 180,
                                    targetPage: const AuthGateInstamart(),
                                  ),
                                  const SizedBox(height: 16),

                                  // DELIVERY PARTNER
                                  _buildModuleCard(
                                    context,
                                    title: "DELIVERY PARTNER",
                                    subtitle: "Rider App",
                                    tag: "LOGISTICS",
                                    icon: Icons.two_wheeler_rounded,
                                    color: const Color(0xFF1E88E5), // Blue
                                    height: 220,
                                    targetPage: const AuthGateRider(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // --- RIGHT COLUMN ---
                            Expanded(
                              child: Column(
                                children: [
                                  // RESTAURANTS
                                  _buildModuleCard(
                                    context,
                                    title: "RESTRURANT",
                                    subtitle: "Restaurant/Store",
                                    tag: "BUSINESS",
                                    icon: Icons.storefront_rounded,
                                    color: const Color(0xFF43A047), // Green
                                    height: 220,
                                    targetPage: const AuthGateRestaurant(),
                                  ),
                                  const SizedBox(height: 16),

                                  // ADMIN
                                  _buildModuleCard(
                                    context,
                                    title: "ADMIN",
                                    subtitle: "Management",
                                    tag: "HQ ONLY",
                                    icon: Icons.admin_panel_settings_rounded,
                                    color: const Color(0xFF546E7A), // Blue Grey
                                    height: 180,
                                    targetPage: const AuthGateAdmin(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // -----------------------------------------------------------
                  // 8. COMPANY FOOTER CONTENT
                  // -----------------------------------------------------------
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "LIVE FOR FOOD & PRODUCTS",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey[300],
                            letterSpacing: 2,

                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Divider(color: Colors.grey[300], thickness: 1),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _footerLink("About"),
                            _footerDot(),
                            _footerLink("Careers"),
                            _footerDot(),
                            _footerLink("Policy"),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialIcon(Icons.facebook),
                            const SizedBox(width: 20),
                            _socialIcon(Icons.camera_alt),
                            const SizedBox(width: 20),
                            _socialIcon(Icons.alternate_email),
                          ],
                        ),

                        const SizedBox(height: 30),

                        const Text(
                          "FoodMart Technologies Pvt. Ltd.",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  // Banner Widget
  Widget _buildPromoBanner(String title, String subtitle, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Stack(
        children: [
          // Background Circle Pattern
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withOpacity(0.2)),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Text("FEATURED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 50),
          )
        ],
      ),
    );
  }

  // Category Item Widget
  Widget _buildCategoryItem(String name, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Icon(icon, color: const Color(0xFF3D4152), size: 28),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF3D4152))),
        ],
      ),
    );
  }

  // Footer Helpers
  Widget _footerLink(String text) {
    return Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]));
  }
  Widget _footerDot() {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 8), width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle));
  }
  Widget _socialIcon(IconData icon) {
    return Icon(icon, color: Colors.grey[500], size: 22);
  }

  // 1. Wide Module Card
  Widget _buildWideModuleCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required String tag,
        required IconData icon,
        required Color color,
        required Widget targetPage,
      }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage)),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF3D4152)),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), Colors.white.withOpacity(0)],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 30,
              child: Icon(icon, size: 80, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Standard Grid Card
  Widget _buildModuleCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required String tag,
        required IconData icon,
        required Color color,
        required double height,
        required Widget targetPage,
      }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage)),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF3D4152)),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -15,
              right: -15,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), Colors.white.withOpacity(0)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Icon(icon, size: 50, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PLACEHOLDER CLASSES - Delete these when you have real files
// -----------------------------------------------------------------------------



