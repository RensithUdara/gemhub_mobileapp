import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String imagePath;
  final String title;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.price,
    this.quantity = 1, // Default to 1, but allow override
  });

  double get totalPrice => price * quantity;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  void addToCart(Map<String, dynamic> product) {
    final existingItemIndex =
        _cartItems.indexWhere((item) => item.id == product['id']);
    if (existingItemIndex != -1) {
      _cartItems[existingItemIndex].quantity++;
    } else {
      _cartItems.add(CartItem(
        id: product['id'],
        imagePath: product['imageUrl'] ?? '',
        title: product['title'] ?? 'Untitled',
        price: (product['pricing'] as num? ?? 0).toDouble(),
      ));
    }
    notifyListeners();
  }

  void incrementQuantity(String id) {
    final item = _cartItems.firstWhere((item) => item.id == id);
    item.quantity++;
    notifyListeners();
  }

  void decrementQuantity(String id) {
    final item = _cartItems.firstWhere((item) => item.id == id);
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _cartItems.removeWhere((item) => item.id == id);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _cartItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  double get totalAmount {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }
}
