// cart_provider.dart
import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String title;
  final double price;
  int quantity;
  final String imagePath;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    this.quantity = 1,
    required this.imagePath,
  });

  double get totalPrice => price * quantity;
}

class CartProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  double get totalAmount =>
      _cartItems.fold(0, (sum, item) => sum + item.totalPrice);

  void addItem(CartItem item) {
    final existingItemIndex =
        _cartItems.indexWhere((cartItem) => cartItem.id == item.id);
    if (existingItemIndex >= 0) {
      _cartItems[existingItemIndex].quantity += 1;
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  // New method to add a product from a Map
  void addToCart(Map<String, dynamic> product) {
    final cartItem = CartItem(
      id: product['id'] as String,
      title: product['title'] as String,
      price: double.parse(product['price'].toString()),
      imagePath: product['imagePath'] as String,
    );
    addItem(cartItem);
  }

  void removeItem(String id) {
    _cartItems.removeWhere((item) => item.id == id);
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
      removeItem(id);
    }
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}