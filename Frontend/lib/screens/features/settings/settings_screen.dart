import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../accountCreation/signupin.dart'; // For navigation after logout
import 'profile_screen.dart';
import 'dart:io';
import '../../../services/profile_service.dart';
import 'package:provider/provider.dart';
import '../../../theme/theme_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/progress_share_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late AnimationController _animationController;
  String _currentLanguage = "English";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lang = await ProfileService.getLanguage();
    setState(() => _currentLanguage = lang);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

  void _showLanguageDialog() {
    final languages = [
      {"name": "English", "code": "EN"},
      {"name": "Portuguese", "code": "PT"},
      {"name": "Chinese", "code": "ZH"},
      {"name": "Hindi", "code": "HI"},
      {"name": "Marathi", "code": "MR"},
      {"name": "Tamil", "code": "TA"},
      {"name": "Spanish", "code": "ES"},
      {"name": "French", "code": "FR"},
    ];
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Material(
            color: Colors.transparent,
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Select Language",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...languages.map((lang) => ListTile(
                      title: Text(lang["name"]!, style: GoogleFonts.poppins()),
                      trailing: _currentLanguage == lang["name"]
                          ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                          : Text(lang["code"]!, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                      onTap: () async {
                        await ProfileService.setLanguage(lang["name"]!);
                        setState(() => _currentLanguage = lang["name"]!);
                        if (mounted) Navigator.pop(context);
                      },
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showShareCard() {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: _apiService.getUserProfile(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snapshot.data ?? {};
                    final name = data['name'] ?? data['userName'] ?? "Habitster User";
                    
                    return Material(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FutureBuilder<String?>(
                            future: ProfileService.getImagePath(),
                            builder: (context, imgSnapshot) {
                              return ProgressShareCard(
                                name: name,
                                level: data['level'] ?? 1,
                                xp: data['xp'] ?? 0,
                                streak: data['bestStreak'] ?? 0,
                                avatarPath: imgSnapshot.data,
                              );
                            },
                          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 30),
                          GestureDetector(
                            onTap: () {
                              final fakeLink = "https://habitster.app/share/${name.toLowerCase().replaceAll(' ', '')}_${math.Random().nextInt(1000)}";
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Link copied: $fakeLink"),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Theme.of(context).primaryColor,
                                ),
                              );
                            },
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              borderRadius: 20,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.link_rounded, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Generate Share Link",
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ).animate(delay: 400.ms).fade().slideY(begin: 0.2),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close", style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                  top: -100 + 40 * math.sin(value * math.pi * 0.8),
                  left: -80 + 30 * math.cos(value * math.pi * 0.6),
                  child: _buildGradientBlob([const Color(0xFFFF0066).withValues(alpha: 0.2), const Color(0xFFFF4081).withValues(alpha: 0.1)], 450),
                ),
                Positioned(
                  bottom: -50 + 40 * math.sin(value * math.pi * 0.5),
                  right: -100 + 50 * math.cos(value * math.pi * 0.7),
                  child: _buildGradientBlob([const Color(0xFF7C4DFF).withValues(alpha: 0.15), const Color(0xFFD500F9).withValues(alpha: 0.05)], 400),
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
          'Settings',
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
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                const SizedBox(height: 20),
                _buildSectionHeader('Account'),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  leading: FutureBuilder<String?>(
                    future: ProfileService.getImagePath(),
                    builder: (context, snapshot) {
                      final path = snapshot.data;
                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        backgroundImage: path != null && path.startsWith('assets')
                            ? AssetImage(path)
                            : (path != null ? FileImage(File(path)) as ImageProvider : null),
                        child: path == null ? const Icon(Icons.person_outline) : null,
                      );
                    },
                  ),
                  title: 'My Profile',
                  subtitle: 'Avatars, naming, goals',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))
                        .then((_) => setState(() {}));
                  },
                ).animate().fade().slideX(begin: 0.2),
                const SizedBox(height: 24),
                _buildSectionHeader('App Experience'),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: 'Dark Mode',
                  trailing: Consumer<ThemeProvider>(
                    builder: (context, theme, _) {
                      return Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: theme.mode == ThemeMode.dark,
                          activeColor: const Color(0xFFFF0066),
                          activeTrackColor: const Color(0xFFFF0066).withValues(alpha: 0.3),
                          inactiveThumbColor: Colors.grey[400],
                          inactiveTrackColor: Colors.grey[200],
                          onChanged: (val) => theme.toggle(val),
                        ),
                      );
                    },
                  ),
                ).animate(delay: 100.ms).fade().slideX(begin: 0.2),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  leading: const Icon(Icons.translate_rounded),
                  title: 'Language',
                  subtitle: _currentLanguage,
                  onTap: _showLanguageDialog,
                ).animate(delay: 200.ms).fade().slideX(begin: 0.2),
                const SizedBox(height: 24),
                _buildSectionHeader('Community'),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: 'Share My Journey',
                  subtitle: 'Stylish progress card',
                  onTap: _showShareCard,
                ).animate(delay: 300.ms).fade().slideX(begin: 0.2),
                const SizedBox(height: 40),
                Center(
                  child: TextButton.icon(
                    onPressed: _logoutUser,
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    label: Text(
                      'Log Out',
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ).animate(delay: 500.ms).fade(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white.withValues(alpha: 0.5) 
              : Theme.of(context).primaryColor.withValues(alpha: 0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required Widget leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconTheme(
            data: IconThemeData(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Theme.of(context).primaryColor, 
              size: 22,
            ),
            child: leading,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              )
            : null,
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }
}
