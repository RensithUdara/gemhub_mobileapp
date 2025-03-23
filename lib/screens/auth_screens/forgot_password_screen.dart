import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gemhub/screens/auth_screens/login_screen.dart';
import 'package:gemhub/screens/auth_screens/reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool isEmailSelected = true;
  bool isOTPSent = false;
  bool isPhoneNumberValid = false;
  bool isEmailValid = false;
  String verificationId = "";

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
    emailController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  // Matching LoginScreen's Input Decoration
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
        borderSide: const BorderSide(color: Colors.blue, width: 2.0),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      labelStyle: TextStyle(color: Colors.grey[700]),
      hintStyle: TextStyle(color: Colors.grey[400]),
    );
  }

  // Matching LoginScreen's TextField
  Widget customTextField(
    String labelText,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6.0,
            offset: Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: customInputDecoration(labelText),
        onChanged: (value) {
          if (labelText == 'Enter your Email') {
            checkEmail(value);
          } else if (labelText == 'Enter your Phone Number') {
            checkPhoneNumber(value);
          }
        },
      ),
    );
  }

  void showAlertDialog(String title, String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 8,
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error_outline,
                color: isSuccess ? Colors.green : Colors.red,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess ? Colors.green : Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  void toggleOption(bool isEmail) {
    setState(() {
      isEmailSelected = isEmail;
      isOTPSent = false;
      for (var controller in otpControllers) {
        controller.clear();
      }
    });
  }

  void checkEmail(String value) {
    setState(() {
      isEmailValid = value.isNotEmpty && value.contains('@');
    });
  }

  void checkPhoneNumber(String value) {
    setState(() {
      isPhoneNumberValid = value.length == 10;
    });
  }

  Future<void> sendResetEmail() async {
    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      showAlertDialog("Success", "Password reset email sent successfully!",
          isSuccess: true);
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    } on FirebaseAuthException catch (e) {
      showAlertDialog("Error", e.message ?? "An error occurred");
    }
  }

  Future<void> sendOTP() async {
    try {
      if (!isPhoneNumberValid) {
        showAlertDialog("Error", "Please enter a valid phone number");
        return;
      }
      await _auth.verifyPhoneNumber(
        phoneNumber: "+94${phoneNumberController.text.trim()}",
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(
                      phoneNumber: phoneNumberController.text.trim())));
        },
        verificationFailed: (FirebaseAuthException e) {
          showAlertDialog("Error", e.message ?? "Verification failed");
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
            isOTPSent = true;
          });
          showAlertDialog("Success", "OTP sent to your phone", isSuccess: true);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId = verificationId;
        },
      );
    } catch (e) {
      showAlertDialog("Error", "An error occurred: ${e.toString()}");
    }
  }

  Future<void> verifyOTP() async {
    try {
      String otp = otpControllers.map((controller) => controller.text).join();
      if (otp.length != 6) {
        showAlertDialog("Error", "Please enter a valid 6-digit OTP");
        return;
      }
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                  phoneNumber: phoneNumberController.text.trim())));
    } on FirebaseAuthException catch (e) {
      showAlertDialog("Error", e.message ?? "Invalid OTP");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Image.asset(
                      "assets/images/logo_new.png",
                      height: 120,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Forgot Password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => toggleOption(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 24),
                              decoration: BoxDecoration(
                                color: isEmailSelected
                                    ? Colors.blueAccent
                                    : Colors.white,
                                borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(12)),
                              ),
                              child: Text(
                                'Email',
                                style: TextStyle(
                                  color: isEmailSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => toggleOption(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 24),
                              decoration: BoxDecoration(
                                color: !isEmailSelected
                                    ? Colors.blueAccent
                                    : Colors.white,
                                borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(12)),
                              ),
                              child: Text(
                                'Phone',
                                style: TextStyle(
                                  color: !isEmailSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isEmailSelected
                          ? customTextField('Enter your Email', emailController,
                              keyboardType: TextInputType.emailAddress)
                          : !isOTPSent
                              ? customTextField('Enter your Phone Number',
                                  phoneNumberController,
                                  keyboardType: TextInputType.phone)
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(6, (index) {
                                    return SizedBox(
                                      width: 50,
                                      child: TextField(
                                        controller: otpControllers[index],
                                        focusNode: otpFocusNodes[index],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        maxLength: 1,
                                        decoration: InputDecoration(
                                          counterText: '',
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: Colors.grey),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: Colors.grey),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: Colors.blueAccent),
                                          ),
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        onChanged: (value) {
                                          if (value.length == 1 && index < 5) {
                                            otpFocusNodes[index].unfocus();
                                            FocusScope.of(context).requestFocus(
                                                otpFocusNodes[index + 1]);
                                          }
                                          if (value.isEmpty && index > 0) {
                                            otpFocusNodes[index].unfocus();
                                            FocusScope.of(context).requestFocus(
                                                otpFocusNodes[index - 1]);
                                          }
                                        },
                                      ),
                                    );
                                  }),
                                ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isEmailSelected
                            ? (isEmailValid ? sendResetEmail : null)
                            : (isOTPSent
                                ? verifyOTP
                                : (isPhoneNumberValid ? sendOTP : null)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 40.0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0)),
                        ),
                        child: Text(
                          isEmailSelected
                              ? 'Send Email'
                              : (isOTPSent ? 'Verify OTP' : 'Send OTP'),
                          style: const TextStyle(
                              fontSize: 18.0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.black87, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
