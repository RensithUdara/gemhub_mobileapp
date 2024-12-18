import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'product_provider.dart';
import 'widget/product_card.dart'; // Your ProductCard widget

class CategoryScreen extends StatefulWidget {
  final String categoryTitle;

  const CategoryScreen({super.key, required this.categoryTitle});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _selectedSortOption = 'Price low to high';

  @override
  void initState() {
    super.initState();
    // Fetch products when the screen loads
    Future.delayed(Duration.zero, () {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
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
                    });
                    // Trigger the sorting in the provider
                    if (newValue == 'Price low to high') {
                      Provider.of<ProductProvider>(context, listen: false)
                          .sortProductsByPriceLowToHigh();
                    } else if (newValue == 'Price high to low') {
                      Provider.of<ProductProvider>(context, listen: false)
                          .sortProductsByPriceHighToLow();
                    }
                  },
                  dropdownColor: Colors.blue[50],
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                  underline: const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Product Grid
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                final products = productProvider.products;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      imagePath: products[index].imagePath,
                      title: products[index].title,
                      price: 'Rs. ${products[index].price}',
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
