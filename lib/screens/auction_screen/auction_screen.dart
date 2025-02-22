import 'package:flutter/material.dart';
import 'dart:async';

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
            currentBid: 150000,
            endTime: Duration(hours: 1), // 1 hour auction
          ),
          AuctionItemCard(
            imagePath: 'assets/images/gem01.jpg',
            title: 'Ruby Gemstone 2.7ct',
            currentBid: 250000,
            endTime: Duration(hours: 2), // 2 hours auction
          ),
          AuctionItemCard(
            imagePath: 'assets/images/gem01.jpg',
            title: 'Sapphire Gemstone 5.0ct',
            currentBid: 500000,
            endTime: Duration(hours: 3), // 3 hours auction
          ),
        ],
      ),
    );
  }
}

class AuctionItemCard extends StatefulWidget {
  final String imagePath;
  final String title;
  final int currentBid;
  final Duration endTime;

  const AuctionItemCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.currentBid,
    required this.endTime,
  });

  @override
  _AuctionItemCardState createState() => _AuctionItemCardState();
}

class _AuctionItemCardState extends State<AuctionItemCard> {
  late int _currentBid;
  late Duration _remainingTime;
  late Timer _timer;
  final TextEditingController _bidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentBid = widget.currentBid;
    _remainingTime = widget.endTime;

    _timer = Timer.periodic(const Duration(seconds: 1), _updateTime);
  }

  void _updateTime(Timer timer) {
    if (_remainingTime.inSeconds > 0) {
      setState(() {
        _remainingTime -= const Duration(seconds: 1);
      });
    } else {
      _timer.cancel();
    }
  }

  void _placeBid() {
    final enteredBid = int.tryParse(_bidController.text);
    if (enteredBid != null && enteredBid > _currentBid) {
      setState(() {
        _currentBid = enteredBid;
      });
      _bidController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a bid higher than the current bid.')),
      );
    }
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer.cancel();
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Image.asset(widget.imagePath, fit: BoxFit.cover, width: 50),
        title: Text(widget.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Bid: Rs. $_currentBid'),
            Text('Time Remaining: ${_formatTime(_remainingTime)}'),
            const SizedBox(height: 8),
            TextField(
              controller: _bidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Your Bid',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: _remainingTime.inSeconds > 0 ? _placeBid : null,
          child: Text(_remainingTime.inSeconds > 0 ? 'Place Bid' : 'Auction Closed'),
        ),
      ),
    );
  }
}
