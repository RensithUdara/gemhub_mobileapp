import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemhub/screens/auth_screens/login_screen.dart';
import 'package:gemhub/widget/custom_dialog.dart'; // Import the new dialog

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

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
  final TextEditingController nicController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      _showCustomDialog(
        title: 'Error',
        message: 'Passwords do not match!',
        isError: true,
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
      if (userId.isEmpty) {
        throw Exception("Failed to retrieve user ID after sign-up");
      }

      Map<String, dynamic> userData = {
        'firebaseUid': userId,
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'phoneNumber': phoneNumberController.text.trim(),
        'role': isBuyer ? 'buyer' : 'seller',
        'isActive': isBuyer ? true : false,
      };

      if (!isBuyer) {
        userData.addAll({
          'displayName': displayNameController.text.trim(),
          'address': addressController.text.trim(),
          'nicNumber': nicController.text.trim(),
        });
      }

      final String collectionName = isBuyer ? 'buyers' : 'sellers';
      await _firestore.collection(collectionName).doc(userId).set(userData);

      if (!isBuyer) {
        _showActivationDialog();
      } else {
        _showCustomDialog(
          title: 'Success',
          message: 'User registered successfully!',
          onConfirm: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          ),
        );
      }
    } catch (e) {
      _showCustomDialog(
        title: 'Error',
        message: 'Error: $e',
        isError: true,
      );
    }
  }

  void _showActivationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomDialog(
          title: 'Account Created',
          message:
              'Your seller account has been created but is currently disabled. Please send your NIC photo and business registration to:\n\nWhatsApp: +94761155638\nEmail: gemhubmobile@gmail.com\n\nThe Admin will review and enable your account.',
          onConfirm: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          ),
        );
      },
    );
  }

  void _showCustomDialog({
    required String title,
    required String message,
    VoidCallback? onConfirm,
    bool isError = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          title: title,
          message: message,
          onConfirm: onConfirm,
          isError: isError,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (Rest of the build method remains unchanged)
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
                if (!isBuyer) _customTextField('NIC Number', nicController),
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
                    backgroundColor: Colors.blue,
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
      fillColor: Colors.blue,
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
        obscureText: isPassword
            ? (label == 'Password'
                ? !isPasswordVisible
                : !isConfirmPasswordVisible)
            : false,
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
                  icon: Icon((label == 'Password'
                          ? isPasswordVisible
                          : isConfirmPasswordVisible)
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () => setState(() {
                    if (label == 'Password') {
                      isPasswordVisible = !isPasswordVisible;
                    } else {
                      isConfirmPasswordVisible = !isConfirmPasswordVisible;
                    }
                  }),
                )
              : null,
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "This field is required" : null,
      ),
    );
  }

  @override
  void dispose() {
    displayNameController.dispose();
    addressController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    nicController.dispose();
    super.dispose();
  }
}
