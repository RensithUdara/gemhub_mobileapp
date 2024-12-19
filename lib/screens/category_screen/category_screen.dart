import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gemhub/screens/product_screen/product_card.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryTitle;

  const CategoryScreen({super.key, required this.categoryTitle});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _selectedSortOption = 'Price low to high';
  String _searchQuery = ''; // State to track search input

  // Firestore reference
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

  // Method to fetch sorted and filtered data
  Stream<List<Map<String, dynamic>>> _getSortedProducts(
      String sortOption, String searchQuery) {
    Query query = _productsCollection;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      query = query.where('title', isGreaterThanOrEqualTo: searchQuery).where(
          'title',
          isLessThanOrEqualTo: searchQuery + '\uf8ff'); // For prefix matching
    }

    // Apply sorting
    if (sortOption == 'Price low to high') {
      query = query.orderBy('price', descending: false);
    } else if (sortOption == 'Price high to low') {
      query = query.orderBy('price', descending: true);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: Text(widget.categoryTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Search bar
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
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
                    });
                  },
                  dropdownColor: Colors.blue[50],
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                  underline: const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Product Grid with Firestore data
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getSortedProducts(_selectedSortOption, _searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading products.'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  } else {
                    final products = snapshot.data!;
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          imagePath: products[index]['imagePath'],
                          title: products[index]['title'],
                          price: 'Rs. ${products[index]['price']}',
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
