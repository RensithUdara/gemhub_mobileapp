import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gemhub/screens/firebase_options/firebase_options.dart';

import 'splash_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
  runApp(MyApp());
}

Future<void> _signInAnonymously() async {
  await FirebaseAuth.instance.signInAnonymously();
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GemHub Mobile App',
      theme: ThemeData.light(), 
      home: const SplashScreen(),
    );
  }
}
