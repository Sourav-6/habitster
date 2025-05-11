import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // For ImageFilter in glassmorphism effect
import 'package:intl/intl.dart';

// App theme colors
class AppColors {
  static const backgroundColor = Colors.white; // Changed to pure white
  static const primaryColor = Color(0xFFFF0066);
  static const navBarColor = Color.fromARGB(255, 255, 240, 245); // Lighter pink
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
    const TodoListScreen(),
    const HabitsScreen(),
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
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
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
            : Colors.black.withOpacity(0.6),
        size: 26,
      ),
      onPressed: () => _onItemTapped(index),
    );
  }

  Widget _buildFloatingActionButton() {
    return GestureDetector(
      onTap: () {
        // Add your action here
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.add, color: AppColors.textColorLight, size: 30),
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

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(Icons.local_fire_department_rounded, '5', 'Streak', Colors.deepOrange),
          _buildStatItem(Icons.star_rounded, '120', 'Karma', Colors.red),
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
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsSection(),
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
    );
  }

  Widget _buildDateTimeline() {
    final now = DateTime.now();
    final dates = List.generate(7, (index) => now.add(Duration(days: index - 3)));

    return Container(
      height: 85,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          final isToday = DateUtils.isSameDay(date, now);

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 58,
              margin: EdgeInsets.symmetric(
                horizontal: 4,
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
                    ? AppColors.primaryColor.withOpacity(0.1)
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
                      color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenWrapper(
      title: 'My Tasks',
      children: [
        // Add your todo list content here
      ],
    );
  }
}

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenWrapper(
      title: 'My Habits',
      children: [
        // Add your habits content here
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenWrapper(
      title: 'Profile',
      children: [
        // Add your profile content here
      ],
    );
  }
}