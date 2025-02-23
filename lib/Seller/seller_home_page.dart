import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Add this package for animations

import 'auction_product.dart';
import 'notifications_page.dart'; // New import for the Notifications page
import 'product_listing.dart';

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
  int _selectedIndex = 0; // Track the selected tab in the bottom navigation bar
  final List<Map<String, dynamic>> _notifications =
      []; // List to store notification data (image, title, quantity)

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Method to add a notification with product details
  void _showNotification(String title, int quantity, String? imagePath) {
    setState(() {
      _notifications.add({
        'title': title,
        'quantity': quantity,
        'imagePath': imagePath,
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      // Navigate to Notifications page
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              NotificationsPage(notifications: _notifications),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Dynamic Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black87,
                    Colors.black54,
                  ],
                  stops: [0.2, 0.8],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar with Glow Effect and Centered
                          MouseRegion(
                            onEnter: (_) => setState(() => _isHovered = true),
                            onExit: (_) => setState(() => _isHovered = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: _isHovered
                                    ? [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                          offset: const Offset(0, 0),
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
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                           const SizedBox(height: 40),
                          // // Welcome Text with Animation and Centered
                          // const Text(
                          //   'Welcome, Kasun!',
                          //   textAlign: TextAlign.center,
                          //   style: TextStyle(
                          //     color: Colors.white,
                          //     fontSize: 36,
                          //     fontWeight: FontWeight.bold,
                          //     shadows: [
                          //       Shadow(
                          //         color: Colors.blue,
                          //         offset: Offset(0, 6),
                          //         blurRadius: 8,
                          //       ),
                          //     ],
                          //   ),
                          // ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),
                          // const SizedBox(height: 60),
                          // Buttons with Hover, Tap Animations, and Centered
                          _buildButton(
                            context: context,
                            title: 'PRODUCT LISTING',
                            icon: Icons.list_alt,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (context, animation, secondaryAnimation) =>
                                          const ProductListing(),
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
                                _showNotification(result['title'],
                                    result['quantity'], result['imagePath']);
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildButton(
                            context: context,
                            title: 'AUCTION',
                            icon: Icons.gavel,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (context, animation, secondaryAnimation) =>
                                          const AuctionProduct(),
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
                                _showNotification(result['title'],
                                    result['quantity'], result['imagePath']);
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildButton(
                            context: context,
                            title: 'ORDER HISTORY',
                            icon: Icons.history,
                            onTap: () {},
                          ),
                          const SizedBox(height: 24),
                          _buildButton(
                            context: context,
                            title: 'AUCTION HISTORY',
                            icon: Icons.timeline,
                            onTap: () {},
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.lightBlueAccent,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          iconSize: 32,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications),
                  if (_notifications.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          _notifications.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: '',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 12,
          selectedIconTheme:
              const IconThemeData(size: 34, color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
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
      ),
    );
  }
}
