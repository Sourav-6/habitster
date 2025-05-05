import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/cupertino.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: SalomonBottomBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFFFF0066),
            unselectedItemColor: Colors.grey,
            items: [
              SalomonBottomBarItem(
                icon: const Icon(Icons.home_rounded),
                title: Text(
                  'Home',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.checklist_rounded),
                title: Text(
                  'TodoList',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.auto_awesome_rounded),
                title: Text(
                  'Habits',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.person_rounded),
                title: Text(
                  'Profile',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
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
  DateTime _selectedMonth = DateTime.now();

  void _showMonthPicker() {
    final List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final List<int> years = List.generate(11, (index) => 2020 + index);
    int selectedMonthIndex = _selectedDate.month - 1;
    int selectedYearIndex = years.indexOf(_selectedDate.year);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 250,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Container(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        // Update the selected date to the same day in the new month and year
                        final int newMonth = selectedMonthIndex + 1;
                        final int newYear = years[selectedYearIndex];
                        
                        final int lastDayOfMonth = DateTime(newYear, newMonth + 1, 0).day;
                        final int newDay = _selectedDate.day > lastDayOfMonth ? lastDayOfMonth : _selectedDate.day;
                        
                        _selectedDate = DateTime(newYear, newMonth, newDay);
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Done',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFF9800),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // Month wheel picker
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      perspective: 0.005,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(initialItem: selectedMonthIndex),
                      onSelectedItemChanged: (index) {
                        selectedMonthIndex = index;
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: months.length,
                        builder: (context, index) {
                          return Center(
                            child: Text(
                              months[index],
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: index == selectedMonthIndex ? FontWeight.bold : FontWeight.normal,
                                color: index == selectedMonthIndex ? const Color(0xFFFF9800) : Colors.black54,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Year wheel picker
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      perspective: 0.005,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(initialItem: selectedYearIndex),
                      onSelectedItemChanged: (index) {
                        selectedYearIndex = index;
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: years.length,
                        builder: (context, index) {
                          return Center(
                            child: Text(
                              years[index].toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: index == selectedYearIndex ? FontWeight.bold : FontWeight.normal,
                                color: index == selectedYearIndex ? const Color(0xFFFF9800) : Colors.black54,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, Uvaiz!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Add date picker timeline with month selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _showMonthPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF9800),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.calendar_month,
                            color: Color(0xFFFF9800),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              EasyDateTimeLine(
                initialDate: _selectedDate,
                activeColor: const Color(0xFFFF9800), // Orange color for current day
                onDateChange: (selectedDate) {
                  setState(() {
                    _selectedDate = selectedDate;
                  });
                  print("Selected date: $selectedDate");
                },
                dayProps: const EasyDayProps(
                  height: 100.0, // Increased height
                  width: 80.0,   // Increased width
                ),
                timeLineProps: const EasyTimeLineProps(
                  hPadding: 16.0,
                  separatorPadding: 16.0,
                  // centerChild parameter removed as it's not supported in this version
                ),
              ),
              const SizedBox(height: 20),
              // Add your home screen content here
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Tasks',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Add your todo list content here
            ],
          ),
        ),
      ),
    );
  }
}

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Habits',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Add your habits content here
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Add your profile content here
            ],
          ),
        ),
      ),
    );
  }
}