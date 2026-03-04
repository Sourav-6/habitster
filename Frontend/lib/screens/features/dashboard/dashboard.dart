import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
import '../../../widgets/glass_card.dart';

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
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.transparent,
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
          ),
        ),
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

  // New Variables for Dashboard V2
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;
  List<dynamic> _activeHabits = [];
  bool _isLoadingHabits = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _loadProfile();
    _loadWeather();
    _loadHabits();
    
    // Refresh UI every minute to keep greeting and date accurate
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadHabits() async {
    try {
      final habits = await _apiService.getHabits();
      if (mounted) {
        setState(() {
          _activeHabits = habits.where((h) => 
            h['status'] != 'completed' && 
            h['status'] != 'hidden' && 
            h['isFavorite'] == true
          ).toList();
          _isLoadingHabits = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading active habits: $e');
      if (mounted) {
        setState(() {
          _isLoadingHabits = false;
        });
      }
    }
  }

  Future<void> _loadWeather() async {
    try {
      // Free Open-Meteo API using Mumbai coordinates
      final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=19.0760&longitude=72.8777&current_weather=true');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _weatherData = data['current_weather'];
            _isLoadingWeather = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingWeather = false);
      }
    } catch (e) {
      debugPrint('Error loading weather: $e');
      if (mounted) setState(() => _isLoadingWeather = false);
    }
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

  Widget _buildTopHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Profile Settings (Avatar + Settings Icon) and Island Button
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              },
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFCCBC), Color(0xFFFF80AB)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _profile?.userName.isNotEmpty == true 
                            ? _profile!.userName.substring(0, 1).toUpperCase() 
                            : 'H',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const IslandScreen()));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌴', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'Travel to Island',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Right: Habitster Logo
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_mosaic_rounded, color: isDark ? Colors.white : AppColors.primaryColor, size: 28),
            const SizedBox(width: 8),
            Text(
              'Habitster',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ],
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildWeatherWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 24, bottom: 20),
        padding: const EdgeInsets.all(2), // Gradient border padding
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF0066), Color(0xFFFF9800)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF0066).withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            )
          ]
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: isDark 
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🌤️', style: TextStyle(fontSize: 48)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _weatherData != null ? '${_weatherData!['temperature']}°C' : '--°C',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              _weatherData != null ? 'partially sunny' : 'Loading...',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Focus: ${_activeHabits.length} Habits',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fade(duration: 800.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String greeting;
    if (hour >= 5 && hour < 12) greeting = 'Good Morning,';
    else if (hour >= 12 && hour < 17) greeting = 'Good Afternoon,';
    else if (hour >= 17 && hour < 21) greeting = 'Good Evening,';
    else greeting = 'Good Night,';

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.2,
            ),
          ),
          Row(
            children: [
              Text(
                '${_profile?.userName ?? 'Habitster'}',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              const Text('👋', style: TextStyle(fontSize: 32))
                 .animate(onPlay: (c) => c.repeat(reverse: true))
                 .rotate(begin: -0.1, end: 0.1, duration: 400.ms),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLevelSection() {
    if (_isLoadingProfile) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: HabitsterLoadingWidget(fontSize: 28)));
    }
    
    final level = _profile?.level ?? 1;
    final xp = _profile?.xp ?? 0;
    final maxXpForLevel = level * 100;
    final percent = _profile?.xpProgressToNextLevel ?? 0.0;
  
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      shadows: [
        BoxShadow(
          color: const Color(0xFFFF0066).withValues(alpha: 0.15),
          blurRadius: 20,
          spreadRadius: 5,
          offset: const Offset(0, 8),
        ),
      ],
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
                          color: const Color(0xFFFF0066).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                  ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.5)),
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
            backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.1),
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
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildStatsSection() {
    if (_isLoadingProfile) {
      return const SizedBox.shrink(); // Hide while loading
    }
  
    final energy = _profile?.avatarEnergy ?? 100;
    final freezeTokens = _profile?.streakFreezeTokens ?? 0;
    final bestStreak = _profile?.bestStreak ?? 0;
    final streakLabel = bestStreak == 1 ? '1 day' : '$bestStreak days';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(Icons.bolt_rounded, '$energy%', 'Energy',
              Colors.amber[600]!),
          Container(width: 1, height: 40, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          _buildStatItem(Icons.ac_unit_rounded, '$freezeTokens', 'Freezes', Colors.blue),
          Container(width: 1, height: 40, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
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

  Widget _buildHabitCards() {
    if (_isLoadingHabits) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: HabitsterLoadingWidget(fontSize: 24)),
      );
    }
    
    if (_activeHabits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          "All done for today! Take a break. 🌟",
          style: GoogleFonts.poppins(color: Colors.white70, fontStyle: FontStyle.italic),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate max width for a 2-column grid
        final cardWidth = (constraints.maxWidth - 16) / 2;
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _activeHabits.asMap().entries.map((entry) {
            final index = entry.key;
            final habit = entry.value;
            
            // For dashboard mockup aesthetics, we'll alternate card styles
            final isProgressStyle = index % 2 == 0; 
            
            if (isProgressStyle) {
              return _buildProgressHabitCard(habit, cardWidth);
            } else {
              return _buildTimerHabitCard(habit, cardWidth);
            }
          }).toList(),
        );
      },
    ).animate().fade(duration: 800.ms, delay: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildProgressHabitCard(dynamic habit, double width) {
    final name = habit['habitName'] ?? 'Habit';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HabitDetailScreen(habit: habit, isCompleted: false),
          ),
        ).then((_) {
          _loadHabits(); // Reload to reflect any completions or favorite toggles
        });
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress bar',
                  style: GoogleFonts.poppins(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
                ),
                Text(
                  '4/8', // Mock data for aesthetics
                  style: GoogleFonts.poppins(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Gradient progress line
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.5, // 4/8
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF0066), Color(0xFFFF9800)],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildMiniIcon(Icons.local_drink_rounded, isDark),
                    const SizedBox(width: 8),
                    _buildMiniIcon(Icons.self_improvement_rounded, isDark),
                  ],
                ),
                Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : Colors.black38, size: 20),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMiniIcon(IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
      ),
      child: Icon(icon, size: 14, color: isDark ? Colors.white70 : Colors.black54),
    );
  }

  Widget _buildTimerHabitCard(dynamic habit, double width) {
    final name = habit['habitName'] ?? 'Habit';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HabitDetailScreen(habit: habit, isCompleted: false),
          ),
        ).then((_) {
          _loadHabits(); // Reload to reflect any completions or favorite toggles
        });
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: isDark ? [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.05),
            ] : [
              Colors.white.withValues(alpha: 0.8),
              Colors.white.withValues(alpha: 0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF0066).withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4081).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🔥', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '10m', // Mock timer value
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
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
                    _buildTopHeader(),
                    _buildWeatherWidget(),
                    _buildGreeting(),
                    const SizedBox(height: 32),
                    
                    _buildDateTimeline().animate().fade(duration: 500.ms).slideX(begin: 0.05, end: 0),
                    const SizedBox(height: 24),
                    
                    _buildHabitCards(),
                    const SizedBox(height: 32),
                    
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
        // Background gradient - Deep Space Blue aesthetic
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      const Color(0xFF030A1A), // Extremely dark blue top
                      const Color(0xFF0A1535), // Deep space blue mid
                      const Color(0xFF050B18), // Dark footer
                    ]
                  : [
                      const Color(0xFFF0F4FA),
                      const Color(0xFFFCFDFF),
                      const Color(0xFFF5F9FF),
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Animated blobs with more attractive design
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final value = _animationController.value;
            return Stack(
              children: [
                // Primary Pink gradient blob - Top Left
                Positioned(
                  top: -100 + 40 * math.sin(value * math.pi * 0.8),
                  left: -80 + 30 * math.cos(value * math.pi * 0.6),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFFF0066).withValues(alpha: 0.25),
                      const Color(0xFFFF4081).withValues(alpha: 0.1),
                    ],
                    450 + 60 * math.sin(value * math.pi * 0.7),
                  ),
                ),

                // Accent Orange/Peach blob - Bottom Right
                Positioned(
                  bottom: -50 + 40 * math.sin(value * math.pi * 0.5),
                  right: -100 + 50 * math.cos(value * math.pi * 0.7),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFFF9E80).withValues(alpha: 0.2),
                      const Color(0xFFFFCCBC).withValues(alpha: 0.05),
                    ],
                    400 + 70 * math.cos(value * math.pi * 0.6),
                  ),
                ),

                // Soft Purple blob - Center Left
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.4 +
                      80 * math.sin(value * math.pi * 0.4),
                  left: -120 + 60 * math.cos(value * math.pi * 0.3),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFD500F9).withValues(alpha: 0.12),
                      const Color(0xFF7C4DFF).withValues(alpha: 0.04),
                    ],
                    350 + 50 * math.sin(value * math.pi * 0.5),
                  ),
                ),

                // Secondary Blue/Cyan blob - Top Right
                Positioned(
                  top: 50 + 60 * math.cos(value * math.pi * 0.4),
                  right: -60 + 40 * math.sin(value * math.pi * 0.6),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFF00E5FF).withValues(alpha: 0.1),
                      const Color(0xFF0288D1).withValues(alpha: 0.02),
                    ],
                    280 + 40 * math.cos(value * math.pi * 0.8),
                  ),
                ),
              ],
            );
          },
        ),

        // Glassmorphic overlay
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), // Maximum luxurious blur
          child: Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.6),
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

    return GlassCard(
      height: 240,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
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

        // Day cells - use Expanded to prevent overflow
        GlassCard(
          height: 78,
          borderRadius: 20,
          child: Row(
            children: dates.map((date) {
              final isSelected = DateUtils.isSameDay(date, _selectedDate);
              final isToday = DateUtils.isSameDay(date, now);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 3, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFFF0066), Color(0xFFFF4081)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date).substring(0, 1),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          date.day.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: isSelected ? 17 : 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Today dot
                        Container(
                          width: isToday ? 4 : 0,
                          height: isToday ? 4 : 0,
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
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
