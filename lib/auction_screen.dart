import 'package:flutter/material.dart';

class AuctionScreen extends StatelessWidget {
  const AuctionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: const [
          AuctionItemCard(
            imagePath: 'assets/images/gem01.jpg',
            title: 'Natural Emerald 3.5ct',
            currentBid: 'Rs. 150,000',
          ),
          AuctionItemCard(
            imagePath: 'assets/images/gem01.jpg',
            title: 'Ruby Gemstone 2.7ct',
            currentBid: 'Rs. 250,000',
          ),
          AuctionItemCard(
            imagePath: 'assets/images/gem01.jpg',
            title: 'Sapphire Gemstone 5.0ct',
            currentBid: 'Rs. 500,000',
          ),
        ],
      ),
    );
  }
}

class AuctionItemCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String currentBid;

  const AuctionItemCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.currentBid,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Image.asset(imagePath, fit: BoxFit.cover, width: 50),
        title: Text(title),
        subtitle: Text('Current Bid: $currentBid'),
        trailing: ElevatedButton(
          onPressed: () {
            // Implement bid action here
          },
          child: const Text('Bid Now'),
        ),
      ),
    );
  }
}
