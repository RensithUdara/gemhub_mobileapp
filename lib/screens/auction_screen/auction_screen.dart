import 'package:flutter/material.dart';
import 'dart:async';

class AuctionScreen extends StatelessWidget {
  const AuctionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            AuctionItemCard(
              imagePath: 'assets/images/gem01.jpg',
              title: 'Natural Emerald 3.5ct',
              currentBid: 150000,
              endTime: Duration(hours: 1),
              minimumIncrement: 500,
            ),
            SizedBox(height: 16),
            AuctionItemCard(
              imagePath: 'assets/images/gem01.jpg',
              title: 'Ruby Gemstone 2.7ct',
              currentBid: 250000,
              endTime: Duration(hours: 2),
              minimumIncrement: 1000,
            ),
            SizedBox(height: 16),
            AuctionItemCard(
              imagePath: 'assets/images/gem01.jpg',
              title: 'Sapphire Gemstone 5.0ct',
              currentBid: 500000,
              endTime: Duration(hours: 3),
              minimumIncrement: 2000,
            ),
          ],
        ),
      ),
    );
  }
}

class AuctionItemCard extends StatefulWidget {
  final String imagePath;
  final String title;
  final int currentBid;
  final Duration endTime;
  final int minimumIncrement;

  const AuctionItemCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.currentBid,
    required this.endTime,
    this.minimumIncrement = 100,
  });

  @override
  _AuctionItemCardState createState() => _AuctionItemCardState();
}

class _AuctionItemCardState extends State<AuctionItemCard> {
  late int _currentBid;
  late Duration _remainingTime;
  late Timer _timer;
  final TextEditingController _bidController = TextEditingController();
  bool _isLoading = false;

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

  Future<void> _placeBid() async {
    final enteredBid = int.tryParse(_bidController.text.trim());
    
    if (enteredBid == null) {
      _showSnackBar('Please enter a valid number');
      return;
    }

    if (enteredBid <= _currentBid) {
      _showSnackBar('Bid must be higher than current bid');
      return;
    }

    if ((enteredBid - _currentBid) < widget.minimumIncrement) {
      _showSnackBar(
          'Bid must be at least Rs. ${widget.minimumIncrement} higher');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bid'),
        content: Text('Place bid of ${_formatCurrency(enteredBid)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      setState(() {
        _isLoading = true;
      });
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _currentBid = enteredBid;
        _isLoading = false;
      });
      _bidController.clear();
      _showSnackBar('Bid placed successfully!');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _formatCurrency(int amount) {
    return 'Rs. ${amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},'
        )}';
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              widget.imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 180,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                color: Colors.grey[300],
                child: const Center(child: Text('Image Not Found')),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Bid: ${_formatCurrency(_currentBid)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Time Remaining: ${_formatTime(_remainingTime)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Min. Increment: ${_formatCurrency(widget.minimumIncrement)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bidController,
                  keyboardType: TextInputType.number,
                  enabled: _remainingTime.inSeconds > 0 && !_isLoading,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[200],
                    labelText: 'Enter Your Bid',
                    labelStyle: const TextStyle(color: Colors.blue),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: (_remainingTime.inSeconds > 0 && !_isLoading)
                        ? _placeBid
                        : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _remainingTime.inSeconds > 0
                                ? 'Place Bid'
                                : 'Auction Closed',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}