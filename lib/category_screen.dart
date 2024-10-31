import 'package:flutter/material.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryTitle;

  const CategoryScreen({super.key, required this.categoryTitle});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _selectedSortOption = 'Price low to high';
  final List<Map<String, dynamic>> _products = [
    {'title': 'Carrot', 'price': 600, 'imagePath': 'assets/images/gem01.jpg'},
    {
      'title': 'Cauliflower',
      'price': 450,
      'imagePath': 'assets/images/gem01.jpg'
    },
    {'title': 'Beets', 'price': 100, 'imagePath': 'assets/images/gem01.jpg'},
    {'title': 'Cabbage', 'price': 300, 'imagePath': 'assets/images/gem01.jpg'},
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
        title: Text(widget.categoryTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sort By:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  imagePath: _products[index]['imagePath'],
                  title: _products[index]['title'],
                  price: 'Rs. ${_products[index]['price']}/Kg',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String price;

  const ProductCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        children: [
          Image.asset(imagePath, height: 100, fit: BoxFit.cover),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(price, style: const TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}
