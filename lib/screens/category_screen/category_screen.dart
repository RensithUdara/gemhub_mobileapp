import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemhub/screens/product_screen/product_card.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryTitle;

  const CategoryScreen({super.key, required this.categoryTitle});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _searchQuery = '';
  String _sortOrder = 'asc'; // Default sorting order
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];

  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

  // 🔹 Fetch products filtered by category
  void _fetchProducts() {
    _productsCollection
        .where('category', isEqualTo: widget.categoryTitle)
        .get()
        .then((snapshot) {
      setState(() {
        _products = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        _applyFilters();
      });
    });
  }

  // 🔹 Apply sorting and search filtering
  void _applyFilters() {
    setState(() {
      _filteredProducts = _products
          .where((product) => product['title'].toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
      _filteredProducts.sort((a, b) => _sortOrder == 'asc'
          ? a['price'].compareTo(b['price'])
          : b['price'].compareTo(a['price']));
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: Text(widget.categoryTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          // 🔹 Sort Button
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortOrder = value;
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'asc',
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: 'desc',
                child: Text('Price: High to Low'),
              ),
            ],
            icon: const Icon(Icons.sort, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        color: Colors.lightBlue[50], // Set background color to light blue
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // 🔹 Search Bar
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                  _applyFilters();
                });
              },
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
            // 🔹 Product Grid
            Expanded(
              child: _filteredProducts.isEmpty
                  ? const Center(child: Text('No products found.'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          imagePath: _filteredProducts[index]['imagePath'],
                          title: _filteredProducts[index]['title'],
                          price: 'Rs. ${_filteredProducts[index]['price']}',
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
