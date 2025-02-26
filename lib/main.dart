import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gemhub/screens/firebase_options/firebase_options.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e) {
    // Handle initialization failure (e.g., show an error screen)
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize Firebase: $e'),
        ),
      ),
    ));
  }
}

// Function to sign in anonymously (can be called from elsewhere if needed)
Future<void> signInAnonymously() async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
    print('Signed in anonymously with UID: ${userCredential.user?.uid}');
  } on FirebaseAuthException catch (e) {
    print('Failed to sign in anonymously: ${e.message}');
    rethrow; // Optionally rethrow to handle this error elsewhere
  } catch (e) {
    print('Unexpected error during anonymous sign-in: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GemHub Mobile App',
      theme: ThemeData.light(useMaterial3: true), // Updated for Material 3
      home: const SplashScreen(),
    );
  }
}