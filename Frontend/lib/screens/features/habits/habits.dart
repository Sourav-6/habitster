import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'create_habit.dart';
import 'habit_detail.dart';
import '../../../services/api_service.dart';
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
      final habits = await _apiService.getHabits();
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
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                          .withAlpha(204), // 0.8 opacity = 204 alpha
                    ),
                  ),
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
      return const Center(child: CircularProgressIndicator());
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
    // We might need habitId later for completion
    // final String habitId = habit['$id'];

    // --- NEW: Determine if completed today ---
    bool isCompletedToday = false;
    if (habit['lastCompletedDate'] != null) {
      final lastCompleted =
          DateTime.parse(habit['lastCompletedDate']).toLocal();
      final now = DateTime.now();
      // Compare year, month, day only
      isCompletedToday = lastCompleted.year == now.year &&
          lastCompleted.month == now.month &&
          lastCompleted.day == now.day;
    }
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)), // Slightly rounder corners
      child: ListTile(
        // Leading Icon (Optional - maybe based on category later)
        // leading: Icon(Icons.fitness_center), // Example

        // Title
        title: Text(
          habitName,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16), // Slightly bolder title
        ),

        // --- NEW: Subtitle for status ---
        subtitle: Text(isCompletedToday
            ? "Completed for today"
            : "Due today"), // Simple status
        // --- End NEW ---

        // Trailing Streak Indicator
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: currentStreak > 0
                  ? Colors.orangeAccent
                  : Colors.grey[400], // Grey out if streak is 0
              size: 22, // Slightly smaller icon
            ),
            const SizedBox(width: 4),
            Text(
              currentStreak.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: currentStreak > 0
                    ? Colors.black87
                    : Colors.grey[400], // Grey out if streak is 0
              ),
            ),
            if (isCompletedToday) ...[
              const SizedBox(width: 10), // Spacing
              IconButton(
                icon: const Icon(Icons.visibility_off_outlined),
                color: Colors.grey,
                tooltip: 'Hide until next due date',
                onPressed: () => _hideHabit(habitId), // Call hide function
              ),
            ]
          ],
        ),

        // Tap action (for expansion later)
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
          ); // <-- REMOVED .then()

          // Handle result after returning from Detail Screen
          if (updatedHabitData != null && mounted) {
            // Refresh the ENTIRE list to get latest data and sorting
            _fetchHabits();
          }
          // --- End UPDATED ---
        },
        contentPadding: const EdgeInsets.symmetric(
            vertical: 8, horizontal: 16), // Adjust padding
      ),
    );
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
