// lib/screens/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../accountCreation/signupin.dart'; // For navigation after logout

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();

  Future<void> _logoutUser() async {
    try {
      await _apiService.deleteToken();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignUpIn()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Logout failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white, // Or your preferred app bar color
        foregroundColor: Colors.black, // Adjust icon/text color if needed
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100], // Slightly off-white background
      body: ListView(
        children: [
          const SizedBox(height: 20), // Top padding

          // --- Profile Option (Placeholder) ---
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile screen coming soon!')),
              );
            },
          ),
          const Divider(height: 1), // Separator

          // Add more settings options here later (e.g., Appearance, Notifications)

          const SizedBox(height: 30), // Spacing before logout

          // --- Logout Option ---
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log Out',
                style: TextStyle(color: Colors.redAccent)),
            onTap: _logoutUser, // Call the logout function
          ),
          const Divider(height: 1), // Separator
        ],
      ),
    );
  }
}
