import 'package:flutter/material.dart';
import 'package:gemhub/home_screen.dart';
import 'package:gemhub/screens/auth_screens/forgot_password_screen.dart';
import 'package:gemhub/screens/auth_screens/signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool rememberMe = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  // Load saved email and password if "Remember Me" was checked
  Future<void> _loadRememberedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');
    String? savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
        rememberMe = true;
      });
    }
  }

  // Save the credentials if "Remember Me" is checked
  Future<void> _saveCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('email', emailController.text);
      await prefs.setString('password', passwordController.text);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

  // Method to handle forgot password action
  void _handleForgotPassword(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  InputDecoration customInputDecoration(String labelText,
      {bool isPasswordField = false}) {
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
          : null,
    );
  }

  Widget customTextField(String labelText, TextEditingController controller,
      {bool obscureText = false,
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
        decoration:
            customInputDecoration(labelText, isPasswordField: obscureText),
      ),
    );
  }

  // Firebase login validation method
  Future<void> _validateLogin() async {
    String email = emailController.text;
    String password = passwordController.text;

    try {
      // Attempt to sign in with Firebase
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If successful, save credentials if "Remember Me" is checked
      await _saveCredentials();

      // Navigate to the HomeScreen on successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // Handle login errors
      String errorMessage = e.message ?? 'Login failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
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
                  'Log In',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                customTextField('Email', emailController,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 20),
                customTextField(
                  'Password',
                  passwordController,
                  obscureText: !isPasswordVisible,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (bool? value) {
                            setState(() {
                              rememberMe = value ?? false;
                            });
                          },
                        ),
                        const Text('Remember me'),
                      ],
                    ),
                    TextButton(
                      onPressed: () => _handleForgotPassword(context),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _validateLogin,
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
                    'Log in',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        // Navigate to the registration screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUp_Screen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}