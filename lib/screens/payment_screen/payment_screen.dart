// payment_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gemhub/screens/cart_screen/cart_provider.dart';
import 'package:gemhub/screens/order_history_screen/oreder_history_screen.dart';
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
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  void _saveOrderToFirebase() async {
    final firestore = FirebaseFirestore.instance;
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
    };

    await firestore.collection('orders').add(order);
  }

  @override
  Widget build(BuildContext context) {
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
            elevation: 4,
            shadowColor: Colors.black26,
            title: const Text(
              'Payment',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_cardNumberController, 'Card Number', Icons.credit_card),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(_expiryController, 'MM/YY', Icons.calendar_today),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(_cvvController, 'CVV', Icons.lock),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Rs. ${widget.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
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
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: (paymentMethod == 'Cash on Delivery' || isCardDetailsComplete)
                      ? () {
                          _saveOrderToFirebase();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                          );
                        }
                      : null,
                  child: const Text('Complete Order',
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
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
}