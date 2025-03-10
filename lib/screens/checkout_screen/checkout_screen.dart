import 'package:flutter/material.dart';
import 'package:gemhub/screens/cart_screen/cart_provider.dart';
import 'package:gemhub/screens/payment_screen/payment_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _deliveryNoteController = TextEditingController();
  final double deliveryCharge = 400.0;
  bool _saveDetails = false;

  @override
  void initState() {
    super.initState();
    _loadSavedDetails(); // Load saved details when screen initializes
  }

  // Load saved details from SharedPreferences
  Future<void> _loadSavedDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('name') ?? '';
      _mobileController.text = prefs.getString('mobile') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _addressController.text =
          prefs.getString('address') ?? '123 Main Street, Colombo';
      _deliveryNoteController.text = prefs.getString('deliveryNote') ?? '';
    });
  }

  // Save details to SharedPreferences
  Future<void> _saveUserDetails() async {
    if (_saveDetails) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', _nameController.text);
      await prefs.setString('mobile', _mobileController.text);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('address', _addressController.text);
      await prefs.setString('deliveryNote', _deliveryNoteController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final double totalWithDelivery = cartProvider.totalAmount + deliveryCharge;

    return Scaffold(
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
        elevation: 6,
        shadowColor: Colors.black38,
        title: const Text(
          'Checkout',
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[100]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderSummary(context, cartProvider),
                const SizedBox(height: 20),
                _buildPriceDetails(totalWithDelivery, cartProvider),
                const SizedBox(height: 20),
                _buildUserDetailsSection(),
                const SizedBox(height: 24),
                _buildProceedButton(context, totalWithDelivery, cartProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Order Summary (unchanged)
  Widget _buildOrderSummary(BuildContext context, CartProvider cartProvider) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
            ),
            const SizedBox(height: 16),
            ...cartProvider.cartItems.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.imagePath,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            width: 60,
                            height: 60,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Qty: ${item.quantity}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Price Details (unchanged)
  Widget _buildPriceDetails(
      double totalWithDelivery, CartProvider cartProvider) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildPriceRow('Subtotal', cartProvider.totalAmount),
            const SizedBox(height: 12),
            _buildPriceRow('Delivery Charge', deliveryCharge),
            const Divider(height: 24, thickness: 1),
            _buildPriceRow('Total', totalWithDelivery, isTotal: true),
          ],
        ),
      ),
    );
  }

  // Updated User Details Section
  Widget _buildUserDetailsSection() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
            ),
            const SizedBox(height: 16),
            _buildTextField(_nameController, 'Full Name', Icons.person),
            const SizedBox(height: 12),
            _buildTextField(_mobileController, 'Mobile Number', Icons.phone,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildTextField(_emailController, 'Email Address', Icons.email,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _buildTextField(
                _addressController, 'Delivery Address', Icons.location_on,
                maxLines: 3),
            const SizedBox(height: 12),
            _buildTextField(
                _deliveryNoteController, 'Delivery Note (Optional)', Icons.note,
                maxLines: 2),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _saveDetails,
                  onChanged: (value) {
                    setState(() {
                      _saveDetails = value!;
                    });
                  },
                ),
                const Text('Save details for future use'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build text fields
  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  // Proceed Button (updated to include new fields)
  Widget _buildProceedButton(BuildContext context, double totalWithDelivery,
      CartProvider cartProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () {
          if (_nameController.text.isEmpty ||
              _mobileController.text.isEmpty ||
              _emailController.text.isEmpty ||
              _addressController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please fill in all required fields')),
            );
            return;
          }
          _saveUserDetails(); // Save details if checkbox is checked
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                totalAmount: totalWithDelivery,
                address: _addressController.text,
                cartItems: cartProvider.cartItems,
                name: _nameController.text,
                mobile: _mobileController.text,
                email: _emailController.text,
                deliveryNote: _deliveryNoteController.text,
              ),
            ),
          );
        },
        child: const Text(
          'Proceed to Payment',
          style: TextStyle(
              fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Price Row (unchanged)
  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 20 : 16,
          ),
        ),
        Text(
          'Rs. ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 20 : 16,
            color: isTotal ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _deliveryNoteController.dispose();
    super.dispose();
  }
}
