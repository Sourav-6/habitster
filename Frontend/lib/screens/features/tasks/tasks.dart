import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'create_task.dart';
import '../../../services/api_service.dart';

class TasksScreen extends StatefulWidget {
  // Changed to StatefulWidget
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService(); // Added ApiService instance
  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;
  bool _isButtonExpanded = false;

  // --- NEW State Variables ---
  List<dynamic> _tasks = []; // List to hold tasks
  bool _isLoading = true; // Loading indicator state
  String? _error; // Error message state
  // --- End NEW State Variables ---

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

    // --- NEW: Fetch tasks when the screen loads ---
    _fetchTasks();
    // --- End NEW ---
  }

  // --- NEW: Function to fetch tasks ---
  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tasks = await _apiService.getTasks();
      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if widget is still mounted
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
          _buildGlassmorphicBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Tasks',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withAlpha(204),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // --- UPDATED: Conditionally show loading, error, or list ---
                  Expanded(
                    child: _buildBodyContent(),
                  ),
                  // --- End UPDATED ---
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 130,
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
      return Center(child: Text('Error loading tasks: $_error'));
    }
    if (_tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks yet. Add one!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    // If loaded, no error, and tasks exist, build the list
    return _buildTasksList();
  }
  // --- End NEW ---

  // --- UPDATED: Build the actual list view ---
  Widget _buildTasksList() {
    final List<dynamic> todayTasks = [];
    final List<dynamic> overdueTasks = [];
    final now = DateTime.now();
    // Create a DateTime object representing today at midnight for comparison
    final todayStart = DateTime(now.year, now.month, now.day);

    // Filter tasks into the two lists
    for (final task in _tasks) {
      if (task['dueDate'] != null) {
        try {
          final dueDate = DateTime.parse(task['dueDate']).toLocal();
          // Create a DateTime object for the due date at midnight
          final dueDateStart =
              DateTime(dueDate.year, dueDate.month, dueDate.day);

          if (dueDateStart.isAtSameMomentAs(todayStart)) {
            todayTasks.add(task);
          } else if (dueDateStart.isBefore(todayStart)) {
            overdueTasks.add(task);
          }
          // Tasks due in the future are ignored for now
        } catch (e) {
          // Optionally add tasks with invalid dates to a separate list or handle them
        }
      }
    }

    // Build the UI with sections
    return ListView(
      // Use a regular ListView to hold Columns/Sections
      children: [
        // --- Overdue Section ---
        if (overdueTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text(
              'Overdue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ),
          ...overdueTasks
              .map((task) => _buildTaskTile(task)), // Use helper for ListTile
          const SizedBox(height: 15), // Spacer between sections
        ],

        // --- Today Section ---
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Text(
            'Today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
        if (todayTasks.isNotEmpty)
          ...todayTasks
              .map((task) => _buildTaskTile(task)) // Use helper for ListTile
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
            child: Text('No tasks for today.',
                style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }

  // lib/screens/features/tasks/tasks.dart

  // --- UPDATED: Helper widget to build a task ListTile with completion logic ---
  Widget _buildTaskTile(dynamic task) {
    final DateTime? dueDate = task['dueDate'] != null
        ? DateTime.parse(task['dueDate']).toLocal()
        : null;
    final String formattedDate = dueDate != null
        ? '${dueDate.day}/${dueDate.month}/${dueDate.year}' // Simple dd/MM/yyyy format
        : 'No due date';

    // Get task properties needed for completion logic
    final String taskId = task['\$id']; // Appwrite document ID
    final bool isRecurring = task['isRecurring'] ?? false;
    final int? recurrenceDays = task['recurrenceDays'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Checkbox(
          value: false, // Checkbox is always unchecked initially when displayed
          onChanged: (bool? value) async {
            // Make onChanged async
            if (value == true) {
              // Only proceed if checkbox is checked
              // Show a temporary loading state (optional)
              // You could disable the checkbox or show an overlay here

              try {
                if (!isRecurring) {
                  // --- One-time task: Delete ---
                  await _apiService.deleteTask(taskId);
                  if (mounted) {
                    // Check if widget is still mounted
                    setState(() {
                      _tasks.removeWhere(
                          (t) => t['\$id'] == taskId); // Remove from list
                    });
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Task completed and removed!'),
                          backgroundColor: Colors.green),
                    );
                  }
                } else if (recurrenceDays != null && recurrenceDays > 0) {
                  // --- Recurring task: Update due date ---
                  if (dueDate != null) {
                    final nextDueDate =
                        dueDate.add(Duration(days: recurrenceDays));
                    final updatedTask = await _apiService.updateTask(taskId, {
                      'dueDate': nextDueDate.toIso8601String(),
                    });
                    if (mounted) {
                      // Check if widget is still mounted
                      setState(() {
                        // Find the index and update the task in the list
                        final index =
                            _tasks.indexWhere((t) => t['\$id'] == taskId);
                        if (index != -1) {
                          _tasks[index] = updatedTask;
                          // We might need to re-sort or re-filter the list here
                          // For now, just updating in place. A re-fetch might be simpler.
                        }
                        // OPTIONAL: Re-fetch all tasks to ensure correct sorting
                        _fetchTasks();
                      });
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Task completed! Next due on ${nextDueDate.day}/${nextDueDate.month}/${nextDueDate.year}')),
                      );
                    }
                  } else {
                    throw Exception(
                        'Due date is null for recurring task $taskId');
                  }
                } else {
                  // Handle case where isRecurring is true but recurrenceDays is invalid
                  throw Exception(
                      'Invalid recurrence settings for task $taskId');
                }
              } catch (e) {
                if (mounted) {
                  // Check if widget is still mounted
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error updating task: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              } finally {
                // Hide loading state if you showed one
              }
            }
          },
          activeColor: const Color(0xFFFF4747), // Use task primary color
        ),
        title: Text(task['taskName'] ?? 'No Name',
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: task['note'] != null && task['note']!.isNotEmpty
            ? Text(task['note'], maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing: Text(formattedDate),
      ),
    );
  }
  // --- End UPDATED ---

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
                  right: -80 +
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
                  left: -120 +
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
                  right: MediaQuery.of(context).size.width / 3 -
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
                  right: MediaQuery.of(context).size.width * 0.7,
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
                  right: MediaQuery.of(context).size.width * 0.6,
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

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isButtonExpanded = !_isButtonExpanded;
          if (_isButtonExpanded) {
            _buttonAnimationController.forward();
            // Show the create task screen
            _showCreateTaskScreen();
          } else {
            _buttonAnimationController.reverse();
          }
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFFFF4747), // Red color #FF4747
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

  // lib/screens/features/tasks/tasks.dart

  void _showCreateTaskScreen() async {
    FocusScope.of(context).requestFocus(FocusNode());

    final newTask = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(100),
      builder: (context) {
        return const Padding(
          padding: EdgeInsets.only(top: 80),
          child: CreateTaskScreen(),
        );
      },
    );

    if (mounted) {
      // Always check mounted after await
      setState(() {
        _isButtonExpanded = false;
        _buttonAnimationController.reverse();
      });
    }

    if (newTask != null) {
      if (mounted) {
        // Check mounted again before setState
        setState(() {
          _tasks.add(newTask); // Add to the list
        });
      }
      // --- End NEW ---
    }
  }
  // --- End UPDATED ---
}
