import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../habits/habits.dart';
import '../tasks/tasks.dart';

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
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBody: true,
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // Navigation bar background
        Container(
          width: MediaQuery.of(context).size.width * 0.9,
          margin: const EdgeInsets.only(bottom: 35),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.navBarColor,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20), // 0.08 opacity = 20 alpha
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(8), // 0.03 opacity = 8 alpha
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded),
              _buildNavItem(1, Icons.checklist_rounded),
              const SizedBox(width: 50),
              _buildNavItem(2, Icons.auto_awesome_rounded),
              _buildNavItem(3, Icons.person_rounded),
            ],
          ),
        ),

        // Floating action button
        Positioned(
          bottom: 45,
          child: _buildFloatingActionButton(),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final bool isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected
            ? AppColors.primaryColor
            : Colors.black.withAlpha(153), // 0.6 opacity = 153 alpha
        size: 26,
      ),
      onPressed: () => _onItemTapped(index),
    );
  }

  Widget _buildFloatingActionButton() {
    return GestureDetector(
      onTap: () {
        // Action for AI chatbot
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Chatbot coming soon!'))
        );
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Color(0xFF6A11CB), // Deep purple
              Color(0xFF2575FC), // Blue
              Color(0xFF00CCFF), // Cyan
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // Removed the glow/shadow effect
        ),
        child: const Icon(
          Icons.chat_bubble_outline_rounded,
          color: AppColors.textColorLight,
          size: 26,
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Stats aligned to the left
          Row(
            children: [
              _buildStatItem(Icons.local_fire_department_rounded, '5', 'Streak', Colors.deepOrange),
              const SizedBox(width: 20),
              _buildStatItem(Icons.star_rounded, '120', 'Karma', Colors.red),
            ],
          ),
          // Notification bell on the right
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF757575),
              size: 28,
            ),
            onPressed: () {
              // Handle notification bell tap
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColorDark,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFE0E0E0)),
                  ),
                  _buildDateTimeline(),
                  const SizedBox(height: 20),
                  // Add your home screen content here
                ],
              ),
            ),
          ),

          // Floating action button for home screen - positioned higher
          Positioned(
            bottom: 130, // Raised higher above navbar
            right: 30,
            child: _buildAddButton(),
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
                  top: -100 + 50 * math.sin(_animationController.value * math.pi * 0.7),
                  left: -80 + 40 * math.cos(_animationController.value * math.pi * 0.5),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFFF0066).withAlpha(30), // Pink
                      const Color(0xFFFF9E80).withAlpha(20), // Light orange
                    ],
                    250 + 50 * math.sin(_animationController.value * math.pi * 0.6),
                  ),
                ),

                // Yellow-purple gradient blob
                Positioned(
                  bottom: MediaQuery.of(context).size.height / 4,
                  right: -120 + 60 * math.cos(_animationController.value * math.pi * 0.4),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFf8e356).withAlpha(25), // Yellow
                      const Color(0xFF6A11CB).withAlpha(15), // Purple
                    ],
                    280 + 60 * math.sin(_animationController.value * math.pi * 0.5),
                  ),
                ),

                // Blue-cyan gradient blob
                Positioned(
                  top: MediaQuery.of(context).size.height / 3,
                  left: MediaQuery.of(context).size.width / 3 - 50 + 70 * math.sin(_animationController.value * math.pi * 0.3),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFF00CCFF).withAlpha(20), // Cyan
                      const Color(0xFF2979FF).withAlpha(15), // Blue
                    ],
                    200 + 40 * math.cos(_animationController.value * math.pi * 0.6),
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
                    100 + 20 * math.sin(_animationController.value * math.pi * 0.8),
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
                    80 + 15 * math.cos(_animationController.value * math.pi * 0.7),
                  ),
                ),
              ],
            );
          },
        ),

        // Glassmorphic overlay
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), // Increased blur for more aesthetic effect
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

  Widget _buildAddButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF0066), // Pink
            Color(0xFFFF3366), // Light pink
            Color(0xFFf8e356), // Yellow (added)
            Color(0xFF6A11CB), // Purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0066).withAlpha(77), // 0.3 opacity = 77 alpha
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildDateTimeline() {
    final now = DateTime.now();

    // Find the previous Sunday to start the week
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));

    // Generate 7 days starting from Sunday
    final dates = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Container(
      height: 85,
      width: double.infinity, // Ensure container takes full width
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withAlpha(230), // More transparent to show glassmorphic effect
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
                    ? AppColors.primaryColor.withAlpha(26) // 0.1 opacity = 26 alpha
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
                      color: isSelected ? Colors.white : AppColors.textColorDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM').format(date).substring(0, 3),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white.withAlpha(230) : Colors.grey[500], // 0.9 opacity = 230 alpha
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

// Removed the old TodoListScreen and HabitsScreen classes as we're now using the ones from separate files

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
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
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withAlpha(204), // 0.8 opacity = 204 alpha
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Your profile information will appear here',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black.withAlpha(153), // 0.6 opacity = 153 alpha
                        ),
                      ),
                    ),
                  ),
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
                  top: -100 + 50 * math.sin(_animationController.value * math.pi * 0.7),
                  right: -80 + 40 * math.cos(_animationController.value * math.pi * 0.5),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFFF0066).withAlpha(30), // Pink
                      const Color(0xFFFF9E80).withAlpha(20), // Light orange
                    ],
                    250 + 50 * math.sin(_animationController.value * math.pi * 0.6),
                  ),
                ),

                // Yellow-purple gradient blob
                Positioned(
                  bottom: MediaQuery.of(context).size.height / 4,
                  left: -120 + 60 * math.cos(_animationController.value * math.pi * 0.4),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFf8e356).withAlpha(25), // Yellow
                      const Color(0xFF6A11CB).withAlpha(15), // Purple
                    ],
                    280 + 60 * math.sin(_animationController.value * math.pi * 0.5),
                  ),
                ),

                // Blue-cyan gradient blob
                Positioned(
                  top: MediaQuery.of(context).size.height / 3,
                  right: MediaQuery.of(context).size.width / 3 - 50 + 70 * math.sin(_animationController.value * math.pi * 0.3),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFF00CCFF).withAlpha(20), // Cyan
                      const Color(0xFF2979FF).withAlpha(15), // Blue
                    ],
                    200 + 40 * math.cos(_animationController.value * math.pi * 0.6),
                  ),
                ),

                // Small decorative blobs
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.6,
                  right: MediaQuery.of(context).size.width * 0.7,
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFFF4081).withAlpha(25), // Pink
                      const Color(0xFFFF80AB).withAlpha(15), // Light pink
                    ],
                    100 + 20 * math.sin(_animationController.value * math.pi * 0.8),
                  ),
                ),

                Positioned(
                  top: MediaQuery.of(context).size.height * 0.2,
                  right: MediaQuery.of(context).size.width * 0.6,
                  child: _buildGradientBlob(
                    [
                      const Color(0xFF64FFDA).withAlpha(20), // Teal
                      const Color(0xFF1DE9B6).withAlpha(15), // Light teal
                    ],
                    80 + 15 * math.cos(_animationController.value * math.pi * 0.7),
                  ),
                ),
              ],
            );
          },
        ),

        // Glassmorphic overlay
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), // Increased blur for more aesthetic effect
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
}