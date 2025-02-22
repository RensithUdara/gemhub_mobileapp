import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
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

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User registered successfully!")));

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
    }
  }

  void switchRole(bool toBuyer) {
    setState(() {
      isBuyer = toBuyer;
      if (toBuyer) {
        displayNameController.clear();
        addressController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset('assets/images/logo_new.png', height: 100),
                  const SizedBox(height: 20),
                  const Text('Register', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => switchRole(true),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isBuyer ? Colors.green : Colors.black,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: const Center(child: Text('Buyer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => switchRole(false),
                          child: Container(
                            decoration: BoxDecoration(
                              color: !isBuyer ? Colors.green : Colors.black,
                              borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: const Center(child: Text('Seller', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!isBuyer) _customTextField('Name', displayNameController),
                  if (!isBuyer) const SizedBox(height: 10),
                  if (!isBuyer) _customTextField('Address', addressController),
                  _customTextField('Username', usernameController),
                  const SizedBox(height: 10),
                  _customTextField('Password', passwordController, isPasswordField: true),
                  const SizedBox(height: 10),
                  _customTextField('Confirm Password', confirmPasswordController, isConfirmPasswordField: true),
                  const SizedBox(height: 10),
                  _customTextField('Email', emailController),
                  const SizedBox(height: 10),
                  _customTextField('Phone Number', phoneNumberController, keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveUser,
                    child: const Text('Register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _customTextField(String labelText, TextEditingController controller, {bool isPasswordField = false, bool isConfirmPasswordField = false, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPasswordField ? !isPasswordVisible : isConfirmPasswordField ? !isConfirmPasswordVisible : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(color: Colors.grey[700]),
          suffixIcon: isPasswordField || isConfirmPasswordField
              ? IconButton(
                  icon: Icon((isPasswordField ? isPasswordVisible : isConfirmPasswordVisible) ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      if (isPasswordField) {
                        isPasswordVisible = !isPasswordVisible;
                      } else {
                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
                      }
                    });
                  },
                )
              : null,
        ),
        validator: (value) => value == null || value.isEmpty ? "This field is required" : null,
      ),
    );
  }
}
