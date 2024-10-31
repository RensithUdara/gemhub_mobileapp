import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:gemhub/category_screen.dart';
import 'package:gemhub/login_screen.dart';
import 'package:gemhub/cart_screen.dart'; // Import Cart Screen
import 'package:gemhub/profile_screen.dart'; // Import Profile Screen
import 'package:gemhub/auction_screen.dart';
import 'package:gemhub/widget/category_card%20.dart'; // Import Auction Screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final iconList = <IconData>[
    Icons.home,
    Icons.shopping_cart,
    Icons.receipt,
    Icons.person,
  ];

  final List<String> imgList = [
    'assets/images/banner1.png',
    'assets/images/banner2.png',
    'assets/images/banner3.png',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      // Navigate to Cart Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CartScreen()),
      );
    } else if (index == 3) {
      // Navigate to Profile Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen(name: '', email: '', phone: '',)),
      );
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Do you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Yes'),
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
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Image.asset(
                'assets/images/logo_new.png',
                height: 30,
              ),
              const SizedBox(width: 10),
              Text(
                'GemHub',
                style: TextStyle(
                    color: Colors.blue[700], fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Rensith,',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CarouselSlider(
                  options: CarouselOptions(
                    height: 150.0,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.8,
                  ),
                  items: imgList.map((item) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: AssetImage(item),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Categories',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
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
                const SizedBox(height: 20),
                const Text(
                  'Popular Gems',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
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
          child: const Icon(Icons.gavel),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AnimatedBottomNavigationBar(
          icons: iconList,
          activeIndex: _selectedIndex,
          gapLocation: GapLocation.center,
          notchSmoothness: NotchSmoothness.smoothEdge,
          onTap: _onItemTapped,
          leftCornerRadius: 32,
          rightCornerRadius: 32,
        ),
      ),
    );
  }
}
