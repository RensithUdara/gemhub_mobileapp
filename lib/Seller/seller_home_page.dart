import 'package:firebase_auth/firebase_auth.dart'; // Added Firebase Auth
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gemhub/Seller/listed_auction_screen.dart';
import 'package:gemhub/Seller/listed_product_screen.dart';
import 'package:gemhub/Seller/order_history_screen.dart';
import 'package:gemhub/Seller/seller_profile_screen.dart';
import 'package:gemhub/screens/auth_screens/login_screen.dart';

import 'auction_product.dart' as auction;
import 'notifications_page.dart';
import 'product_listing.dart' as product;

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isHovered = false;
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _notifications = [];
  String? currentUserId; // Added to store current user ID

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();

    // Get current user ID
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showNotification(
      String title, int quantity, String? imagePath, String type) {
    setState(() {
      _notifications.add({
        'title': title,
        'quantity': quantity,
        'imagePath': imagePath,
        'type': type,
      });
    });
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.black87,
            title: const Row(
              children: [
                Icon(Icons.logout, color: Colors.redAccent),
                SizedBox(width: 10),
                Text('Confirm Logout',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            content: const Text('Are you sure you want to logout?',
                style: TextStyle(fontSize: 16, color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pop(true);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Logout',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 1: // Notifications
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                NotificationsPage(notifications: _notifications),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
        break;
      case 2: // Profile
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SellerProfileScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
        break;
      case 3: // Logout
        _onWillPop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      // If no user is logged in, redirect to login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
      return const SizedBox(); // Return empty widget while redirecting
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.black87, Colors.black54],
                    stops: [0.2, 0.8],
                  ),
                ),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MouseRegion(
                            onEnter: (_) => setState(() => _isHovered = true),
                            onExit: (_) => setState(() => _isHovered = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: _isHovered
                                    ? [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  'assets/images/logo_new.png',
                                  width: 180,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildButton(
                            title: 'PRODUCT LISTING',
                            icon: Icons.list_alt,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const product.ProductListing(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    return FadeTransition(
                                        opacity: animation, child: child);
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 400),
                                ),
                              );
                              if (result != null &&
                                  result is Map<String, dynamic>) {
                                _showNotification(
                                    result['title'],
                                    result['quantity'],
                                    result['imagePath'],
                                    'product');
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildButton(
                            title: 'AUCTION LISTING',
                            icon: Icons.gavel,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const auction.AuctionProduct(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    return FadeTransition(
                                        opacity: animation, child: child);
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 400),
                                ),
                              );
                              if (result != null &&
                                  result is Map<String, dynamic>) {
                                _showNotification(
                                    result['title'],
                                    result['quantity'],
                                    result['imagePath'],
                                    'auction');
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildButton(
                            title: 'LISTED PRODUCTS',
                            icon: Icons.history,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ListedProductScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildButton(
                            title: 'AUCTION HISTORY',
                            icon: Icons.timeline,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListedAuctionScreen(
                                    sellerId: currentUserId!,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildButton(
                            title: 'ORDER HISTORY',
                            icon: Icons.receipt_long,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SellerOrderHistoryScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.black87],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.grey[400],
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: [
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == 0
                          ? Colors.blueAccent.withOpacity(0.2)
                          : Colors.transparent,
                    ),
                    child: const Icon(Icons.home, size: 28),
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedIndex == 1
                              ? Colors.blueAccent.withOpacity(0.2)
                              : Colors.transparent,
                        ),
                        child: const Icon(Icons.notifications, size: 28),
                      ),
                      if (_notifications.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _notifications.length.toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Notifications',
                ),
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == 2
                          ? Colors.blueAccent.withOpacity(0.2)
                          : Colors.transparent,
                    ),
                    child: const Icon(Icons.person, size: 28),
                  ),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == 3
                          ? Colors.blueAccent.withOpacity(0.2)
                          : Colors.transparent,
                    ),
                    child: const Icon(Icons.logout, size: 28),
                  ),
                  label: 'Logout',
                ),
              ],
              selectedLabelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              showUnselectedLabels: true,
              selectedIconTheme:
                  const IconThemeData(size: 32, color: Colors.blueAccent),
              unselectedIconTheme:
                  const IconThemeData(size: 28, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: _isHovered ? 12 : 8,
              shadowColor: Colors.blueAccent.withOpacity(0.6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: Colors.white),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_ios,
                    size: 20, color: Colors.white),
              ],
            ),
          ).animate().scale(duration: 250.ms, curve: Curves.easeInOut),
        ),
      ),
    );
  }
}
