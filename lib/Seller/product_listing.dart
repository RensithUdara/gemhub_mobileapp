import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ProductListing extends StatefulWidget {
  const ProductListing({super.key});

  @override
  State<ProductListing> createState() => _ProductListingState();
}

class _ProductListingState extends State<ProductListing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final List<File?> _images = List.filled(3, null);
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _pricingController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _isBulkUploading = false;
  bool _isDownloadingTemplate = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    _pricingController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images[index] = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadFirstImage() async {
    if (_auth.currentUser == null) {
      _showErrorDialog('You must be signed in to upload images.');
      return null;
    }

    File? firstImage =
        _images.firstWhere((image) => image != null, orElse: () => null);

    if (firstImage == null) {
      _showErrorDialog('Please select at least one image.');
      return null;
    }

    String fileName =
        'product_images/${DateTime.now().millisecondsSinceEpoch}_${firstImage.path.split('/').last}';

    try {
      SettableMetadata metadata = SettableMetadata(
        cacheControl: 'public,max-age=31536000',
        contentType: 'image/jpeg',
      );

      UploadTask uploadTask =
          _storage.ref(fileName).putFile(firstImage, metadata);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      String errorMessage = 'Error uploading image: ${e.message}';
      if (e.code == 'permission-denied') {
        errorMessage =
            'Permission denied. Check your authentication status or storage rules.';
      }
      _showErrorDialog(errorMessage);
      return null;
    } catch (e) {
      _showErrorDialog('Unexpected error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveProductToFirestore(String? imageUrl) async {
    if (imageUrl == null) {
      _showErrorDialog('Image upload failed. Please try again.');
      return;
    }

    try {
      await _firestore.collection('products').add({
        'title': _titleController.text,
        'category': _selectedCategory,
        'pricing': double.tryParse(_pricingController.text) ?? 0.0,
        'unit': _unitController.text,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid,
      });
    } catch (e) {
      _showErrorDialog('Error saving product: $e');
    }
  }

  Future<void> _downloadCsvTemplate() async {
    try {
      setState(() => _isDownloadingTemplate = true);

      // Define the CSV headers
      List<List<dynamic>> csvData = [
        [
          'title',
          'category',
          'pricing',
          'quantity',
          'unit',
          'description',
          'imageUrl'
        ],
      ];

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get the temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/product_template.csv';
      final file = File(filePath);

      // Write the CSV string to the file
      await file.writeAsString(csv);

      // Share the file
      await Share.shareXFiles([XFile(filePath)],
          text: 'Product Listing CSV Template');
    } catch (e) {
      _showErrorDialog('Error generating CSV template: $e');
    } finally {
      setState(() => _isDownloadingTemplate = false);
    }
  }

  Future<void> _handleBulkUpload() async {
    try {
      setState(() => _isBulkUploading = true);

      // Check if the user is authenticated
      if (_auth.currentUser == null) {
        _showErrorDialog('You must be signed in to upload products.');
        return;
      }

      // Pick the CSV file
      FilePickerResult? csvResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (csvResult == null || csvResult.files.single.path == null) {
        _showErrorDialog('No CSV file selected.');
        setState(() => _isBulkUploading = false);
        return;
      }

      // Read the CSV file
      final csvFile = File(csvResult.files.single.path!);
      final input = await csvFile.readAsString();
      final List<List<dynamic>> csvData =
          const CsvToListConverter().convert(input);

      // Validate CSV headers
      if (csvData.isEmpty) {
        _showErrorDialog('CSV file is empty.');
        setState(() => _isBulkUploading = false);
        return;
      }

      List<String> expectedHeaders = [
        'title',
        'category',
        'pricing',
        'quantity',
        'unit',
        'description',
        'imageUrl'
      ];

      List<String> actualHeaders =
          csvData[0].map((e) => e.toString().trim()).toList();

      // Check number of columns
      if (actualHeaders.length != expectedHeaders.length) {
        _showErrorDialog(
            'Header mismatch: Expected ${expectedHeaders.length} columns but found ${actualHeaders.length} columns.\n\n'
            'Expected headers: ${expectedHeaders.join(", ")}\n'
            'Found headers: ${actualHeaders.join(", ")}');
        setState(() => _isBulkUploading = false);
        return;
      }

      // Check each header for an exact match
      StringBuffer headerErrors = StringBuffer();
      for (int i = 0; i < expectedHeaders.length; i++) {
        if (actualHeaders[i] != expectedHeaders[i]) {
          headerErrors.writeln(
              'Column ${i + 1}: Expected "${expectedHeaders[i]}", but found "${actualHeaders[i]}"');
        }
      }

      if (headerErrors.isNotEmpty) {
        _showErrorDialog(
            'Header mismatch detected:\n\n${headerErrors.toString()}\n\n'
            'Please ensure the CSV headers match exactly: ${expectedHeaders.join(", ")}');
        setState(() => _isBulkUploading = false);
        return;
      }

      // If headers are correct, proceed with data validation
      List<Map<String, dynamic>> products = [];
      StringBuffer errorMessages = StringBuffer();
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.length != 7) {
          errorMessages.writeln(
              'Row ${i + 1}: Invalid number of columns. Expected 7, found ${row.length}');
          continue;
        }

        String title = row[0].toString().trim();
        String category = row[1].toString().trim();
        String pricingStr = row[2].toString().trim();
        String quantityStr = row[3].toString().trim();
        String unit = row[4].toString().trim();
        String description = row[5].toString().trim();
        String imageUrl = row[6].toString().trim();

        // Validate each field
        bool hasErrors = false;
        if (title.isEmpty) {
          errorMessages.writeln('Row ${i + 1}: Title is empty');
          hasErrors = true;
        }
        if (category.isEmpty ||
            !['Blue Sapphires', 'White Sapphires', 'Yellow Sapphires']
                .contains(category)) {
          errorMessages.writeln(
              'Row ${i + 1}: Category is empty or invalid. Must be Blue Sapphires, White Sapphires, or Yellow Sapphires');
          hasErrors = true;
        }
        double? pricing = double.tryParse(pricingStr);
        if (pricingStr.isEmpty || pricing == null) {
          errorMessages.writeln('Row ${i + 1}: Pricing is empty or invalid');
          hasErrors = true;
        }
        int? quantity = int.tryParse(quantityStr);
        if (quantityStr.isEmpty || quantity == null) {
          errorMessages.writeln('Row ${i + 1}: Quantity is empty or invalid');
          hasErrors = true;
        }
        if (description.isEmpty) {
          errorMessages.writeln('Row ${i + 1}: Description is empty');
          hasErrors = true;
        }

        if (!hasErrors) {
          products.add({
            'title': title,
            'category': category,
            'pricing': pricing!,
            'quantity': quantity!,
            'unit': unit,
            'description': description,
            'imageUrl': imageUrl,
            'timestamp': FieldValue.serverTimestamp(),
            'userId': _auth.currentUser!.uid,
          });
        }
      }

      if (products.isEmpty) {
        if (errorMessages.isNotEmpty) {
          _showErrorDialog(
              'Upload failed due to the following errors:\n${errorMessages.toString()}');
        } else {
          _showErrorDialog(
              'No valid products to upload. CSV file contains only headers or all rows are invalid.');
        }
        setState(() => _isBulkUploading = false);
        return;
      }

      // Batch write to Firestore
      WriteBatch batch = _firestore.batch();
      for (var product in products) {
        DocumentReference docRef = _firestore.collection('products').doc();
        batch.set(docRef, product);
      }

      await batch.commit();
      _showSuccessDialog(
          message: 'Successfully uploaded ${products.length} products');
    } catch (e) {
      _showErrorDialog('Error uploading bulk products: $e');
    } finally {
      setState(() => _isBulkUploading = false);
    }
  }

  void _showConfirmationDialog() {
    if (_formKey.currentState!.validate() &&
        _images.any((image) => image != null)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Confirm Listing',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to list this product?',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                String? imageUrl = await _uploadFirstImage();
                if (imageUrl != null) {
                  await _saveProductToFirestore(imageUrl);
                  _showSuccessDialog();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    } else {
      _showErrorDialog('Please fill all fields and upload at least one photo.');
    }
  }

  void _showSuccessDialog({String? message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Success!',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message ?? 'Your product has been listed successfully!',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (message == null) {
                Navigator.pop(
                  context,
                  {
                    'title': _titleController.text,
                    'quantity': int.tryParse(_quantityController.text) ?? 0,
                    'imagePath':
                        _images.firstWhere((image) => image != null)?.path,
                    'type': 'product',
                  },
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Error',
          style: TextStyle(
              color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK'),
          ),
        ],
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
          'Product Listing',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _animation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Photos (select first image to upload)',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          3,
                          (index) => GestureDetector(
                                onTap: () => _pickImage(index),
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey[900]!,
                                        Colors.grey[800]!
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.blue, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: _images[index] != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: Image.file(
                                            _images[index]!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(Icons.camera_alt,
                                              color: Colors.white, size: 40),
                                        ),
                                ),
                              )),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInputField(
                    label: 'Title',
                    hint: 'Enter product title',
                    controller: _titleController,
                    validator: (value) =>
                        value!.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildDropdownField(
                    label: 'Category',
                    hint: 'Select category',
                    value: _selectedCategory,
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                    validator: (value) =>
                        value == null ? 'Category is required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'Pricing',
                    hint: 'Enter price',
                    controller: _pricingController,
                    validator: (value) =>
                        value!.isEmpty ? 'Pricing is required' : null,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'Product quantity',
                    hint: 'Enter quantity',
                    controller: _quantityController,
                    validator: (value) =>
                        value!.isEmpty ? 'Quantity is required' : null,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'Description',
                    hint: 'Enter product description',
                    controller: _descriptionController,
                    validator: (value) =>
                        value!.isEmpty ? 'Description is required' : null,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: ElevatedButton(
                        onPressed: _showConfirmationDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: Colors.blue.withOpacity(0.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ALL DONE, SELL IT',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.check_circle,
                                size: 20, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: ElevatedButton(
                        onPressed: _isBulkUploading ? null : _handleBulkUpload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: Colors.green.withOpacity(0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isBulkUploading
                                  ? 'UPLOADING...'
                                  : 'BULK PRODUCT LISTING',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            _isBulkUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_file,
                                    size: 20, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: ElevatedButton(
                        onPressed: _isDownloadingTemplate
                            ? null
                            : _downloadCsvTemplate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: Colors.orange.withOpacity(0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isDownloadingTemplate
                                  ? 'DOWNLOADING...'
                                  : 'DOWNLOAD CSV TEMPLATE',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            _isDownloadingTemplate
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.download,
                                    size: 20, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[900],
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[900],
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          dropdownColor: Colors.grey[900],
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: const [
            DropdownMenuItem(
                value: 'Blue Sapphires', child: Text('Blue Sapphires')),
            DropdownMenuItem(
                value: 'White Sapphires', child: Text('White Sapphires')),
            DropdownMenuItem(
                value: 'Yellow Sapphires', child: Text('Yellow Sapphires')),
          ],
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
