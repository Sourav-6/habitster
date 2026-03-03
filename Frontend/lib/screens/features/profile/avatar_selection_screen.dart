import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/api_service.dart';
import '../../../models/user_profile.dart';

class AvatarSelectionScreen extends StatefulWidget {
  final UserProfile currentProfile;

  const AvatarSelectionScreen({super.key, required this.currentProfile});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  final ApiService _apiService = ApiService();
  late String _selectedAvatar;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _availableAvatars = [
    {
      'id': 'woman_climbing',
      'path': 'assets/images/Woman Climbing Light Skin Tone.png',
      'name': 'Climber',
      'requiredLevel': 1,
    },
    {
      'id': 'man_lotus',
      'path': 'assets/images/Man In Lotus Position Dark Skin Tone.png',
      'name': 'Zen Master',
      'requiredLevel': 2,
    },
    {
      'id': 'person_bouncing',
      'path': 'assets/images/Person Bouncing Ball Light Skin Tone.png',
      'name': 'Athletic',
      'requiredLevel': 3,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Use the currently equipped avatar if it matches one of ours, otherwise default mapping
    _selectedAvatar = widget.currentProfile.equippedAvatar;
    if (!_availableAvatars.any((a) => a['id'] == _selectedAvatar)) {
      _selectedAvatar = 'woman_climbing';
    }
  }

  Future<void> _saveAvatar() async {
    setState(() => _isSaving = true);
    try {
      // Assuming a method updateAvatar exists in api_service.dart
      await _apiService.updateAvatar(_selectedAvatar);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, _selectedAvatar);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update avatar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Avatar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'Level up your Habitster profile by unlocking new avatars!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color),
          ).animate().fade().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: _availableAvatars.length,
              itemBuilder: (context, index) {
                final avatar = _availableAvatars[index];
                final isLocked = widget.currentProfile.level < avatar['requiredLevel'];
                final isSelected = _selectedAvatar == avatar['id'];

                return GestureDetector(
                  onTap: () {
                    if (!isLocked) {
                      setState(() => _selectedAvatar = avatar['id']);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reach Level ${avatar['requiredLevel']} to unlock!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF0066) : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? const Color(0xFFFF0066).withAlpha(80)
                              : Colors.black.withAlpha(20),
                          blurRadius: isSelected ? 15 : 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Opacity(
                                opacity: isLocked ? 0.4 : 1.0,
                                child: Image.asset(
                                  avatar['path'],
                                  height: 80,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                avatar['name'],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: isLocked ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isLocked)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Lvl ${avatar['requiredLevel']}',
                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (isSelected)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: const Icon(Icons.check_circle, color: Color(0xFFFF0066)),
                          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
                      ],
                    ),
                  ).animate().fade(delay: (index * 100).ms).slideY(begin: 0.2, end: 0),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAvatar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0066),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Equip Avatar',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
