import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../habits/habits.dart';
import '../tasks/tasks.dart';
import '../settings/settings_screen.dart';
import '../chatBot/chat_screen.dart';
import '../../../services/api_service.dart';
import '../../../models/user_profile.dart';
import '../../../widgets/habitster_loading_widget.dart';
import '../profile/avatar_selection_screen.dart';
import '../../../widgets/mood_tracker.dart';
import '../../../widgets/daily_learning_card.dart';
import '../island/island_screen.dart';

// App theme colors
class AppColors {
  static Color getBackgroundColor(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static const primaryColor = Color(0xFFFF0066);
  static Color getNavBarColor(BuildContext context) => Theme.of(context).cardColor;
  static const accentColor = Color(0xFFFF9800);
  static Color getTextColor(BuildContext context) => Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(), // Using our new TasksScreen
    const HabitsScreen(), // Using our new HabitsScreen
  ];

  void _onItemTapped(int index) {
    // Direct mapping:
    // Tap index 0 (Home)   -> Screen index 0
    // Tap index 1 (Tasks)  -> Screen index 1
    // Tap index 2 (Habits) -> Screen index 2
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use the adjusted index to show the correct screen
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      extendBody: true,
      body: _screens[_selectedIndex], // Use _selectedIndex directly
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    // No Stack needed anymore
    return Container(
      width: MediaQuery.of(context).size.width * 0.9, // Adjust width if needed
      margin: const EdgeInsets.only(
          bottom: 35, left: 20, right: 20), // Use margin for centering/spacing
      padding:
          const EdgeInsets.symmetric(vertical: 10), // Adjust vertical padding
      height: 72, // May need slight adjustment
      decoration: BoxDecoration(
        color: AppColors.getNavBarColor(context),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        // Use spaceEvenly for equal spacing AROUND each item
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment:
            CrossAxisAlignment.center, // Center items vertically
        children: [
          // Item 1: Home
          _buildNavItem(0, Icons.home_rounded, isSelected: _selectedIndex == 0),

          // Item 2: Tasks
          _buildNavItem(1, Icons.checklist_rounded,
              isSelected: _selectedIndex == 1),

          // Item 3: FAB (Now directly in the Row)
          _buildFloatingActionButton(), // Use the existing FAB builder function

          // Item 4: Habits
          _buildNavItem(2, Icons.auto_awesome_rounded,
              isSelected: _selectedIndex == 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, {required bool isSelected}) {
    Color iconColor;
    int screenIndex = index > 1 ? index - 1 : index;

    if (screenIndex == 1) {
      iconColor =
          isSelected ? AppColors.primaryColor : Theme.of(context).unselectedWidgetColor.withAlpha(120);
    } else {
      iconColor =
          isSelected ? AppColors.primaryColor : Theme.of(context).unselectedWidgetColor.withAlpha(120);
    }

    return IconButton(
      icon: isSelected 
        ? Icon(icon, color: iconColor, size: 28).animate().scale(duration: 200.ms, curve: Curves.easeOutBack) 
        : Icon(icon, color: iconColor, size: 24),
      onPressed: () => _onItemTapped(index),
    );
  }

  Widget _buildFloatingActionButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ChatScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4081), Color(0xFFFF80AB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4081).withAlpha(100),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'H',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF4081),
                letterSpacing: -1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Common screen wrapper to reduce code duplication
class ScreenWrapper extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ScreenWrapper({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animationController;
  final ApiService _apiService = ApiService();
  UserProfile? _profile;
  bool _isLoadingProfile = true;
  Map<String, int> _activityData = {};
  bool _isLoadingActivity = true;
  String? _todayMood;
  bool _isLoadingMood = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _loadProfile();
    
    // Refresh UI every minute to keep greeting and date accurate
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadProfile() async {
    try {
      final profileData = await _apiService.getUserProfile();
      if (mounted) {
        setState(() {
          _profile = UserProfile.fromJson(profileData);
          _isLoadingProfile = false;
        });
        _loadMood();
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadActivityStats() async {
    try {
      final activityData = await _apiService.getActivityStats();
      if (mounted) {
        setState(() {
          // Convert Map<String, dynamic> to Map<String, int>
          _activityData = activityData.map((key, value) => MapEntry(key, value as int));
          _isLoadingActivity = false;
        });
      }
    } catch (e) {
      print('Error loading activity stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingActivity = false;
        });
      }
    }
  }

  Future<void> _loadMood() async {
    try {
      final mood = await _apiService.getTodayMood();
      if (mounted) {
        setState(() {
          _todayMood = mood;
          _isLoadingMood = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading mood: \$e');
      if (mounted) {
        setState(() {
          _isLoadingMood = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildProfileHeader() {
    // Determine greeting based on time of day
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      greeting = 'Good Evening';
    } else {
      greeting = 'Good Night';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Greeting and Username
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fade().slideY(begin: -0.2, end: 0, duration: 400.ms),
              const SizedBox(height: 4),
              _isLoadingProfile
                  ? Container(
                      width: 120,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).disabledColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1200.ms)
                  : Text(
                      '${_profile?.userName ?? 'Habitster'} 👋', // Dynamically read username
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(context),
                      ),
                    ).animate().fade(delay: 100.ms).slideY(begin: -0.2, end: 0, duration: 400.ms),
            ],
          ),
          
          // Interactive Avatar Frame
          GestureDetector(
            onTap: () async {
              if (_profile == null) return;
              final newAvatarId = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => AvatarSelectionScreen(currentProfile: _profile!),
                ),
              );
              
              if (newAvatarId != null && mounted) {
                // Instantly update the UI local state
                setState(() {
                  _profile = UserProfile(
                    userId: _profile!.userId,
                    userName: _profile!.userName,
                    xp: _profile!.xp,
                    level: _profile!.level,
                    streakFreezeTokens: _profile!.streakFreezeTokens,
                    avatarEnergy: _profile!.avatarEnergy,
                    bestStreak: _profile!.bestStreak,
                    healthXp: _profile!.healthXp,
                    productivityXp: _profile!.productivityXp,
                    mindfulnessXp: _profile!.mindfulnessXp,
                    learningXp: _profile!.learningXp,
                    equippedAvatar: newAvatarId,
                  );
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(3), // Border width
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF0066), Color(0xFFFF80AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF0066).withAlpha(60),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
                child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor,
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[900] 
                      : Colors.grey[100],
                  backgroundImage: AssetImage(
                    _profile?.equippedAvatar == 'man_lotus' 
                        ? 'assets/images/Man In Lotus Position Dark Skin Tone.png'
                        : _profile?.equippedAvatar == 'person_bouncing'
                            ? 'assets/images/Person Bouncing Ball Light Skin Tone.png'
                            : 'assets/images/Woman Climbing Light Skin Tone.png',
                  ), 
                ),
              ),
            ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSection() {
    if (_isLoadingProfile) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: HabitsterLoadingWidget(fontSize: 28)));
    }
    
    final level = _profile?.level ?? 1;
    final xp = _profile?.xp ?? 0;
    final maxXpForLevel = level * 100;
    final percent = _profile?.xpProgressToNextLevel ?? 0.0;
  
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withAlpha(240),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0066).withAlpha(15),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF0066), Color(0xFFFF4081)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF0066).withAlpha(60),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                  ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 2.seconds, color: Colors.white.withAlpha(128)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $level',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextColor(context),
                        ),
                      ),
                      Text(
                        _profile != null && _profile!.level >= 10 ? 'Habit Master' : 'Hustler',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF0066),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.settings_rounded,
                  color: Color(0xFFB0B0B0),
                  size: 28,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearPercentIndicator(
            lineHeight: 14.0,
            percent: percent,
            barRadius: const Radius.circular(10),
            backgroundColor: Theme.of(context).disabledColor.withAlpha(30),
            linearGradient: const LinearGradient(
              colors: [Color(0xFFFF0066), Color(0xFFFF80AB)],
            ),
            animation: true,
            animationDuration: 1500,
            curve: Curves.easeOutCubic,
            widgetIndicator: const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFFFF0066)),
            trailing: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                "$xp/Next Lvl",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildStatsSection() {
    if (_isLoadingProfile) {
      return const SizedBox.shrink(); // Hide while loading
    }
  
    final energy = _profile?.avatarEnergy ?? 100;
    final freezeTokens = _profile?.streakFreezeTokens ?? 0;
    final bestStreak = _profile?.bestStreak ?? 0;
    final streakLabel = bestStreak == 1 ? '1 day' : '$bestStreak days';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withAlpha(240),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(Icons.bolt_rounded, '$energy%', 'Energy',
              Colors.amber[600]!),
          Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
          _buildStatItem(Icons.ac_unit_rounded, '$freezeTokens', 'Freezes', Colors.blue),
          Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
          _buildStatItem(Icons.local_fire_department_rounded, streakLabel, 'Best Streak', Colors.deepOrange),
        ],
      ),
    ).animate().fade(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildStatItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Glassmorphic background with blurred blobs
          _buildGlassmorphicBackground(),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Moved Calendar to the very top
                    _buildDateTimeline().animate().fade(duration: 500.ms).slideX(begin: 0.05, end: 0),
                    const SizedBox(height: 24),
                    
                    _buildProfileHeader(),
                    _buildLevelSection(),
                    _buildStatsSection(),
                    const SizedBox(height: 16),
                    
                    // Daily Learning Gamification Card
                    DailyLearningCard(
                      onXpGained: () {
                        // Refresh the profile to reflect the new XP and Level in the header
                        _loadProfile();
                      },
                    ).animate().fade(duration: 800.ms, delay: 300.ms).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 16), // Less gap to keep cards tight
                    
                    _isLoadingMood 
                        ? const SizedBox.shrink() 
                        : MoodTrackerCard(
                            initialMood: _todayMood,
                            onMoodSelected: (mood) {
                              setState(() {
                                _todayMood = mood;
                              });
                            },
                          ).animate().fade(duration: 700.ms, delay: 400.ms).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 24),
                    
                    // Travel to Island Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const IslandScreen()));
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4DD0E1), Color(0xFF00BCD4)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00BCD4).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ]
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🌴', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Text(
                              'Travel to My Island',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ).animate().fade(duration: 800.ms, delay: 400.ms).slideY(begin: 0.1, end: 0),

                    // Extra bottom padding to ensure it scrolls comfortably past the bottom nav bar
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicBackground() {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      const Color(0xFF0F0F1A),
                      const Color(0xFF161625),
                    ]
                  : [
                      const Color(0xFFF9F9FF),
                      const Color(0xFFF0F8FF),
                    ],
            ),
          ),
        ),

        // Animated blobs with more attractive design
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Stack(
              children: [
                // Primary Pink gradient blob
                Positioned(
                  top: -60 +
                      30 * math.sin(_animationController.value * math.pi * 0.7),
                  left: -40 +
                      20 * math.cos(_animationController.value * math.pi * 0.5),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFFF0066).withAlpha(50), // Pink
                      const Color(0xFFFF4081).withAlpha(30), // Lighter pink
                    ],
                    350 +
                        40 *
                            math.sin(
                                _animationController.value * math.pi * 0.6),
                  ),
                ),

                // Accent Peach gradient blob
                Positioned(
                  bottom: MediaQuery.of(context).size.height / 5,
                  right: -80 +
                      40 * math.cos(_animationController.value * math.pi * 0.4),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFFF9E80).withAlpha(40), // Peach
                      const Color(0xFFFFE57F).withAlpha(20), // Soft yellow
                    ],
                    300 +
                        50 *
                            math.sin(
                                _animationController.value * math.pi * 0.5),
                  ),
                ),

                // Soft Purple blob
                Positioned(
                  top: MediaQuery.of(context).size.height / 3,
                  left: MediaQuery.of(context).size.width / 4 -
                      50 +
                      60 * math.sin(_animationController.value * math.pi * 0.3),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFD500F9).withAlpha(15), // Purple
                      const Color(0xFFE040FB).withAlpha(10), // Light purple
                    ],
                    250 +
                        40 *
                            math.cos(
                                _animationController.value * math.pi * 0.6),
                  ),
                ),

                // Secondary Pink blob
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.6,
                  left: MediaQuery.of(context).size.width * 0.6,
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFFF0066).withAlpha(25), // Pink
                      const Color(0xFFFF80AB).withAlpha(15), // Light pink
                    ],
                    180 +
                        20 *
                            math.sin(
                                _animationController.value * math.pi * 0.8),
                  ),
                ),
              ],
            );
          },
        ),

        // Glassmorphic overlay
        BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: 70,
              sigmaY: 70), // Softer blur
          child: Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withAlpha(40)
                : Colors.white.withAlpha(80),
          ),
        ),
      ],
    );
  }

  // New method for creating gradient blobs
  Widget _buildGradientBlob(List<Color> colors, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }

  Widget _buildActivityGraph() {
    if (_isLoadingActivity) {
      return Container(
        height: 220,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withAlpha(230),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Prepare data for the last 30 days
    final now = DateTime.now();
    final List<BarChartGroupData> barGroups = [];
    double maxCount = 5.0; // Minimum Y-axis max

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final count = _activityData[dateKey] ?? 0;
      if (count.toDouble() > maxCount) maxCount = count.toDouble();

      barGroups.add(
        BarChartGroupData(
          x: 29 - i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF0066), Color(0xFFFF4081)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 8,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxCount + 1,
                color: Theme.of(context).disabledColor.withAlpha(30),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 240,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withAlpha(232),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Habit Activity',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(context),
                ),
              ),
              Text(
                'Last 30 Days',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: false, // Start from the left (oldest) to right (newest)
              child: SizedBox(
                width: 30 * 32.0, // Increased width for better spacing
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxCount + 1,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: AppColors.primaryColor,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final date = now.subtract(Duration(days: 29 - group.x.toInt()));
                          final dateLabel = DateFormat('MMM d').format(date);
                          return BarTooltipItem(
                            '$dateLabel\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: '${rod.toY.toInt()} habits',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index % 5 != 0 && index != 29) return const SizedBox.shrink();
                            final date = now.subtract(Duration(days: 29 - index));
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('dd').format(date),
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeline() {
    final now = DateTime.now();

    // Find the previous Monday (or Sunday) to anchor the week
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final dates = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthLabel = DateFormat('MMMM yyyy').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            monthLabel,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(context),
            ),
          ),
        ),

        // Day cells
        Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: dates.map((date) {
              final isSelected = DateUtils.isSameDay(date, _selectedDate);
              final isToday = DateUtils.isSameDay(date, now);

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 42,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFFF0066), Color(0xFFFF4081)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Day abbreviation
                      Text(
                        DateFormat('E').format(date).substring(0, 1),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : (isDark ? Colors.grey[500] : Colors.grey[500]),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Day number
                      Text(
                        date.day.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: isSelected ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Today dot indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isToday ? 5 : 0,
                        height: isToday ? 5 : 0,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFFF0066),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
