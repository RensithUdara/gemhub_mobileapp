import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemhub/providers/banner_provider.dart';
import 'package:gemhub/screens/auction_screen/auction_screen.dart';
import 'package:gemhub/screens/auth_screens/login_screen.dart';
import 'package:gemhub/screens/cart_screen/cart_screen.dart';
import 'package:gemhub/screens/category_screen/category_card.dart';
import 'package:gemhub/screens/product_screen/product_card.dart';
import 'package:gemhub/screens/profile_screen/profile_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final iconList = const [
    Icons.home,
    Icons.shopping_cart,
    Icons.receipt,
    Icons.person,
  ];
  String userName = 'Guest';

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userName = userDoc['name'] as String? ?? 'Guest';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()), // Removed cartItems parameter
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.logout, color: Colors.redAccent),
                SizedBox(width: 10),
                Text('Confirm Logout',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    debugPrint('Error during logout: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child:
                    const Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // Sample product data for Popular Gems section
    final List<Map<String, dynamic>> popularProducts = [
      {
        'id': '1',
        'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTZJUXhT8gkiHYQywVLTOdkuyGE31eo45l2LA&s',
        'title': '4.37ct Natural Blue Sapphire',
        'pricing': 4038500.00,
      },
      {
        'id': '2',
        'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTZJUXhT8gkiHYQywVLTOdkuyGE31eo45l2LA&s',
        'title': '1.17ct Natural Pink Sapphire',
        'pricing': 549000.00,
      },
      {
        'id': '3',
        'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTZJUXhT8gkiHYQywVLTOdkuyGE31eo45l2LA&s',
        'title': '4.37ct Natural Blue Sapphire',
        'pricing': 4038500.00,
      },
      {
        'id': '4',
        'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTZJUXhT8gkiHYQywVLTOdkuyGE31eo45l2LA&s',
        'title': '1.17ct Natural Pink Sapphire',
        'pricing': 549000.00,
      },
      {
        'id': '5',
        'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTZJUXhT8gkiHYQywVLTOdkuyGE31eo45l2LA&s',
        'title': '4.37ct Natural Blue Sapphire',
        'pricing': 4038500.00,
      },
      {
        'id': '6',
        'imageUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn9GcTZJUXhT8gkiHYQywVLTOdkuyGE31eo45l2LA&s',
        'title': '1.17ct Natural Pink Sapphire',
        'pricing': 549000.00,
      },
    ];

    return ChangeNotifierProvider(
      create: (context) => BannerProvider()..fetchBannerImages(),
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0072ff), Color(0xFF00c6ff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            elevation: 10,
            shadowColor: Colors.black.withOpacity(0.3),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo_new.png', height: 50),
                const SizedBox(width: 10),
                const Text(
                  'GemHub',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _onWillPop,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              final bannerProvider =
                  Provider.of<BannerProvider>(context, listen: false);
              await bannerProvider.fetchBannerImages();
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome $userName,',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Consumer<BannerProvider>(
                      builder: (context, bannerProvider, child) {
                        if (bannerProvider.isLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (bannerProvider.error != null) {
                          return Center(
                            child: Text(
                              'Error loading banners',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        return CarouselSlider(
                          options: CarouselOptions(
                            height: 180.0,
                            autoPlay: true,
                            enlargeCenterPage: true,
                            viewportFraction: 0.9,
                            aspectRatio: 16 / 9,
                          ),
                          items: bannerProvider.bannerList.map((imageUrl) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(
                                      title: const Text('All Categories')),
                                  body: const Center(
                                    child: Text(
                                        'All categories will be displayed here.'),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'See All',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      padding: const EdgeInsets.all(8),
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        CategoryCard(
                          imagePath: 'assets/images/category1.jpg',
                          title: 'Blue Sapphires',
                        ),
                        CategoryCard(
                          imagePath: 'assets/images/category2.jpg',
                          title: 'White Sapphires',
                        ),
                        CategoryCard(
                          imagePath: 'assets/images/category3.jpg',
                          title: 'Yellow Sapphires',
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Popular Gems',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: popularProducts.length,
                      itemBuilder: (context, index) {
                        final product = popularProducts[index];
                        return ProductCard(
                          id: product['id'] as String,
                          imagePath: product['imageUrl'] as String,
                          title: product['title'] as String,
                          price:
                              'Rs. ${(product['pricing'] as num).toStringAsFixed(2)}',
                          product: product,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuctionScreen()),
              );
            },
            backgroundColor: const Color.fromARGB(255, 173, 216, 230),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            child: const Icon(Icons.gavel),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: AnimatedBottomNavigationBar(
            icons: iconList,
            activeIndex: _selectedIndex,
            gapLocation: GapLocation.center,
            notchSmoothness: NotchSmoothness.smoothEdge,
            onTap: _onItemTapped,
            backgroundColor: const Color.fromARGB(255, 173, 216, 230),
            activeColor: const Color.fromARGB(255, 0, 0, 139),
            leftCornerRadius: 32,
            rightCornerRadius: 32,
          ),
        ),
      ),
    );
  }
}