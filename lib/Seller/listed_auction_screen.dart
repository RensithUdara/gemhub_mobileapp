import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ListedAuctionScreen extends StatelessWidget {
  final String sellerId;

  const ListedAuctionScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    // Get current user ID for additional verification
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    print('Passed sellerId: $sellerId');
    print('Current Firebase user ID: $currentUserId');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        title: const Text(
          'Listed Auctions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('auctions')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.blue,
                  strokeWidth: 3,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gavel_outlined, color: Colors.white70, size: 60),
                    SizedBox(height: 16),
                    Text(
                      'No auctions listed yet',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var auction = snapshot.data!.docs[index];
                Map<String, dynamic> auctionData =
                    auction.data() as Map<String, dynamic>;

                // Enhanced debugging
                print('Auction ID: ${auction.id}');
                print('Auction data: $auctionData');
                bool hasSellerId = auctionData.containsKey('sellerId');
                print('Has sellerId field: $hasSellerId');
                if (hasSellerId) {
                  print('Auction sellerId: ${auctionData['sellerId']}');
                }

                bool isSeller =
                    hasSellerId && auctionData['sellerId'] == sellerId;
                print('isSeller for ${auction.id}: $isSeller');

                return AuctionCard(
                  title: auctionData['title'] ?? 'Untitled',
                  currentBid: auctionData['currentBid']?.toString() ?? '0',
                  endTime: DateTime.parse(auctionData['endTime'] ??
                      DateTime.now().toIso8601String()),
                  imageUrl: auctionData['imagePath'] ?? '',
                  minimumIncrement:
                      auctionData['minimumIncrement']?.toString() ?? '0',
                  auctionId: auction.id,
                  isSeller: isSeller,
                  onTap: () {
                    // Add navigation to detail screen if needed
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AuctionCard extends StatelessWidget {
  final String title;
  final String currentBid;
  final DateTime endTime;
  final String imageUrl;
  final String minimumIncrement;
  final VoidCallback onTap;
  final String auctionId;
  final bool isSeller;

  const AuctionCard({
    super.key,
    required this.title,
    required this.currentBid,
    required this.endTime,
    required this.imageUrl,
    required this.minimumIncrement,
    required this.onTap,
    required this.auctionId,
    required this.isSeller,
  });

  String _formatEndTime(DateTime endTime) {
    return DateFormat('MMM d, yyyy - HH:mm').format(endTime.toLocal());
  }

  String _getTimeRemaining() {
    final now = DateTime.now();
    final difference = endTime.difference(now);
    if (difference.isNegative) {
      return 'Ended';
    }
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    if (days > 0) {
      return '$days:${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  void _showEditDialog(BuildContext context) {
    print('Edit button pressed for auction: $auctionId');
    showDialog(
      context: context,
      builder: (context) => EditEndTimeDialog(
        auctionId: auctionId,
        currentEndTime: endTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[850]!, Colors.grey[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Hero(
              tag: imageUrl,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 40,
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.blue,
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Min Inc: Rs. $minimumIncrement',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ends: ${_formatEndTime(endTime)}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSeller)
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.blueAccent, size: 20),
                          onPressed: () => _showEditDialog(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs. $currentBid',
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getTimeRemaining(),
                          style: TextStyle(
                            color: endTime.isBefore(DateTime.now())
                                ? Colors.redAccent
                                : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditEndTimeDialog extends StatefulWidget {
  final String auctionId;
  final DateTime currentEndTime;

  const EditEndTimeDialog({
    super.key,
    required this.auctionId,
    required this.currentEndTime,
  });

  @override
  State<EditEndTimeDialog> createState() => _EditEndTimeDialogState();
}

class _EditEndTimeDialogState extends State<EditEndTimeDialog> {
  late DateTime selectedDateTime;

  @override
  void initState() {
    super.initState();
    selectedDateTime = widget.currentEndTime;
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _updateEndTime() async {
    try {
      print(
          'Updating auction ${widget.auctionId} with new end time: $selectedDateTime');
      await FirebaseFirestore.instance
          .collection('auctions')
          .doc(widget.auctionId)
          .update({
        'endTime': selectedDateTime.toIso8601String(),
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time updated successfully')),
      );
    } catch (e) {
      print('Error updating end time: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating end time: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('Edit End Time', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current: ${DateFormat('MMM d, yyyy - HH:mm').format(selectedDateTime)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _selectDateTime(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
            ),
            child: const Text('Select New Date & Time'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: _updateEndTime,
          child: const Text('Save', style: TextStyle(color: Colors.blueAccent)),
        ),
      ],
    );
  }
}
