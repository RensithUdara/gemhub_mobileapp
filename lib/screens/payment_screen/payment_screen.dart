import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  bool saveCard = false;
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  // Simulated saved cards (replace with actual storage in production)
  List<Map<String, String>> savedCards = [
    {'number': '**** **** **** 1234', 'expiry': '12/25', 'type': 'Visa'},
  ];
  String? selectedSavedCard;

  void _saveOrderToFirebase() async {
    final firestore = FirebaseFirestore.instance;
    DateTime now = DateTime.now();
    DateTime deliveryDate = now.add(const Duration(days: 3));

    final order = {
      'items': widget.cartItems
          .map((item) => {
                'title': item.title,
                'quantity': item.quantity,
                'price': item.price,
                'totalPrice': item.totalPrice,
              })
          .toList(),
      'totalAmount': widget.totalAmount,
      'address': widget.address,
      'paymentMethod': paymentMethod,
      'orderDate': DateFormat('yyyy-MM-dd').format(now),
      'deliveryDate': DateFormat('yyyy-MM-dd').format(deliveryDate),
      'status': 'Pending',
    };

    await firestore.collection('orders').add(order);

    if (saveCard &&
        paymentMethod == 'Card Payment' &&
        selectedSavedCard == null) {
      setState(() {
        savedCards.add({
          'number':
              '**** **** **** ${_cardNumberController.text.substring(_cardNumberController.text.length - 4)}',
          'expiry': _expiryController.text,
          'type': _getCardType(_cardNumberController.text),
        });
      });
    }
  }

  String _getCardType(String cardNumber) {
    if (cardNumber.startsWith('4')) return 'Visa';
    if (cardNumber.startsWith('5')) return 'Mastercard';
    return 'Unknown';
  }

  void _formatExpiryDate(String value) {
    if (value.length == 2 && !value.contains('/')) {
      _expiryController.text = '$value/';
      _expiryController.selection = TextSelection.fromPosition(
        TextPosition(offset: _expiryController.text.length),
      );
    }
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
        elevation: 6,
        shadowColor: Colors.black38,
        title: const Text(
          'Payment',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
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
                _buildPaymentOptions(),
                if (paymentMethod == 'Card Payment') ...[
                  const SizedBox(height: 20),
                  if (savedCards.isNotEmpty) _buildSavedCards(),
                  const SizedBox(height: 20),
                  if (selectedSavedCard == null) _buildCardDetailsInput(),
                ],
                const SizedBox(height: 24),
                _buildTotalCard(),
                const SizedBox(height: 24),
                _buildCompleteOrderButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOptions() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildRadioTile(
                'Cash on Delivery', Icons.money, 'Cash on Delivery'),
            const Divider(height: 24),
            _buildRadioTile('Card Payment', Icons.credit_card, 'Card Payment'),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedCards() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved Cards',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
            ),
            const SizedBox(height: 16),
            ...savedCards.map(
              (card) => GestureDetector(
                onTap: () {
                  setState(() {
                    if (selectedSavedCard == card['number']) {
                      selectedSavedCard = null; // Unselect if already selected
                      isCardDetailsComplete = false;
                    } else {
                      selectedSavedCard = card['number']; // Select the card
                      isCardDetailsComplete = true;
                    }
                  });
                },
                child: ListTile(
                  leading: Icon(
                    card['type'] == 'Visa' ? Icons.credit_card : Icons.payment,
                    color: Colors.blue[700],
                  ),
                  title: Text(card['number']!),
                  subtitle: Text('Expires: ${card['expiry']}'),
                  trailing: Radio<String>(
                    value: card['number']!,
                    groupValue: selectedSavedCard,
                    activeColor: Colors.blue[700],
                    onChanged: (value) {
                      setState(() {
                        if (selectedSavedCard == value) {
                          selectedSavedCard = null; // Unselect
                          isCardDetailsComplete = false;
                        } else {
                          selectedSavedCard = value; // Select
                          isCardDetailsComplete = true;
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetailsInput() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildTextField(
              _cardNumberController,
              'Card Number',
              _getCardType(_cardNumberController.text) == 'Visa'
                  ? Icons.credit_card
                  : Icons.payment,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _expiryController,
                    'MM/YY',
                    Icons.calendar_today,
                    onChanged: _formatExpiryDate,
                    maxLength: 5,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(_cvvController, 'CVV', Icons.lock,
                      maxLength: 3),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: saveCard,
                  onChanged: (value) {
                    setState(() {
                      saveCard = value!; // Toggle saveCard state
                    });
                  },
                  activeColor: Colors.blue[700],
                ),
                const Text(
                  'Save this card for future use',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Rs. ${widget.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteOrderButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed:
            (paymentMethod == 'Cash on Delivery' || isCardDetailsComplete)
                ? () {
                    _saveOrderToFirebase();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OrderHistoryScreen()),
                    );
                  }
                : null,
        child: const Text(
          'Complete Order',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w600,
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
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 16)),
        ],
      ),
      value: value,
      groupValue: paymentMethod,
      activeColor: Colors.blue[700],
      onChanged: (value) {
        setState(() {
          paymentMethod = value.toString();
          selectedSavedCard = null;
          isCardDetailsComplete = paymentMethod == 'Cash on Delivery';
        });
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    void Function(String)? onChanged,
    int? maxLength,
  }) {
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        counterText: '', // Hides character counter
      ),
      keyboardType: TextInputType.number,
      maxLength: maxLength,
      onChanged: (value) {
        if (onChanged != null) onChanged(value);
        setState(() {
          isCardDetailsComplete = _cardNumberController.text.isNotEmpty &&
              _expiryController.text.isNotEmpty &&
              _cvvController.text.isNotEmpty;
        });
      },
    );
  }
}
