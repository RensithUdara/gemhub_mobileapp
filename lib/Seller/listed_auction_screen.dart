import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class ListedAuctionScreen extends StatefulWidget {
  const ListedAuctionScreen({super.key});

  @override
  State<ListedAuctionScreen> createState() => _ListedAuctionScreenState();
}

class _ListedAuctionScreenState extends State<ListedAuctionScreen> {
  String _searchQuery = '';
  String _sortOrder = 'asc'; // Default sorting order by current bid
  List<Map<String, dynamic>> _auctions = [];
  List<Map<String, dynamic>> _filteredAuctions = [];
  bool _isLoading = true;

  final CollectionReference _auctionsCollection =
      FirebaseFirestore.instance.collection('auctions');

  // Fetch all auctions
  void _fetchAuctions() {
    _auctionsCollection.snapshots().listen((snapshot) {
      setState(() {
        _auctions = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        _applyFilters();
        _isLoading = false;
      });
    }, onError: (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching auctions: $error')),
      );
    });
  }

  // Apply sorting and search filtering
  void _applyFilters() {
    setState(() {
      _filteredAuctions = _auctions
          .where((auction) => auction['title']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();

      _filteredAuctions.sort((a, b) {
        final aBid = a['currentBid'] as num? ?? 0;
        final bBid = b['currentBid'] as num? ?? 0;
        return _sortOrder == 'asc'
            ? aBid.compareTo(bBid)
            : bBid.compareTo(aBid);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchAuctions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: const Text(
          'Listed Auctions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          // Sort Button
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortOrder = value;
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'asc',
                child: Text('Bid: Low to High'),
              ),
              const PopupMenuItem(
                value: 'desc',
                child: Text('Bid: High to Low'),
              ),
            ],
            icon: const Icon(Icons.sort, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        color: Colors.lightBlue[50],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Search Bar
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                hintText: 'Search auctions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                filled: true,
                fillColor: Colors.blue[50],
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              ),
            ),
            const SizedBox(height: 20),
            // Auction Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredAuctions.isEmpty
                      ? const Center(child: Text('No auctions found.'))
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                          itemCount: _filteredAuctions.length,
                          itemBuilder: (context, index) {
                            final auction = _filteredAuctions[index];
                            return GestureDetector(
                              onTap: () {
                                _showAuctionDetails(context, auction);
                              },
                              child: AuctionCard(
                                imagePath: auction['imagePath'] ?? '',
                                title: auction['title'] ?? 'Untitled',
                                currentBid:
                                    'Rs. ${(auction['currentBid'] as num? ?? 0).toStringAsFixed(2)}',
                                endTime: auction['endTime'] != null
                                    ? DateFormat('yyyy-MM-dd HH:mm')
                                        .format(DateTime.parse(auction['endTime']))
                                    : 'N/A',
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Show auction details in a dialog
  void _showAuctionDetails(BuildContext context, Map<String, dynamic> auction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(auction['title'] ?? 'Untitled'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (auction['imagePath'] != null && auction['imagePath'].isNotEmpty)
                Image.network(
                  auction['imagePath'],
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error),
                ),
              const SizedBox(height: 10),
              Text(
                  'Current Bid: Rs. ${(auction['currentBid'] as num? ?? 0).toStringAsFixed(2)}'),
              Text(
                  'Minimum Increment: Rs. ${(auction['minimumIncrement'] as num? ?? 0).toStringAsFixed(2)}'),
              Text(
                  'End Time: ${auction['endTime'] != null ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(auction['endTime'])) : 'N/A'}'),
              const SizedBox(height: 10),
              Text(
                  'Payment Status: ${auction['paymentStatus'] ?? 'Pending'}'),
              Text('Winning User: ${auction['winningUserId'] ?? 'None'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// AuctionCard widget (you can customize this further)
class AuctionCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String currentBid;
  final String endTime;

  const AuctionCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.currentBid,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: imagePath.isNotEmpty
                ? Image.network(
                    imagePath,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error),
                  )
                : Container(
                    height: 120,
                    color: Colors.grey,
                    child: const Icon(Icons.image_not_supported),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  currentBid,
                  style: const TextStyle(color: Colors.green, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ends: $endTime',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}