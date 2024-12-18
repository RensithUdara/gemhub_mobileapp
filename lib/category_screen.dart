import 'package:flutter/material.dart';
import 'package:gemhub/widget/product_card.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryTitle;

  const CategoryScreen({super.key, required this.categoryTitle});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _selectedSortOption = 'Price low to high';

  final List<Map<String, dynamic>> _products = [
    {
      'title': 'Natural Blue Sapphire',
      'price': 4000000,
      'imagePath': 'assets/images/gem01.jpg'
    },
    {
      'title': 'Natural Pink Sapphire',
      'price': 1500000,
      'imagePath': 'assets/images/gem02.jpg'
    },
    {
      'title': 'Yellow Sapphire',
      'price': 2500000,
      'imagePath': 'assets/images/gem01.jpg'
    },
    {'title': 'Ruby', 'price': 6000000, 'imagePath': 'assets/images/gem01.jpg'},
    {
      'title': 'Emerald',
      'price': 3500000,
      'imagePath': 'assets/images/gem01.jpg'
    },
    {
      'title': 'White Sapphire',
      'price': 1000000,
      'imagePath': 'assets/images/gem01.jpg'
    },
  ];

  void _sortProducts(String option) {
    setState(() {
      if (option == 'Price low to high') {
        _products.sort((a, b) => a['price'].compareTo(b['price']));
      } else if (option == 'Price high to low') {
        _products.sort((a, b) => b['price'].compareTo(a['price']));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: Text(widget.categoryTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Search bar
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
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              ),
            ),
            const SizedBox(height: 20),
            // Optional banner
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: const DecorationImage(
                  image: AssetImage('assets/images/banner1.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Sorting options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sort By:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                DropdownButton<String>(
                  value: _selectedSortOption,
                  items: const [
                    DropdownMenuItem(
                      value: 'Price low to high',
                      child: Text('Price low to high'),
                    ),
                    DropdownMenuItem(
                      value: 'Price high to low',
                      child: Text('Price high to low'),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSortOption = newValue!;
                      _sortProducts(_selectedSortOption);
                    });
                  },
                  dropdownColor: Colors.blue[50],
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                  underline: const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Product Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  imagePath: _products[index]['imagePath'],
                  title: _products[index]['title'],
                  price: 'Rs. ${_products[index]['price']}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
