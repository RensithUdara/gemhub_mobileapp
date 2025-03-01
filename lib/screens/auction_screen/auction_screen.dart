import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuctionScreen extends StatelessWidget {
  const AuctionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Luxury Auction',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 26,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[900]!, Colors.blue[700]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('auctions')
            .orderBy('endTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final auctions = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: ListView(
              children: [
                const Text(
                  'Live Bidding',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 16),
                ...auctions.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: AuctionItemCard(
                      auctionId: doc.id,
                      imagePath: data['imagePath'],
                      title: data['title'],
                      currentBid: data['currentBid'],
                      endTime: DateTime.parse(data['endTime']),
                      minimumIncrement: data['minimumIncrement'],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AuctionItemCard extends StatefulWidget {
  final String auctionId;
  final String imagePath;
  final String title;
  final int currentBid;
  final DateTime endTime;
  final int minimumIncrement;

  const AuctionItemCard({
    super.key,
    required this.auctionId,
    required this.imagePath,
    required this.title,
    required this.currentBid,
    required this.endTime,
    required this.minimumIncrement,
  });

  @override
  _AuctionItemCardState createState() => _AuctionItemCardState();
}

class _AuctionItemCardState extends State<AuctionItemCard>
    with SingleTickerProviderStateMixin {
  late int _currentBid;
  late Duration _remainingTime;
  late Timer _timer;
  final TextEditingController _bidController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _bidAnimation;
  String? _winningUserId;
  late StreamSubscription<DocumentSnapshot> _auctionSubscription;

  @override
  void initState() {
    super.initState();
    _currentBid = widget.currentBid;
    _remainingTime = widget.endTime.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), _updateTime);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bidAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    _auctionSubscription = FirebaseFirestore.instance
        .collection('auctions')
        .doc(widget.auctionId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _currentBid = data['currentBid'];
          _winningUserId = data['winningUserId'];
        });
        if (data['currentBid'] > widget.currentBid) {
          _animationController.forward(from: 0.0);
        }
      }
    });
  }

  void _updateTime(Timer timer) {
    final now = DateTime.now();
    if (widget.endTime.isAfter(now)) {
      setState(() {
        _remainingTime = widget.endTime.difference(now);
      });
    } else {
      _timer.cancel();
    }
  }

Future<void> _placeBid() async {
  final enteredBid = int.tryParse(_bidController.text.trim());
  final currentUser = FirebaseAuth.instance.currentUser;

  print("Current user: ${currentUser?.uid}");
  if (currentUser == null) {
    _showSnackBar('Please log in to bid');
    return;
  }

  if (enteredBid == null) {
    _showSnackBar('Please enter a valid number');
    return;
  }

  if (enteredBid <= _currentBid) {
    _showSnackBar('Bid must exceed current bid');
    return;
  }

  if ((enteredBid - _currentBid) < widget.minimumIncrement) {
    _showSnackBar(
        'Minimum increment: ${_formatCurrency(widget.minimumIncrement)}');
    return;
  }

  // Check if auction document exists
  final doc = await FirebaseFirestore.instance
      .collection('auctions')
      .doc(widget.auctionId)
      .get();
  if (!doc.exists) {
    _showSnackBar('Auction not found');
    return;
  }
  print("Document data: ${doc.data()}");

  // Confirmation dialog (unchanged)
  final confirm = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[400]!],
                ),
              ),
              child: const Icon(
                Icons.gavel,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Confirm Bid',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Place bid of:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(enteredBid),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 6,
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (confirm ?? false) {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('auctions')
          .doc(widget.auctionId)
          .update({
        'currentBid': enteredBid,
        'winningUserId': currentUser.uid,
        'lastBidTime': FieldValue.serverTimestamp(),
      });
      setState(() {
        _currentBid = enteredBid;
        _winningUserId = currentUser.uid;
        _isLoading = false;
      });
      _bidController.clear();
      _showSnackBar('Bid placed successfully!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error placing bid: $e');
    }
  }
}

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('auctions')
          .doc(widget.auctionId)
          .update({
        'paymentStatus': 'pending',
        'paymentInitiatedAt': FieldValue.serverTimestamp(),
      });
      setState(() => _isLoading = false);
      _showSnackBar('Payment processing initiated!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Payment error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.blue[800],
        elevation: 6,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

String _formatTime(Duration duration) {
  if (duration.inSeconds <= 0) {
    return '00d : 00h : 00m : 00s';
  }
  
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  
  final days = duration.inDays;
  final hours = twoDigits(duration.inHours.remainder(24));
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  
  return '${days}d : ${hours}h : ${minutes}m : ${seconds}s';
}

  String _formatCurrency(int amount) {
    return 'Rs.${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  void dispose() {
    _auctionSubscription.cancel();
    _timer.cancel();
    _bidController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isAuctionActive = _remainingTime.inSeconds > 0;
    bool isCurrentUserWinner = 
        _winningUserId == FirebaseAuth.instance.currentUser?.uid;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            isAuctionActive ? Colors.blue[50]! : Colors.grey[100]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                Image.asset(
                  widget.imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 220,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAuctionActive
                            ? [Colors.green[600]!, Colors.green[400]!]
                            : [Colors.red[600]!, Colors.red[400]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAuctionActive ? 'LIVE' : 'ENDED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lot #${widget.title.hashCode.toString().substring(0, 4)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ScaleTransition(
                  scale: _bidAnimation,
                  child: Row(
                    children: [
                      Icon(Icons.gavel, color: Colors.green[700], size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Current Bid: ${_formatCurrency(_currentBid)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: _remainingTime.inSeconds < 300
                          ? Colors.red[700]
                          : Colors.grey[600],
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Time Left: ${_formatTime(_remainingTime)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _remainingTime.inSeconds < 300
                            ? Colors.red[700]
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: Colors.grey[600], size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Min. Inc: ${_formatCurrency(widget.minimumIncrement)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (!isAuctionActive && _winningUserId != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCurrentUserWinner
                            ? [Colors.green[100]!, Colors.green[50]!]
                            : [Colors.grey[200]!, Colors.grey[100]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCurrentUserWinner ? Icons.celebration : Icons.info,
                          color: isCurrentUserWinner
                              ? Colors.green[800]
                              : Colors.grey[800],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isCurrentUserWinner
                                ? 'You Won! Congratulations!'
                                : 'Won by another bidder',
                            style: TextStyle(
                              color: isCurrentUserWinner
                                  ? Colors.green[800]
                                  : Colors.grey[800],
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (isAuctionActive) ...[
                  TextField(
                    controller: _bidController,
                    keyboardType: TextInputType.number,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
                      hintText: 'Enter your bid',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon:
                          Icon(Icons.monetization_on, color: Colors.blue[600]),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400]),
                        onPressed: () => _bidController.clear(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.blue[200]!, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.blue[700]!, width: 2),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _getButtonAction(),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: isAuctionActive ||
                              (isCurrentUserWinner && !isAuctionActive)
                          ? Colors.blue[700]
                          : Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!isAuctionActive && isCurrentUserWinner)
                                const Icon(Icons.payment, size: 20),
                              if (!isAuctionActive && isCurrentUserWinner)
                                const SizedBox(width: 8),
                              Text(
                                _getButtonText(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
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

  String _getButtonText() {
    if (_remainingTime.inSeconds > 0) {
      return 'Place Bid';
    } else if (_winningUserId == FirebaseAuth.instance.currentUser?.uid) {
      return 'Pay Now';
    } else {
      return 'Auction Ended';
    }
  }

  VoidCallback? _getButtonAction() {
    if (_remainingTime.inSeconds > 0 && !_isLoading) {
      return _placeBid;
    } else if (_winningUserId == FirebaseAuth.instance.currentUser?.uid &&
        !_isLoading) {
      return _handlePayment;
    } else {
      return null;
    }
  }
}