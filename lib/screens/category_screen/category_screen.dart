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
  String _sortOrder = 'asc';
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;

  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

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
        _applyFilters();
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

  void _applyFilters() {
    setState(() {
      _filteredProducts = List.from(_products);

      if (_searchQuery.isNotEmpty) {
        _filteredProducts = _filteredProducts
            .where((product) => product['title']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();
      }

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
        color: Colors.lightBlue[50],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
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
                                id: product['id'],
                                imagePath: product['imageUrl'] ?? '',
                                title: product['title'] ?? 'Untitled',
                                price:
                                    'Rs. ${(product['pricing'] as num? ?? 0).toStringAsFixed(2)}',
                                product: product,
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

  // Updated product details dialog with modern design
  void _showProductDetails(BuildContext context, Map<String, dynamic> product) {
    int cartQuantity = 0; // Local state to track quantity in the dialog
    String? sellerName; // Variable to hold the seller's name
    bool isLoadingSeller = true; // To show a loading indicator while fetching

    // Fetch seller name from Firestore (sellers collection)
    Future<void> fetchSellerName() async {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(product['userId'])
            .get();
        if (userDoc.exists) {
          sellerName = userDoc.data()?['displayName'] ?? 'Unknown';
        } else {
          sellerName = 'Unknown';
        }
      } catch (e) {
        sellerName = 'Error fetching seller';
      }
      isLoadingSeller = false;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              // Fetch seller name when the dialog is built
              fetchSellerName().then((_) {
                setState(() {
                  // Trigger rebuild after fetching seller name
                });
              });

              return Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image (unchanged)
                        if (product['imageUrl'] != null &&
                            product['imageUrl'].isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                product['imageUrl'],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image,
                                        size: 50, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(Icons.image_not_supported,
                                size: 50, color: Colors.grey),
                          ),
                        const SizedBox(height: 16),

                        // Product Title (unchanged)
                        Text(
                          product['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Price (unchanged)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Price: Rs. ${(product['pricing'] as num? ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Product Details
                        _buildDetailRow(
                          icon: Icons.inventory,
                          label: 'Quantity',
                          value: product['quantity']?.toString() ?? 'N/A',
                        ),
                        _buildDetailRow(
                          icon: Icons.straighten,
                          label: 'Unit',
                          value: product['unit'] ?? 'N/A',
                        ),
                        _buildDetailRow(
                          icon: Icons.description,
                          label: 'Description',
                          value: product['description'] ?? 'No description',
                          isMultiLine: true,
                        ),
                        _buildDetailRow(
                          icon: Icons.category,
                          label: 'Category',
                          value: product['category'] ?? 'N/A',
                        ),
                        _buildDetailRow(
                          icon: Icons.person,
                          label: 'Listed by',
                          value: isLoadingSeller
                              ? 'Loading...' // Show loading while fetching
                              : sellerName ?? 'Unknown',
                        ),
                        const SizedBox(height: 16), // Extra space at the bottom
                      ],
                    ),
                  ),
                  // Close Icon in Top-Right Corner (unchanged)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper method to build detail rows
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment:
            isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: isMultiLine ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
