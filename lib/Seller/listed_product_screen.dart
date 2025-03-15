import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ListedProductScreen extends StatefulWidget {
  const ListedProductScreen({super.key});

  @override
  _ListedProductScreenState createState() => _ListedProductScreenState();
}

class _ListedProductScreenState extends State<ListedProductScreen> {
  DateTimeRange? _selectedDateRange;

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

  // Method to generate PDF report
  Future<Uint8List> _generatePdfReport(
      List<QueryDocumentSnapshot> products) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');
    double totalValueInRange = 0;
    double allTimeTotalValue = 0;

    // Calculate total value for products in the selected date range (if any)
    for (var product in products) {
      final data = product.data() as Map<String, dynamic>;
      final pricing = data['pricing'] is int
          ? (data['pricing'] as int).toDouble()
          : data['pricing'] as double;
      final quantity = data['quantity'] is int
          ? (data['quantity'] as int).toDouble()
          : data['quantity'] as double;
      totalValueInRange += pricing * quantity;
    }

    // Fetch all products for all-time total value
    final allProductsSnapshot =
        await FirebaseFirestore.instance.collection('products').get();
    for (var product in allProductsSnapshot.docs) {
      final data = product.data();
      final pricing = data['pricing'] is int
          ? (data['pricing'] as int).toDouble()
          : data['pricing'] as double;
      final quantity = data['quantity'] is int
          ? (data['quantity'] as int).toDouble()
          : data['quantity'] as double;
      allTimeTotalValue += pricing * quantity;
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Listed Products Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Date Range: ${_selectedDateRange != null ? '${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}' : 'All Time'}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              'Total Value (Selected Range): Rs. ${totalValueInRange.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              'All-Time Total Value: Rs. ${allTimeTotalValue.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Product Details:',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Title', 'Category', 'Pricing', 'Quantity', 'Total'],
              data: products.map((product) {
                final data = product.data() as Map<String, dynamic>;
                final pricing = data['pricing'] is int
                    ? (data['pricing'] as int).toDouble()
                    : data['pricing'] as double;
                final quantity = data['quantity'] is int
                    ? (data['quantity'] as int).toDouble()
                    : data['quantity'] as double;
                return [
                  data['title'],
                  data['category'],
                  'Rs. ${pricing.toStringAsFixed(2)}',
                  quantity.toString(),
                  'Rs. ${(pricing * quantity).toStringAsFixed(2)}',
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
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'Product_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  // Method to show save/share dialog
  Future<void> _showSaveOrShareDialog(
      List<QueryDocumentSnapshot> products) async {
    final pdfBytes = await _generatePdfReport(products);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text(
              'Download Product Report',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose an option to proceed with your product report:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Text(
              'Products in Range: ${products.length}',
              style: const TextStyle(color: Colors.white60),
            ),
            if (_selectedDateRange != null)
              Text(
                'Date Range: ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)} - ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)}',
                style: const TextStyle(color: Colors.white60),
              ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              final filePath = await _savePdfToStorage(pdfBytes);
              if (Platform.isAndroid || Platform.isIOS) {
                try {
                  Fluttertoast.showToast(
                    msg: 'Saved to $filePath',
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.green.withOpacity(0.9),
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                } catch (e) {
                  print('Toast error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved to $filePath')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved to $filePath')),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename:
                    'Product_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
              );
              if (Platform.isAndroid || Platform.isIOS) {
                try {
                  Fluttertoast.showToast(
                    msg: 'Sharing report...',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.blueAccent.withOpacity(0.9),
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                } catch (e) {
                  print('Toast error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sharing report...')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing report...')),
                );
              }
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Listed Products',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
              final snapshot = await FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('timestamp', descending: true)
                  .get();
              var filteredProducts = snapshot.docs;
              if (_selectedDateRange != null) {
                filteredProducts = filteredProducts.where((product) {
                  final data = product.data();
                  final timestamp = (data['timestamp'] as Timestamp).toDate();
                  return timestamp.isAfter(_selectedDateRange!.start) &&
                      timestamp.isBefore(
                          _selectedDateRange!.end.add(const Duration(days: 1)));
                }).toList();
              }
              await _showSaveOrShareDialog(filteredProducts);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: Colors.blue, strokeWidth: 3));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        color: Colors.white70, size: 60),
                    SizedBox(height: 16),
                    Text(
                      'No products listed yet',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }

            var products = snapshot.data!.docs;
            if (_selectedDateRange != null) {
              products = products.where((product) {
                final data = product.data() as Map<String, dynamic>;
                final timestamp = (data['timestamp'] as Timestamp).toDate();
                return timestamp.isAfter(_selectedDateRange!.start) &&
                    timestamp.isBefore(
                        _selectedDateRange!.end.add(const Duration(days: 1)));
              }).toList();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                var product = products[index];
                return ProductCard(
                  docId: product.id,
                  title: product['title'],
                  pricing: product['pricing'].toString(),
                  quantity: product['quantity'].toString(),
                  imageUrl: product['imageUrl'],
                  category: product['category'],
                  description: product['description'],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final String docId;
  final String title;
  final String pricing;
  final String quantity;
  final String imageUrl;
  final String category;
  final String description;

  const ProductCard({
    super.key,
    required this.docId,
    required this.title,
    required this.pricing,
    required this.quantity,
    required this.imageUrl,
    required this.category,
    required this.description,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: widget.title);
    final pricingController = TextEditingController(text: widget.pricing);
    final quantityController = TextEditingController(text: widget.quantity);
    final descriptionController =
        TextEditingController(text: widget.description);
    String? selectedCategory = widget.category;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Product',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Title', titleController),
              const SizedBox(height: 12),
              _buildDropdownField('Category', selectedCategory, (value) {
                selectedCategory = value;
              }),
              const SizedBox(height: 12),
              _buildTextField(
                  'Pricing', pricingController, TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(
                  'Quantity', quantityController, TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField('Description', descriptionController, null, 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(widget.docId)
                    .update({
                  'title': titleController.text,
                  'pricing': double.parse(pricingController.text),
                  'quantity': int.parse(quantityController.text),
                  'category': selectedCategory,
                  'description': descriptionController.text,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Product updated successfully'),
                      backgroundColor: Colors.green),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error updating product: $e'),
                      backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      [TextInputType? keyboardType, int maxLines = 1]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue)),
      ),
    );
  }

  Widget _buildDropdownField(
      String label, String? value, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue)),
      ),
      dropdownColor: Colors.grey[900],
      style: const TextStyle(color: Colors.white),
      items: const [
        DropdownMenuItem(
            value: 'Blue Sapphires', child: Text('Blue Sapphires')),
        DropdownMenuItem(
            value: 'White Sapphires', child: Text('White Sapphires')),
        DropdownMenuItem(
            value: 'Yellow Sapphires', child: Text('Yellow Sapphires')),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.grey[850]!, Colors.grey[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Hero(
            tag: widget.imageUrl,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[800],
                    child: const Icon(Icons.broken_image,
                        color: Colors.white54, size: 40),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[800],
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
                  widget.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    widget.category,
                    style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontWeight: FontWeight.w400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Rs. ${widget.pricing}',
                        style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              'Qty: ${widget.quantity}',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showEditDialog(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.edit,
                                  color: Colors.blue, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
