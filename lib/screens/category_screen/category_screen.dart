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

  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

  // 🔹 Fetch products filtered by category (No Sorting Required)
  Stream<List<Map<String, dynamic>>> _getFilteredProducts(String searchQuery) {
    Query query = _productsCollection.where('category', isEqualTo: widget.categoryTitle);

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      query = query.orderBy('title').startAt([searchQuery]).endAt(['$searchQuery\uf8ff']);
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
            // 🔹 Search Bar
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
            // 🔹 Product Grid
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getFilteredProducts(_searchQuery),
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
