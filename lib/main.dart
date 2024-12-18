import 'package:flutter/material.dart';

import 'splash_screen.dart'; // Ensure this path is correct based on your project structure

void main() {
  runApp(const MyApp());
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
