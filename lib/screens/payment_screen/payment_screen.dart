// payment_screen.dart
import 'package:flutter/material.dart';
import 'package:gemhub/screens/cart_screen/cart_provider.dart';
import 'package:gemhub/screens/order_history_screen/oreder_history_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String address;
  final List<CartItem> cartItems;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.address,
    required this.cartItems,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String paymentMethod = 'Cash on Delivery';
  bool isCardDetailsComplete = false;
  bool _isLoading = false;
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  Future<void> _saveOrderToFirebaseAndClearCart() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place an order')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    DateTime now = DateTime.now();
    DateTime deliveryDate = now.add(const Duration(days: 3));

    final order = {
      'items': widget.cartItems.map((item) => {
            'title': item.title,
            'quantity': item.quantity,
            'price': item.price,
            'totalPrice': item.totalPrice,
          }).toList(),
      'totalAmount': widget.totalAmount,
      'address': widget.address,
      'paymentMethod': paymentMethod,
      'orderDate': DateFormat('yyyy-MM-dd').format(now),
      'deliveryDate': DateFormat('yyyy-MM-dd').format(deliveryDate),
      'status': 'Pending',
      'userId': user.uid,
    };

    try {
      await firestore.collection('orders').add(order);
      cartProvider.clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Payment'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[100]!, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildRadioTile(
                        'Cash on Delivery',
                        Icons.money,
                        'Cash on Delivery',
                      ),
                      const Divider(),
                      _buildRadioTile(
                        'Card Payment',
                        Icons.credit_card,
                        'Card Payment',
                      ),
                    ],
                  ),
                ),
              ),
              if (paymentMethod == 'Card Payment') ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(
                            _cardNumberController, 'Card Number', Icons.credit_card),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                  _expiryController, 'MM/YY', Icons.calendar_today),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                  _cvvController, 'CVV', Icons.lock),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Rs. ${widget.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: (paymentMethod == 'Cash on Delivery' ||
                          isCardDetailsComplete)
                      ? () async {
                          await _saveOrderToFirebaseAndClearCart();
                        }
                      : null,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Complete Order',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioTile(String title, IconData icon, String value) {
    return RadioListTile(
      title: Row(
        children: [
          Icon(icon, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      value: value,
      groupValue: paymentMethod,
      activeColor: Colors.blue[700],
      onChanged: (value) {
        setState(() {
          paymentMethod = value.toString();
          isCardDetailsComplete = paymentMethod == 'Cash on Delivery' ||
              (_cardNumberController.text.isNotEmpty &&
                  _expiryController.text.isNotEmpty &&
                  _cvvController.text.isNotEmpty);
        });
      },
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        setState(() {
          isCardDetailsComplete = _cardNumberController.text.isNotEmpty &&
              _expiryController.text.isNotEmpty &&
              _cvvController.text.isNotEmpty;
        });
      },
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
}