import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isEmailSelected = true;
  bool isOTPSent = false;
  bool isPhoneNumberValid = false;
  bool isEmailValid = false;
  String verificationId = "";

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Custom Input Decoration
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: TextStyle(color: Colors.grey[700]),
      hintStyle: TextStyle(color: Colors.grey[400]),
    );
  }

  // Toggle between Email and Phone Options
  void toggleOption(bool isEmail) {
    setState(() {
      isEmailSelected = isEmail;
      isOTPSent = false;
    });
  }

  // Validate Email Input
  void checkEmail(String value) {
    setState(() {
      isEmailValid = value.isNotEmpty && value.contains('@');
    });
  }

  // Validate Phone Number Input
  void checkPhoneNumber(String value) {
    setState(() {
      isPhoneNumberValid = value.length == 10; // Adjust for your phone number length
    });
  }

  // Send Password Reset Email
  Future<void> sendResetEmail() async {
    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Error occurred")),
      );
    }
  }

  // Send OTP for Phone Option
  Future<void> sendOTP() async {
    try {
      if (!isPhoneNumberValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid phone number")),
        );
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: "+94${phoneNumberController.text.trim()}",
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (rare case)
          await _auth.signInWithCredential(credential);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                phoneNumber: phoneNumberController.text.trim(),
              ),
            ),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? "Verification failed")),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
            isOTPSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("OTP sent to your phone")),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId = verificationId;
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: ${e.toString()}")),
      );
    }
  }

  // Verify OTP for Phone Option
  Future<void> verifyOTP() async {
    try {
      if (otpController.text.trim().isEmpty || otpController.text.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid 6-digit OTP")),
        );
        return;
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );

      // Authenticate user and navigate to ResetPasswordScreen
      await _auth.signInWithCredential(credential);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(
            phoneNumber: phoneNumberController.text.trim(),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Invalid OTP")),
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
                // App Logo
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

                // Email/Phone Toggle Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => toggleOption(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isEmailSelected ? Colors.black : Colors.grey[300],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Email',
                          style: TextStyle(
                            color: isEmailSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => toggleOption(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: !isEmailSelected ? Colors.black : Colors.grey[300],
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Phone',
                          style: TextStyle(
                            color: !isEmailSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Input Fields
                if (isEmailSelected)
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: checkEmail,
                    decoration: customInputDecoration('Enter your Email'),
                  ),
                if (!isEmailSelected && !isOTPSent)
                  TextField(
                    controller: phoneNumberController,
                    keyboardType: TextInputType.phone,
                    onChanged: checkPhoneNumber,
                    decoration: customInputDecoration('Enter your Phone Number'),
                  ),
                if (!isEmailSelected && isOTPSent)
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: customInputDecoration('Enter OTP'),
                  ),
                const SizedBox(height: 20),

                // Action Button
                ElevatedButton(
                  onPressed: isEmailSelected
                      ? (isEmailValid ? sendResetEmail : null)
                      : (isOTPSent ? verifyOTP : (isPhoneNumberValid ? sendOTP : null)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isEmailSelected && isEmailValid) ||
                            (!isEmailSelected && (isOTPSent || isPhoneNumberValid))
                        ? Colors.black
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 40.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    isEmailSelected
                        ? 'Send Email'
                        : (isOTPSent ? 'Verify OTP' : 'Send OTP'),
                    style: const TextStyle(
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