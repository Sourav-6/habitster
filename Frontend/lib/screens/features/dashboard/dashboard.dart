import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../habits/habits.dart';
import '../tasks/tasks.dart';
import '../settings/settings_screen.dart';
import '../chatBot/chat_screen.dart';
import '../../../services/api_service.dart';

// App theme colors
class AppColors {
  static const backgroundColor = Colors.white; // Pure white background
  static const primaryColor = Color(0xFFFF0066);
  static const navBarColor = Colors.white; // Changed to white
  static const accentColor = Color(0xFFFF9800);
  static const textColorDark = Colors.black;
  static const textColorLight = Colors.white;
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
      backgroundColor: AppColors.backgroundColor,
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
        color: AppColors.navBarColor,
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
    // Adjust index for screen mapping if needed for special coloring
    int screenIndex = index > 1 ? index - 1 : index;

    if (screenIndex == 1) {
      // Tasks icon special color
      iconColor =
          isSelected ? AppColors.primaryColor : Colors.black.withAlpha(153);
    } else {
      iconColor =
          isSelected ? AppColors.primaryColor : Colors.black.withAlpha(153);
    }

    return IconButton(
      icon: Icon(icon, color: iconColor, size: 26),
      // Pass the original tap index to _onItemTapped
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
      child: Icon(
        Icons.chat_bubble_outline_rounded,
        color: Colors.black.withAlpha(153),
        size: 26,
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
      backgroundColor: AppColors.backgroundColor,
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Stats aligned to the left
          Row(
            children: [
              _buildStatItem(Icons.local_fire_department_rounded, '5', 'Streak',
                  Colors.deepOrange),
              const SizedBox(width: 30),
              _buildStatItem(Icons.star_rounded, '120', 'Karma', Colors.red),
            ],
          ),
          IconButton(
            icon: const Icon(
              // Change icon
              Icons.settings_rounded,
              color: Color(0xFF757575),
              size: 26,
            ),
            onPressed: () {
              // Navigate to the new Settings Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const SettingsScreen()), // We'll create this next
              );
            },
          ),
        ],
      ),
    );
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
                color: AppColors.textColorDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
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
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSection(), // Stats section moved to the top
                  const SizedBox(height: 10),
                  // 🔹 AI SUGGESTION CARD (ADD HERE)
                  FutureBuilder(
                    future: ApiService().getAiSuggestion(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      final data = snapshot.data as Map<String, dynamic>;
                      if (data['show'] != true) return const SizedBox();

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ChatScreen()),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.smart_toy),
                              const SizedBox(width: 8),
                              Expanded(child: Text(data['message'])),
                            ],
                          ),
                        ),
                      );
                    },
                  ), // Small space between stats and date picker
                  _buildDateTimeline(),
                  const SizedBox(height: 20),
                  // Add your home screen content here
                ],
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF9F9FF), // Very light purple/white
                Color(0xFFF0F8FF), // Very light blue
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
                // Pink gradient blob
                Positioned(
                  top: -100 +
                      50 * math.sin(_animationController.value * math.pi * 0.7),
                  left: -80 +
                      40 * math.cos(_animationController.value * math.pi * 0.5),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFFF0066).withAlpha(30), // Pink
                      const Color(0xFFFF9E80).withAlpha(20), // Light orange
                    ],
                    250 +
                        50 *
                            math.sin(
                                _animationController.value * math.pi * 0.6),
                  ),
                ),

                // Yellow-purple gradient blob
                Positioned(
                  bottom: MediaQuery.of(context).size.height / 4,
                  right: -120 +
                      60 * math.cos(_animationController.value * math.pi * 0.4),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFf8e356).withAlpha(25), // Yellow
                      const Color(0xFF6A11CB).withAlpha(15), // Purple
                    ],
                    280 +
                        60 *
                            math.sin(
                                _animationController.value * math.pi * 0.5),
                  ),
                ),

                // Blue-cyan gradient blob
                Positioned(
                  top: MediaQuery.of(context).size.height / 3,
                  left: MediaQuery.of(context).size.width / 3 -
                      50 +
                      70 * math.sin(_animationController.value * math.pi * 0.3),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFF00CCFF).withAlpha(20), // Cyan
                      const Color(0xFF2979FF).withAlpha(15), // Blue
                    ],
                    200 +
                        40 *
                            math.cos(
                                _animationController.value * math.pi * 0.6),
                  ),
                ),

                // Small decorative blobs
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.6,
                  left: MediaQuery.of(context).size.width * 0.7,
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFFF4081).withAlpha(25), // Pink
                      const Color(0xFFFF80AB).withAlpha(15), // Light pink
                    ],
                    100 +
                        20 *
                            math.sin(
                                _animationController.value * math.pi * 0.8),
                  ),
                ),

                Positioned(
                  top: MediaQuery.of(context).size.height * 0.2,
                  left: MediaQuery.of(context).size.width * 0.6,
                  child: _buildGradientBlob(
                    [
                      const Color(0xFF64FFDA).withAlpha(20), // Teal
                      const Color(0xFF1DE9B6).withAlpha(15), // Light teal
                    ],
                    80 +
                        15 *
                            math.cos(
                                _animationController.value * math.pi * 0.7),
                  ),
                ),
              ],
            );
          },
        ),

        // Glassmorphic overlay
        BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: 60,
              sigmaY: 60), // Increased blur for more aesthetic effect
          child: Container(
            color: Colors.white.withAlpha(20), // Very subtle white overlay
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

  Widget _buildDateTimeline() {
    final now = DateTime.now();

    // Find the previous Sunday to start the week
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));

    // Generate 7 days starting from Sunday
    final dates =
        List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Container(
      height: 85,
      width: double.infinity, // Ensure container takes full width
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white
            .withAlpha(230), // More transparent to show glassmorphic effect
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 opacity = 13 alpha
            blurRadius: 8,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final date = dates[index];
            final isSelected = DateUtils.isSameDay(date, _selectedDate);
            final isToday = DateUtils.isSameDay(date, now);

            return GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Container(
                width: 42, // Narrower to fix overflow
                margin: EdgeInsets.symmetric(
                  horizontal: 1, // Reduced horizontal margin
                  vertical: isSelected ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFF0066), Color(0xFFFF4081)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isToday && !isSelected
                      ? AppColors.primaryColor
                          .withAlpha(26) // 0.1 opacity = 26 alpha
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('E').format(date).substring(0, 3),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? Colors.white : AppColors.textColorDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM').format(date).substring(0, 3),
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white.withAlpha(230)
                            : Colors.grey[500], // 0.9 opacity = 230 alpha
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
