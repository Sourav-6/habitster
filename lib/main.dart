import 'package:flutter/material.dart';
import 'screens/obs/onboarding_screen.dart'; // Import the new file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitster',
      theme: ThemeData(
        primaryColor: const Color(0xFFFFEA00), // Lemon Zest
        scaffoldBackgroundColor: const Color(0xFFFFFDE7), // Light Cream
        fontFamily: 'Poppins', // Added font
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Color(0xFF212121), fontSize: 28), // Graphite
          bodyMedium: TextStyle(color: Color(0xFF757575), fontSize: 16), // Cool Grey
        ),
      ),
      home: const OnboardingScreen(), // Use the new onboarding screen
    );
  }
}