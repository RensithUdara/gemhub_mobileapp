import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemhub/screens/auth_screens/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool isBuyer = true;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String userId = userCredential.user?.uid ?? '';
      Map<String, dynamic> userData = {
        'firebaseUid': userId,
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'phoneNumber': phoneNumberController.text.trim(),
        'role': isBuyer ? 'buyer' : 'seller',
      };

      if (!isBuyer) {
        userData.addAll({
          'displayName': displayNameController.text.trim(),
          'address': addressController.text.trim(),
        });
      }

      final String collectionName = isBuyer ? 'buyers' : 'sellers';
      await _firestore.collection(collectionName).doc(userId).set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User registered successfully!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.message}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo_new.png', height: 90),
                const SizedBox(height: 20),
                const Text(
                  'Create an Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                _roleSelector(),
                if (!isBuyer) _customTextField('Name', displayNameController),
                if (!isBuyer) _customTextField('Address', addressController),
                _customTextField('Username', usernameController),
                _customTextField('Email', emailController),
                _customTextField('Phone Number', phoneNumberController,
                    keyboardType: TextInputType.phone),
                _customTextField('Password', passwordController,
                    isPassword: true),
                _customTextField('Confirm Password', confirmPasswordController,
                    isPassword: true),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSelector() {
    return ToggleButtons(
      isSelected: [isBuyer, !isBuyer],
      onPressed: (index) => setState(() => isBuyer = index == 0),
      borderRadius: BorderRadius.circular(12),
      selectedColor: Colors.white,
      fillColor: Colors.green,
      color: Colors.black,
      borderWidth: 2,
      children: const [
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text('Buyer')),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text('Seller')),
      ],
    );
  }

  Widget _customTextField(String label, TextEditingController controller,
      {bool isPassword = false,
      TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? !isPasswordVisible : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => isPasswordVisible = !isPasswordVisible),
                )
              : null,
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "This field is required" : null,
      ),
    );
  }
}
