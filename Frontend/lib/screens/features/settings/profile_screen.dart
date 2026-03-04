import 'package:flutter/material.dart';
import '../../../services/profile_service.dart';
import '../../../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/glass_card.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  String name = "";
  String email = "";
  String? imagePath;
  bool _isLoadingName = true;
  late AnimationController _animationController;
  final ApiService _apiService = ApiService();

  final List<String> _avatars = [
    'assets/images/avatars/boy.png',
    'assets/images/avatars/girl.png',
    'assets/images/avatars/robot.png',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _loadProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final e = await ProfileService.getEmail();
    final img = await ProfileService.getImagePath();
    // Fetch name from backend so it's per-account, not device-local
    String fetchedName = "Habitster User";
    try {
      final profileData = await _apiService.getUserProfile();
      fetchedName = profileData['name'] ?? profileData['userName'] ?? e.split('@')[0];
    } catch (_) {
      // Fallback to locally stored name if API fails
      fetchedName = await ProfileService.getName();
    }
    setState(() {
      name = fetchedName;
      email = e;
      imagePath = img;
      _isLoadingName = false;
    });
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: name);

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Material(
            color: Colors.transparent,
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Edit Name",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintText: "Enter your name",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, controller.text.trim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text("Save", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      try {
        // Save per-account name on the backend (Appwrite)
        await _apiService.updateUserName(newName);
      } catch (_) {
        // Silently fallback to device-local storage if server update fails
      }
      await ProfileService.setName(newName); // also update local cache
      setState(() => name = newName);
    }
  }

  Future<void> _selectAvatar(String path) async {
    await ProfileService.setImagePath(path);
    setState(() => imagePath = path);
  }

  Widget _buildGlassmorphicBackground() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [const Color(0xFF0A0A12), const Color(0xFF121220)]
                  : [const Color(0xFFFAFAFF), const Color(0xFFF5F9FF)],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final value = _animationController.value;
            return Stack(
              children: [
                Positioned(
                  top: -50 + 30 * math.sin(value * math.pi * 0.7),
                  right: -60 + 40 * math.cos(value * math.pi * 0.5),
                  child: _buildGradientBlob([const Color(0xFF7C4DFF).withValues(alpha: 0.15), const Color(0xFFB388FF).withValues(alpha: 0.1)], 400),
                ),
                Positioned(
                  bottom: -100 + 40 * math.sin(value * math.pi * 0.9),
                  left: -80 + 30 * math.cos(value * math.pi * 0.6),
                  child: _buildGradientBlob([const Color(0xFFFF0066).withValues(alpha: 0.1), const Color(0xFFFF80AB).withValues(alpha: 0.05)], 450),
                ),
              ],
            );
          },
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildGradientBlob(List<Color> colors, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildGlassmorphicBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Main Profile Card
                  GlassCard(
                    padding: const EdgeInsets.all(32),
                    borderRadius: 24,
                    child: Column(
                      children: [
                        _buildAvatarPreview(),
                        const SizedBox(height: 24),
                        _buildEditableName(),
                        Text(
                          email,
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade().scale(duration: 400.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 32),

                  // Avatar Selection Row
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 16),
                      child: Text(
                        "CHOOSE YOUR CHARACTER",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Theme.of(context).primaryColor.withValues(alpha: 0.7),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _avatars.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final path = _avatars[index];
                        final isSelected = imagePath == path;
                        return GestureDetector(
                          onTap: () => _selectAvatar(path),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white10,
                              backgroundImage: AssetImage(path),
                            ),
                          ),
                        ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.5);
                      },
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPreview() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.5)],
        ),
      ),
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Theme.of(context).cardColor,
        backgroundImage: imagePath != null && imagePath!.startsWith('assets')
            ? AssetImage(imagePath!) as ImageProvider
            : (imagePath != null ? FileImage(File(imagePath!)) as ImageProvider : null),
        child: imagePath == null ? const Icon(Icons.person, size: 60) : null,
      ),
    );
  }

  Widget _buildEditableName() {
    return GestureDetector(
      onTap: _editName,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.edit_rounded, 
            size: 18, 
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Theme.of(context).primaryColor
          ),
        ],
      ),
    );
  }
}
