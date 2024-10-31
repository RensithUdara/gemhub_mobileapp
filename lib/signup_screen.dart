import 'package:flutter/material.dart';
import 'package:gemhub/Database/db_helper.dart';
import 'package:gemhub/login_screen.dart';

class SignUp_Screen extends StatefulWidget {
  const SignUp_Screen({super.key});

  @override
  State<SignUp_Screen> createState() => _SignUp_ScreenState();
}

class _SignUp_ScreenState extends State<SignUp_Screen> {
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

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  InputDecoration customInputDecoration(String labelText,
      {bool isPasswordField = false, bool isConfirmPasswordField = false}) {
    return InputDecoration(
      labelText: labelText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: TextStyle(color: Colors.grey[700]),
      hintStyle: TextStyle(color: Colors.grey[400]),
      suffixIcon: isPasswordField
          ? IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  isPasswordVisible = !isPasswordVisible;
                });
              },
            )
          : isConfirmPasswordField
              ? IconButton(
                  icon: Icon(
                    isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      isConfirmPasswordVisible = !isConfirmPasswordVisible;
                    });
                  },
                )
              : null,
    );
  }

  Widget customTextField(String labelText, TextEditingController controller,
      {bool obscureText = false,
      bool isPasswordField = false,
      bool isConfirmPasswordField = false,
      TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: customInputDecoration(labelText,
            isPasswordField: isPasswordField,
            isConfirmPasswordField: isConfirmPasswordField),
      ),
    );
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

  Future<void> _saveUser() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    Map<String, dynamic> user = {
      'displayName': isBuyer ? null : displayNameController.text,
      'address': isBuyer ? null : addressController.text,
      'username': usernameController.text,
      'password': passwordController.text,
      'email': emailController.text,
      'phoneNumber': phoneNumberController.text,
    };

    await _databaseHelper.insertUser(user);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User registered successfully!")),
    );

    // Navigate to the Login Screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/logo_new.png',
                  height: 100,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Register',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          switchRole(true);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBuyer ? Colors.green : Colors.black,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: const Center(
                            child: Text(
                              'Buyer',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          switchRole(false);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: !isBuyer ? Colors.green : Colors.black,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: const Center(
                            child: Text(
                              'Seller',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (!isBuyer) customTextField('Name', displayNameController),
                if (!isBuyer) const SizedBox(height: 10),
                if (!isBuyer) customTextField('Address', addressController),
                if (!isBuyer) const SizedBox(height: 10),
                customTextField('Username', usernameController),
                const SizedBox(height: 10),
                customTextField(
                  'Password',
                  passwordController,
                  obscureText: !isPasswordVisible,
                  isPasswordField: true,
                ),
                const SizedBox(height: 10),
                customTextField(
                  'Confirm Password',
                  confirmPasswordController,
                  obscureText: !isConfirmPasswordVisible,
                  isConfirmPasswordField: true,
                ),
                const SizedBox(height: 10),
                customTextField('Email', emailController),
                const SizedBox(height: 10),
                customTextField('Phone Number', phoneNumberController,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 40.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
