import 'package:flutter/material.dart';
import 'package:gemhub/Database/db_helper.dart';
import 'package:gemhub/login_screen.dart'; 

class ResetPasswordScreen extends StatefulWidget {
  final String phoneNumber; 
  const ResetPasswordScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  InputDecoration customInputDecoration(String labelText, {bool isPasswordField = false}) {
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
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
          : IconButton(
              icon: Icon(
                isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  isConfirmPasswordVisible = !isConfirmPasswordVisible;
                });
              },
            ),
    );
  }

  Future<void> resetPassword() async {
    String newPassword = newPasswordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar("Password must be at least 6 characters long");
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar("Passwords do not match");
      return;
    }

    try {
      await _databaseHelper.updateUserPassword(widget.phoneNumber, newPassword);
      _showSnackBar("Password reset successfully!");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      _showSnackBar("An error occurred. Please try again.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/images/logo_new.png",
                  height: 100,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: newPasswordController,
                  obscureText: !isPasswordVisible,
                  decoration: customInputDecoration('New Password', isPasswordField: true),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !isConfirmPasswordVisible,
                  decoration: customInputDecoration('Confirm Password', isPasswordField: false),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: resetPassword,
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
                    'Reset Password',
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
