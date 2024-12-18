import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Method to add a product to Firestore
  Future<void> addProduct(String title, double price, String imagePath) async {
    try {
      await _db.collection('products').add({
        'title': title,
        'price': price,
        'imagePath': imagePath,
      });
    } catch (e) {
      print("Error adding product: $e");
    }
  }

  // Method to fetch products from Firestore
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      QuerySnapshot snapshot = await _db.collection('products').get();
      return snapshot.docs
          .map((doc) => {
                'title': doc['title'],
                'price': doc['price'],
                'imagePath': doc['imagePath'],
              })
          .toList();
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }
}
