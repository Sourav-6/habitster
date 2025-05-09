import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for SystemChrome
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/obs/onboarding_screen.dart'; // Import the new file
import 'screens/accountCreation/signUpIn.dart'; // Import the SignUpIn screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Add this line
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]); // Lock to portrait mode
  
  // Check if onboarding has been shown
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('showOnboarding') ?? true;
  
  runApp(MyApp(showOnboarding: showOnboarding));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  
  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitster',
      debugShowCheckedModeBanner: false, // Hide the debug banner
      theme: ThemeData(
        primaryColor: const Color(0xFFFF0066), // Changed from yellow to pink
        scaffoldBackgroundColor: Colors.white, // Changed from cream to white
        fontFamily: 'Poppins', // Added font
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Color(0xFF212121), fontSize: 28), // Graphite
          bodyMedium: TextStyle(color: Color(0xFF757575), fontSize: 16), // Cool Grey
        ),
      ),
      home: showOnboarding ? const OnboardingScreen() : const SignUpIn(), // Show SignUpIn instead of Register
    );
  }
}