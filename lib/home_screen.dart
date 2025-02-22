import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:gemhub/screens/auction_screen/auction_screen.dart';
import 'package:gemhub/screens/auth_screens/login_screen.dart';
import 'package:gemhub/screens/cart_screen/cart_screen.dart';
import 'package:gemhub/screens/product_screen/product_card.dart';
import 'package:gemhub/screens/profile_screen/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'widget/category_card .dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final iconList = <IconData>[
    Icons.home,
    Icons.shopping_cart,
    Icons.receipt,
    Icons.person,
  ];

  List<String> bannerList = [];
  String userName = '';

  @override
  void initState() {
    super.initState();
    _fetchBannerImages();
    _fetchUserName();
  }

  Future<void> _fetchBannerImages() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('banners').get();
      final List<String> banners = [];

      for (var doc in querySnapshot.docs) {
        String gsUrl = doc['imageUrl'];
        String httpUrl = await FirebaseStorage.instance.refFromURL(gsUrl).getDownloadURL();
        banners.add(httpUrl);
      }

      print('Fetched Banners: $banners');
      setState(() {
        bannerList = banners;
      });
    } catch (e) {
      print('Error fetching banners: $e');
    }
  }

  Future<void> _fetchUserName() async {
    try {
      var user = FirebaseFirestore.instance.collection('users').doc('userId'); // Replace 'userId' with the actual user ID
      var docSnapshot = await user.get();
      if (docSnapshot.exists) {
        setState(() {
          userName = docSnapshot['username']; // Ensure that the username is fetched correctly
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CartScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const ProfileScreen(
                  name: '',
                  email: '',
                  phone: '',
                )),
      );
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.redAccent,
                ),
                SizedBox(width: 10),
                Text(
                  'Confirm Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Are you sure you want to logout?',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () {
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
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
              Image.asset(
                'assets/images/logo_new.png',
                height: 50,
              ),
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
              onPressed: () async {
                bool shouldLogout = await _onWillPop();
                if (shouldLogout) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome ${userName.isNotEmpty ? userName : 'Guest'},',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    hintText: 'Search gems...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    filled: true,
                    fillColor: Colors.blue[50],
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                  ),
                ),
                const SizedBox(height: 15),
                bannerList.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : CarouselSlider(
                        options: CarouselOptions(
                          height: 150.0,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          aspectRatio: 16 / 9,
                          viewportFraction: 0.8,
                        ),
                        items: bannerList
                            .map((item) => Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    image: DecorationImage(
                                      image: NetworkImage(item),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Categories',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                title: const Text('All Categories'),
                              ),
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
                        style: TextStyle(color: Colors.blue, fontSize: 16),
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
                      title: 'White Sapphire',
                    ),
                    CategoryCard(
                      imagePath: 'assets/images/category3.jpg',
                      title: 'Yellow Sapphire',
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  'Popular Gems',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  padding: const EdgeInsets.all(8),
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    ProductCard(
                      imagePath: 'assets/images/gem01.jpg',
                      title: '4.37ct Natural Blue Sapphire',
                      price: 'Rs 4,038,500.00',
                    ),
                    ProductCard(
                      imagePath: 'assets/images/gem02.jpg',
                      title: '1.17ct Natural Pink Sapphire',
                      price: 'Rs.549,000.00',
                    ),
                  ],
                ),
              ],
            ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: const Icon(Icons.gavel),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AnimatedBottomNavigationBar(
          icons: iconList,
          activeIndex: _selectedIndex,
          gapLocation: GapLocation.center,
          notchSmoothness: NotchSmoothness.defaultEdge,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
