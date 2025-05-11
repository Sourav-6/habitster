import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';

// App theme colors
class AppColors {
  static const backgroundColor = Color(0xFFF4F0FF);
  static const primaryColor = Color(0xFFFF0066);
  static const navBarColor = Color.fromARGB(255, 252, 221, 233);
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

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      title: 'Hey, Uvaiz!',
      children: [
        const SizedBox(height: 12),
        _buildDateTimeline(),
        const SizedBox(height: 20),
        // Add your home screen content here
      ],
    );
  }

  Widget _buildDateTimeline() {
    return EasyDateTimeLine(
      initialDate: _selectedDate,
      activeColor: AppColors.accentColor,
      onDateChange: (selectedDate) {
        setState(() {
          _selectedDate = selectedDate;
        });
      },
      dayProps: const EasyDayProps(
        height: 100.0,
        width: 80.0,
      ),
      timeLineProps: const EasyTimeLineProps(
        hPadding: 16.0,
        separatorPadding: 16.0,
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