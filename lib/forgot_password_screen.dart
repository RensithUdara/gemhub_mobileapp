import 'package:flutter/material.dart';
import 'package:gemhub/Database/db_helper.dart';
import 'package:gemhub/reset_password_screen.dart'; // Import the reset password screen

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController phoneNumberController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool isOTPSent = false;
  String generatedOTP = "123456"; // For testing purposes, you would generate this dynamically
  bool isPhoneNumberValid = false; // Used to enable/disable "Send OTP" button

  List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());
  List<FocusNode> otpFocusNodes = List.generate(6, (index) => FocusNode());

  InputDecoration customInputDecoration(String labelText) {
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
    );
  }

  Widget otpInput(TextEditingController controller, FocusNode focusNode,
      FocusNode? nextFocusNode) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        onChanged: (value) {
          if (value.length == 1) {
            focusNode.unfocus();
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            }
          }
        },
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Function to validate if phone number exists in database
  Future<bool> validatePhoneNumber(String phoneNumber) async {
    final users = await _databaseHelper.getUsers();
    return users.any((user) => user['phoneNumber'] == phoneNumber);
  }

  // Function to check phone number before enabling "Send OTP" button
  void checkPhoneNumber(String value) {
    setState(() {
      isPhoneNumberValid = value.isNotEmpty;
    });
  }

  // Send OTP and validate phone number
  void sendOTP() async {
    String phoneNumber = phoneNumberController.text;

    // Validate if phone number exists in the database
    bool phoneNumberExists = await validatePhoneNumber(phoneNumber);

    if (phoneNumberExists) {
      setState(() {
        isOTPSent = true;
      });
      // Proceed with sending OTP logic
    } else {
      // Show error if phone number does not exist
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number not found!")),
      );
    }
  }

  void verifyOTP() {
    String enteredOTP = otpControllers.map((controller) => controller.text).join();
    if (enteredOTP == generatedOTP) {
      // Navigate to the Reset Password screen if OTP is correct
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(
            phoneNumber: phoneNumberController.text,
          ),
        ),
      );
    } else {
      // Show error message if OTP is incorrect
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP!")),
      );
    }
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
                  'Forgot Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: phoneNumberController,
                  keyboardType: TextInputType.phone,
                  onChanged: checkPhoneNumber, // Enable "Send OTP" button based on input
                  decoration: customInputDecoration('Phone Number'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isPhoneNumberValid ? sendOTP : null, // Disable button if phone number is empty
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPhoneNumberValid ? Colors.black : Colors.grey, // Change button color when enabled/disabled
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 40.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Send OTP',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isOTPSent) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return otpInput(
                        otpControllers[index],
                        otpFocusNodes[index],
                        index < 5 ? otpFocusNodes[index + 1] : null,
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: verifyOTP,
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
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
