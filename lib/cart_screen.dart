import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const CartItemCard(
            imagePath: 'assets/images/gem01.jpg',
            title: '4.37ct Natural Blue Sapphire',
            price: 'Rs 4,038,500.00',
            quantity: 1,
          ),
          const CartItemCard(
            imagePath: 'assets/images/gem02.jpg',
            title: '1.17ct Natural Pink Sapphire',
            price: 'Rs.549,000.00',
            quantity: 2,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Implement checkout action here
            },
            child: const Text('Proceed to Checkout'),
          ),
        ],
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String price;
  final int quantity;

  const CartItemCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.price,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Image.asset(imagePath, fit: BoxFit.cover, width: 50),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: $price'),
            Text('Quantity: $quantity'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            // Implement delete item action here
          },
        ),
      ),
    );
  }
}
