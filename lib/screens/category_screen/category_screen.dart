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
  String _sortOrder = 'asc'; // Default sorting order, will persist via setState
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;

  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

  // Fetch products filtered by category
  void _fetchProducts() {
    _productsCollection
        .where('category', isEqualTo: widget.categoryTitle)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _products = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        _applyFilters(); // Apply filters with the current sort order
        _isLoading = false;
      });
    }, onError: (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching products: $error')),
      );
    });
  }

  // Apply sorting and search filtering
  void _applyFilters() {
    setState(() {
      _filteredProducts = List.from(_products); // Create a copy of products

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        _filteredProducts = _filteredProducts
            .where((product) => product['title']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();
      }

      // Apply sorting
      _filteredProducts.sort((a, b) {
        final aPrice = a['pricing'] as num? ?? 0;
        final bPrice = b['pricing'] as num? ?? 0;
        return _sortOrder == 'asc'
            ? aPrice.compareTo(bPrice)
            : bPrice.compareTo(aPrice);
      });
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
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortOrder = value; // Update sort order
                _applyFilters(); // Reapply filters with new sort order
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
        color: Colors.lightBlue[50],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Search Bar
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
            // Product Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
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
                            final product = _filteredProducts[index];
                            return GestureDetector(
                              onTap: () {
                                _showProductDetails(context, product);
                              },
                              child: ProductCard(
                                imagePath: product['imageUrl'] ?? '',
                                title: product['title'] ?? 'Untitled',
                                price:
                                    'Rs. ${(product['pricing'] as num? ?? 0).toStringAsFixed(2)}',
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Show product details in a dialog
  void _showProductDetails(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['title'] ?? 'Untitled'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product['imageUrl'] != null && product['imageUrl'].isNotEmpty)
                Image.network(
                  product['imageUrl'],
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error),
                ),
              const SizedBox(height: 10),
              Text(
                  'Price: Rs. ${(product['pricing'] as num? ?? 0).toStringAsFixed(2)}'),
              Text('Quantity: ${product['quantity']?.toString() ?? 'N/A'}'),
              Text('Unit: ${product['unit'] ?? 'N/A'}'),
              const SizedBox(height: 10),
              Text('Description: ${product['description'] ?? 'No description'}'),
              Text('Category: ${product['category'] ?? 'N/A'}'),
              Text('Listed by: ${product['userId'] ?? 'Unknown'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}