// Now, let's improve the HomeScreen
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:gemhub/providers/banner_provider.dart';
import 'package:gemhub/screens/category_screen/category_card.dart';
import 'package:provider/provider.dart';
import 'package:gemhub/screens/auction_screen/auction_screen.dart';
import 'package:gemhub/screens/auth_screens/login_screen.dart';
import 'package:gemhub/screens/cart_screen/cart_screen.dart';
import 'package:gemhub/screens/product_screen/product_card.dart';
import 'package:gemhub/screens/profile_screen/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String userName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    // Banner fetching is handled by BannerProvider
  }

  Future<void> _fetchUserName() async {
    try {
      // Replace 'userId' with actual user ID (perhaps from auth system)
      var user = FirebaseFirestore.instance.collection('users').doc('userId');
      var docSnapshot = await user.get();
      if (docSnapshot.exists) {
        setState(() {
          userName = docSnapshot.data()?['username'] ?? 'Guest';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        userName = 'Guest';
      });
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
          MaterialPageRoute(builder: (context) => const CartScreen(cartItems: [])),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(
              name: '',
              email: '',
              phone: '',
            ),
          ),
        );
        break;
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.logout, color: Colors.redAccent),
                SizedBox(width: 10),
                Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final bannerProvider = BannerProvider();
        bannerProvider.fetchBannerImages();
        return bannerProvider;
      },
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
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome $userName,',
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
                    ),
                  ),
                  const SizedBox(height: 15),
                  Consumer<BannerProvider>(
                    builder: (context, bannerProvider, child) {
                      if (bannerProvider.isLoading) {
                        return const SizedBox(
                          height: 150,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (bannerProvider.error != null) {
                        return SizedBox(
                          height: 150,
                          child: Center(
                            child: Text(
                              'Error loading banners',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }
                      if (bannerProvider.bannerList.isEmpty) {
                        return const SizedBox(
                          height: 150,
                          child: Center(child: Text('No banners available')),
                        );
                      }
                      return CarouselSlider(
                        options: CarouselOptions(
                          height: 150.0,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          aspectRatio: 16 / 9,
                          viewportFraction: 0.8,
                        ),
                        items: bannerProvider.bannerList.map((item) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                              image: NetworkImage(item),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) => const Icon(Icons.error),
                            ),
                          ),
                        )).toList(),
                      );
                    },
                  ),
                  // Rest of your existing widgets remain the same...
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(title: const Text('All Categories')),
                                body: const Center(
                                  child: Text('All categories will be displayed here.'),
                                ),
                              ),
                            ),
                          );
                        },
                        child: const Text('See All', style: TextStyle(color: Colors.blue)),
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
                      CategoryCard(imagePath: 'assets/images/category1.jpg', title: 'Blue Sapphires'),
                      CategoryCard(imagePath: 'assets/images/category2.jpg', title: 'White Sapphires'),
                      CategoryCard(imagePath: 'assets/images/category3.jpg', title: 'Yellow Sapphires'),
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
                      ProductCard(imagePath: 'https://firebasestorage.googleapis.com/v0/b/gemhub-mobile-app.firebasestorage.app/o/1.51ct-Blue-Sapphire.jpg?alt=media&token=3419a0ce-76a0-4b0a-add0-5e11644cd394', title: '4.37ct Natural Blue Sapphire', price: 'Rs 4,038,500.00'),
                      ProductCard(imagePath: 'https://firebasestorage.googleapis.com/v0/b/gemhub-mobile-app.firebasestorage.app/o/gem01.jpg?alt=media&token=475d79c8-0694-4493-b112-85061cbf2980', title: '1.17ct Natural Pink Sapphire', price: 'Rs.549,000.00'),
                      ProductCard(imagePath: 'https://firebasestorage.googleapis.com/v0/b/gemhub-mobile-app.firebasestorage.app/o/1.51ct-Blue-Sapphire.jpg?alt=media&token=3419a0ce-76a0-4b0a-add0-5e11644cd394', title: '4.37ct Natural Blue Sapphire', price: 'Rs 4,038,500.00'),
                      ProductCard(imagePath: 'https://firebasestorage.googleapis.com/v0/b/gemhub-mobile-app.firebasestorage.app/o/gem01.jpg?alt=media&token=475d79c8-0694-4493-b112-85061cbf2980', title: '1.17ct Natural Pink Sapphire', price: 'Rs.549,000.00'),
                      ProductCard(imagePath: 'https://firebasestorage.googleapis.com/v0/b/gemhub-mobile-app.firebasestorage.app/o/1.51ct-Blue-Sapphire.jpg?alt=media&token=3419a0ce-76a0-4b0a-add0-5e11644cd394', title: '4.37ct Natural Blue Sapphire', price: 'Rs 4,038,500.00'),
                      ProductCard(imagePath: 'https://firebasestorage.googleapis.com/v0/b/gemhub-mobile-app.firebasestorage.app/o/gem01.jpg?alt=media&token=475d79c8-0694-4493-b112-85061cbf2980', title: '1.17ct Natural Pink Sapphire', price: 'Rs.549,000.00'),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            child: const Icon(Icons.gavel),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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