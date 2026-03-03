import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'create_habit.dart';
import 'habit_detail.dart';
import '../../../services/api_service.dart';
import '../../../widgets/habitster_loading_widget.dart';
import 'hidden_habits.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService(); // Added ApiService instance
  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;

  // --- NEW State Variables ---
  List<dynamic> _habits = []; // List to hold habits
  bool _isLoading = true; // Loading indicator state
  String? _error; // Error message state
  // --- End NEW State Variables ---
  final Set<String> _completedTodayHabitIds = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchHabits();
  }

// --- NEW: Function to hide a habit ---
  Future<void> _hideHabit(String habitId) async {
    // Optional: Add a confirmation dialog?
    try {
      await _apiService.hideHabit(habitId);
      if (mounted) {
        setState(() {
          // Remove from local list AND completed set
          _habits.removeWhere((h) => h['\$id'] == habitId);
          _completedTodayHabitIds.remove(habitId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habit hidden until next due date.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error hiding habit: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
  // --- End NEW -

  // --- Helper to check completion status ---
  bool _isHabitCompletedToday(dynamic habit) {
    if (habit['lastCompletedDate'] == null) return false;
    try {
      final lastCompleted = DateTime.parse(habit['lastCompletedDate']).toLocal();
      final now = DateTime.now();
      return lastCompleted.year == now.year &&
          lastCompleted.month == now.month &&
          lastCompleted.day == now.day;
    } catch (e) {
      return false;
    }
  }

  // --- NEW: Function to fetch habits ---
  Future<void> _fetchHabits() async {
    // Don't show loading indicator on subsequent refreshes, only initial load
    if (_habits.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      }); // Clear previous error on refresh
    }

    try {
      final List<dynamic> habits = await _apiService.getHabits();
      
      // Sort: Completed today goes to bottom
      habits.sort((a, b) {
        final bool aDone = _isHabitCompletedToday(a);
        final bool bDone = _isHabitCompletedToday(b);
        if (aDone == bDone) return 0;
        return aDone ? 1 : -1;
      });

      if (mounted) {
        setState(() {
          _habits = habits;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonAnimationController.dispose();
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
                    'My Habits',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineMedium?.color ??
                          Colors.black.withAlpha(220),
                    ),
                  ).animate().fade().slideY(begin: -0.2, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildBodyContent(),
                  ),
                  const SizedBox(height: 10),
                  // --- NEW: Show Hidden Button ---
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        // Make async
                        // Navigate and wait for a potential result
                        final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const HiddenHabitsScreen()));
                        // If HiddenHabitsScreen pops with 'true', refresh the list
                        if (result == true && mounted) {
                          _fetchHabits();
                        }
                      },
                      child: const Text('Show Hidden Habits'),
                    ),
                  ),
                  const SizedBox(
                      height: 90), // Ensure space above bottom nav bar
                  // --- End NEW ---
                ],
              ),
            ),
          ),

          // Floating action button - positioned higher to be above navbar
          Positioned(
            bottom: 130, // Raised higher above navbar
            right: 30,
            child: _buildAddButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: HabitsterLoadingWidget(fontSize: 32));
    }
    if (_error != null) {
      // Add a refresh button on error
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading habits: $_error'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchHabits, // Retry fetch
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }
    if (_habits.isEmpty) {
      return const Center(
        child: Text(
          'No habits due today. Add one!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    // If loaded, no error, and habits exist, build the list
    return _buildHabitsList();
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
                      const Color(0xFF121212), // Deep dark
                      const Color(0xFF1E1E2C), // Dark blue/purple
                    ]
                  : [
                      const Color(0xFFF9F9FF), // Very light purple/white
                      const Color(0xFFF0F8FF), // Very light blue
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
              sigmaX: 70,
              sigmaY: 70), // Softer blur
          child: Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withAlpha(100)
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

  // lib/screens/features/habits/habits.dart

  // --- UPDATED: Build the actual list view ---
  Widget _buildHabitsList() {
    return ListView.builder(
      itemCount: _habits.length,
      itemBuilder: (context, index) {
        final habit = _habits[index];
        // Use a dedicated builder function for the tile
        return _buildHabitTile(habit);
      },
    );
  }

  Widget _buildHabitTile(dynamic habit) {
    final String habitId = habit['\$id'];
    final String habitName = habit['habitName'] ?? 'No Name';
    final int currentStreak = habit['currentStreak'] ?? 0;
    
    // Gamification properties
    final String difficulty = habit['difficulty'] ?? 'Medium';
    final String category = habit['category'] ?? 'Productivity';

    // --- NEW: Determine if completed today ---
    final bool isCompletedToday = _isHabitCompletedToday(habit);
    // --- End NEW --

    // --- NEW: Update local completed set (needed if _fetchHabits runs again) ---
    if (isCompletedToday && !_completedTodayHabitIds.contains(habitId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _completedTodayHabitIds.add(habitId);
          });
        }
      });
    } else if (!isCompletedToday && _completedTodayHabitIds.contains(habitId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _completedTodayHabitIds.remove(habitId);
          });
        }
      });
    }
    // --- End NEW ---

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isCompletedToday 
            ? Theme.of(context).cardColor.withAlpha(150) // More transparent when completed
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isCompletedToday 
                ? Colors.transparent 
                : (Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black.withAlpha(100) 
                    : const Color(0xFFFF0066).withAlpha(15)),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isCompletedToday 
              ? Colors.grey.withAlpha(80) 
              : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withAlpha(20) : Colors.transparent),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final updatedHabitData = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                // --- Pass completion status to detail screen ---
                builder: (context) => HabitDetailScreen(
                    habit: Map<String, dynamic>.from(
                        habit), // Pass original habit data
                    isCompleted: isCompletedToday // Pass the flag
                    ),
              ),
            );

            // Handle result after returning from Detail Screen
            if (updatedHabitData != null && mounted) {
              // Refresh the ENTIRE list to get latest data and sorting
              _fetchHabits();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Activity Circle / Checkmark
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isCompletedToday 
                      ? const LinearGradient(colors: [Colors.green, Colors.lightGreen])
                      : const LinearGradient(colors: [Color(0xFFFF0066), Color(0xFFFF4081)]),
                    boxShadow: isCompletedToday ? [] : [
                      BoxShadow(
                        color: const Color(0xFFFF0066).withAlpha(80),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Icon(
                    isCompletedToday ? Icons.check_rounded : Icons.star_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ).animate(target: isCompletedToday ? 1 : 0)
                 .swap(builder: (context, child) => child!.animate().rotate(duration: 400.ms, curve: Curves.easeOut)),

                const SizedBox(width: 16),
                
                // Habit Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        habitName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isCompletedToday 
                              ? Colors.grey[600] 
                              : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                          decoration: isCompletedToday ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: difficulty == 'Hard' ? Colors.red[100] : difficulty == 'Small' ? Colors.green[100] : Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              difficulty,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: difficulty == 'Hard' ? Colors.red[800] : difficulty == 'Small' ? Colors.green[800] : Colors.orange[800],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompletedToday ? "Completed" : "Due today",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isCompletedToday ? Colors.green : const Color(0xFFFF0066),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Streak info and hide button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: currentStreak > 0
                          ? Colors.orangeAccent
                          : Colors.grey[300],
                      size: 24,
                    ).animate(target: (currentStreak > 0 && !isCompletedToday) ? 1 : 0)
                     .shimmer(duration: 1500.ms).scaleXY(begin: 0.9, end: 1.1, curve: Curves.easeInOut, duration: 1.seconds).then().scaleXY(begin: 1.1, end: 0.9, curve: Curves.easeInOut, duration: 1.seconds),
                    const SizedBox(width: 6),
                      Text(
                        currentStreak.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: currentStreak > 0
                              ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)
                              : Colors.grey[400],
                        ),
                      ),
                    if (isCompletedToday) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.visibility_off_rounded),
                        color: Colors.grey[400],
                        iconSize: 22,
                        tooltip: 'Hide until next due date',
                        onPressed: () => _hideHabit(habitId),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(duration: 600.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  // --- End UPDATED ---
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () async {
        final bool? habitCreated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const CreateHabitScreen()),
        );

        // If a habit was successfully created, refresh the habit list
        if (habitCreated == true && mounted) {
          _fetchHabits(); // <--- CALL FETCH HABITS
        }

        // Reset button animation (optional, you might remove this animation)
        if (mounted) {
          // Assuming you still use this?
          _buttonAnimationController.reverse();
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFFFF0066), // Single pink color
        ),
        child: AnimatedBuilder(
          animation: _buttonAnimationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _buttonAnimationController.value *
                  math.pi /
                  4, // Rotate 45 degrees
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            );
          },
        ),
      ),
    );
  }
}
