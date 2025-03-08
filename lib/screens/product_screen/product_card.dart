import 'package:flutter/material.dart';
import 'package:gemhub/screens/cart_screen/cart_provider.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String price;
  final String id;
  final Map<String, dynamic> product;

  const ProductCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.price,
    required this.id,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartItem = cartProvider.cartItems.firstWhere(
          (item) => item.id == id,
          orElse: () => CartItem(
            id: id,
            imagePath: '',
            title: '',
            price: 0,
            quantity: 0, // Explicitly set to 0 for non-existent items
          ),
        );
        final int quantity = cartItem.quantity;

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 180,
            height: 280,
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              shadowColor: Colors.black.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Image.network(
                      imagePath,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 120),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          quantity == 0
                              ? SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      cartProvider.addToCart(product);
                                    },
                                    child: const Text("Add to Cart"),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove,
                                            color: Colors.blue),
                                        onPressed: () =>
                                            cartProvider.decrementQuantity(id),
                                      ),
                                      Text(
                                        "$quantity",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add,
                                            color: Colors.blue),
                                        onPressed: () =>
                                            cartProvider.incrementQuantity(id),
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
