import 'dart:io'; // For file operations
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemhub/Seller/order_details_screen.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // For PDF generation
import 'package:printing/printing.dart'; // For printing/sharing PDF
import 'package:path_provider/path_provider.dart'; // For internal storage access

class SellerOrderHistoryScreen extends StatefulWidget {
  const SellerOrderHistoryScreen({super.key});

  @override
  _SellerOrderHistoryScreenState createState() => _SellerOrderHistoryScreenState();
}

class _SellerOrderHistoryScreenState extends State<SellerOrderHistoryScreen> {
  DateTimeRange? _selectedDateRange;

  // Helper method to check if order is overdue
  bool isOrderOverdue(Map<String, dynamic> order) {
    final deliveryDateStr = order['deliveryDate'] as String;
    final status = order['status'] as String;

    try {
      final deliveryDate = DateTime.parse(deliveryDateStr);
      final currentDate = DateTime.now();
      return currentDate.isAfter(deliveryDate) && status.toLowerCase() != 'delivered';
    } catch (e) {
      return false;
    }
  }

  // Method to generate PDF report
  Future<Uint8List> _generatePdfReport(List<QueryDocumentSnapshot> orders) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');
    double totalIncome = 0;

    // Calculate total income
    for (var order in orders) {
      final data = order.data() as Map<String, dynamic>;
      final amount = data['totalAmount'];
      totalIncome += (amount is int ? amount.toDouble() : amount as double);
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Order History Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Date Range: ${dateFormat.format(_selectedDateRange?.start ?? DateTime.now())} - ${dateFormat.format(_selectedDateRange?.end ?? DateTime.now())}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              'Total Income: Rs. ${totalIncome.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Order ID', 'Status', 'Total Amount', 'Delivery Date'],
              data: orders.map((order) {
                final data = order.data() as Map<String, dynamic>;
                return [
                  order.id.substring(0, 8),
                  data['status'],
                  'Rs. ${(data['totalAmount'] is int ? (data['totalAmount'] as int).toDouble() : data['totalAmount'] as double).toStringAsFixed(2)}',
                  data['deliveryDate'],
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // Method to save PDF to internal storage
  Future<String> _savePdfToStorage(Uint8List pdfBytes) async {
    final directory = await getApplicationDocumentsDirectory(); // App's documents directory
    final fileName = 'Order_History_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path; // Return the file path for feedback
  }

  // Method to show save/share dialog
  Future<void> _showSaveOrShareDialog(List<QueryDocumentSnapshot> orders) async {
    final pdfBytes = await _generatePdfReport(orders);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save or Share Report'),
        content: const Text('Would you like to save the report to internal storage or share it?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              final filePath = await _savePdfToStorage(pdfBytes);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Report saved to: $filePath')),
              );
            },
            child: const Text('Save to Storage'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: 'Order_History_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  // Method to pick date range
  Future<void> _pickDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange ?? initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.grey,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDateRange != null) {
      setState(() {
        _selectedDateRange = newDateRange;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        title: const Text(
          'Order History',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: () => _pickDateRange(context),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () async {
              final snapshot = await FirebaseFirestore.instance.collection('orders').get();
              await _showSaveOrShareDialog(snapshot.docs);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.grey[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
              }
              if (snapshot.hasError) {
                return const Center(
                    child: Text('Error loading orders', style: TextStyle(color: Colors.white)));
              }

              var orders = snapshot.data!.docs;
              if (_selectedDateRange != null) {
                orders = orders.where((order) {
                  final data = order.data() as Map<String, dynamic>;
                  final orderDate = DateTime.parse(data['deliveryDate']);
                  return orderDate.isAfter(_selectedDateRange!.start) &&
                      orderDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
                }).toList();
              }

              if (orders.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, color: Colors.white70, size: 60),
                      SizedBox(height: 16),
                      Text('No orders found', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index].data() as Map<String, dynamic>;
                  final orderId = orders[index].id;
                  final isOverdue = isOrderOverdue(order);

                  return Card(
                    elevation: 4,
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOverdue
                              ? [Colors.red[800]!, Colors.red[900]!]
                              : [Colors.grey[850]!, Colors.grey[900]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOverdue ? Colors.red.withOpacity(0.5) : Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text('Order #${orderId.substring(0, 8)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('Status: ${order['status']}',
                                style: const TextStyle(color: Colors.white60)),
                            Text('Total: Rs. ${order['totalAmount'].toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white60)),
                            Text('Delivery: ${order['deliveryDate']}',
                                style: const TextStyle(color: Colors.white60)),
                          ],
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: isOverdue ? Colors.white : Colors.blueAccent,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsScreen(orderId: orderId),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}