// lib/screens/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../accountCreation/signupin.dart'; // For navigation after logout
import 'profile_screen.dart';
import 'dart:io';
import '../../../services/profile_service.dart';
import 'package:provider/provider.dart';
import '../../../theme/theme_provider.dart';

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
            leading: FutureBuilder<String?>(
              future: ProfileService.getImagePath(),
              builder: (context, snapshot) {
                final path = snapshot.data;

                if (path != null && path.isNotEmpty) {
                  return CircleAvatar(
                    radius: 22,
                    backgroundImage: FileImage(File(path)),
                    backgroundColor: Colors.grey[200],
                  );
                }

                return const CircleAvatar(
                  radius: 22,
                  child: Icon(Icons.person_outline),
                );
              },
            ),
            title: const Text('Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1), // Separator

          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            trailing: Consumer<ThemeProvider>(
              builder: (context, theme, _) {
                return Switch(
                  value: theme.mode == ThemeMode.dark,
                  onChanged: (val) {
                    theme.toggle(val);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),

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
