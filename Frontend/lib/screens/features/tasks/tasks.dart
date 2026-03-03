import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'create_task.dart';
import '../../../services/api_service.dart';
import '../../../widgets/habitster_loading_widget.dart';

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
  List<dynamic> _tasks = []; // List to hold active tasks
  List<dynamic> _completedTasks = []; // Persisted completed tasks
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
      // Fetch ALL tasks, split active/completed client-side (avoids Appwrite index requirement)
      final allTasks = await _apiService.getTasks();
      if (mounted) {
        setState(() {
          _tasks = allTasks.where((t) => t['isCompleted'] != true).toList();
          _completedTasks = allTasks.where((t) => t['isCompleted'] == true).toList();
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
                      color: Theme.of(context).textTheme.headlineMedium?.color ??
                          Colors.black.withAlpha(220),
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
      return const Center(child: HabitsterLoadingWidget(fontSize: 32));
    }
    if (_error != null) {
      return Center(child: Text('Error loading tasks: $_error'));
    }
    // Only show empty state when there's truly nothing — no active AND no completed
    if (_tasks.isEmpty && _completedTasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks yet. Add one!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    // Always build the list view (it handles empty active tasks with a "caught up" message)
    return _buildTasksList();
  }
  // --- End NEW ---

  // --- UPDATED: Build the actual list view ---
  Widget _buildTasksList() {
    final List<dynamic> todayTasks = [];
    final List<dynamic> overdueTasks = [];
    final List<dynamic> upcomingTasks = [];
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    for (final task in _tasks) {
      if (task['dueDate'] != null) {
        try {
          final dueDate = DateTime.parse(task['dueDate']).toLocal();
          final dueDateStart = DateTime(dueDate.year, dueDate.month, dueDate.day);

          if (dueDateStart.isAtSameMomentAs(todayStart)) {
            todayTasks.add(task);
          } else if (dueDateStart.isBefore(todayStart)) {
            overdueTasks.add(task); // Past due date
          } else {
            upcomingTasks.add(task); // Future tasks
          }
        } catch (e) {
          // ignore parse errors
        }
      } else {
        // Tasks with no due date go under today
        todayTasks.add(task);
      }
    }

    // Build the UI with sections
    // Build the UI with sections
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // --- Overdue Section (ALWAYS at top when it has items) ---
        if (overdueTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4081), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Overdue',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF4081),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4081).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${overdueTasks.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF4081),
                    ),
                  ),
                ),
              ],
            ).animate().fade().slideX(begin: -0.1),
          ),
          ...overdueTasks.asMap().entries.map((entry) {
            return AnimatedTaskCard(
              task: entry.value,
              index: entry.key,
              apiService: _apiService,
              onCompleted: (taskId) {
                if (mounted) {
                  setState(() {
                    final t = _tasks.firstWhere((element) => element['\$id'] == taskId, orElse: () => null);
                    if (t != null) _completedTasks.add(t);
                    _tasks.removeWhere((t) => t['\$id'] == taskId);
                  });
                }
              },
            );
          }),
          const SizedBox(height: 20),
        ],

        // --- Today Section ---
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Row(
            children: [
              const Icon(Icons.today_rounded, color: Color(0xFF4A00E0), size: 24),
              const SizedBox(width: 8),
              Text(
                'Today',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A00E0),
                ),
              ),
            ],
          ).animate().fade().slideX(begin: -0.1),
        ),
        if (todayTasks.isNotEmpty)
          ...todayTasks.asMap().entries.map((entry) {
            return AnimatedTaskCard(
              task: entry.value,
              index: entry.key + overdueTasks.length,
              apiService: _apiService,
              onCompleted: (taskId) {
                if (mounted) {
                  setState(() {
                    final t = _tasks.firstWhere((element) => element['\$id'] == taskId, orElse: () => null);
                    if (t != null) _completedTasks.add(t);
                    _tasks.removeWhere((t) => t['\$id'] == taskId);
                  });
                }
              },
            );
          })
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
            child: Text(
              'No tasks due today.',
              style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14),
            ),
          ),
        const SizedBox(height: 20),

        // --- Upcoming Section ---
        if (upcomingTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: Row(
              children: [
                const Icon(Icons.event_rounded, color: Color(0xFF00BFA5), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Upcoming',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00BFA5),
                  ),
                ),
              ],
            ).animate().fade().slideX(begin: -0.1),
          ),
          ...upcomingTasks.asMap().entries.map((entry) {
            return AnimatedTaskCard(
              task: entry.value,
              index: entry.key + overdueTasks.length + todayTasks.length,
              apiService: _apiService,
              onCompleted: (taskId) {
                if (mounted) {
                  setState(() {
                    final t = _tasks.firstWhere((element) => element['\$id'] == taskId, orElse: () => null);
                    if (t != null) _completedTasks.add(t);
                    _tasks.removeWhere((t) => t['\$id'] == taskId);
                  });
                }
              },
            );
          }),
          const SizedBox(height: 20),
        ],

        // --- Completed Section ---
        if (_completedTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Completed',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ).animate().fade().slideX(begin: -0.1),
          ),
          ..._completedTasks.map((task) {
            final String title = task['taskName'] ?? task['title'] ?? 'Untitled';
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withAlpha(220),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.green.withAlpha(100), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey.shade600,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fade(duration: 300.ms).slideY(begin: 0.1);
          }),
          const SizedBox(height: 20),
        ],
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withAlpha(100)
                : Colors.white.withAlpha(80),
          ), // subtle white overlay
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

// --- NEW: Animated Task Card Component ---
class AnimatedTaskCard extends StatefulWidget {
  final dynamic task;
  final int index;
  final ApiService apiService;
  final Function(String) onCompleted;

  const AnimatedTaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.apiService,
    required this.onCompleted,
  });

  @override
  State<AnimatedTaskCard> createState() => _AnimatedTaskCardState();
}

class _AnimatedTaskCardState extends State<AnimatedTaskCard> {
  bool _isChecking = false;
  bool _isCompleted = false;

  Future<void> _handleComplete() async {
    if (_isChecking || _isCompleted) return;

    setState(() {
      _isChecking = true;
      _isCompleted = true; // Trigger animation immediately for snappy UX
    });

    final taskId = widget.task['\$id'];
    final bool isRecurring = widget.task['isRecurring'] ?? false;
    final int? recurrenceDays = widget.task['recurrenceDays'];
    final dueDateRaw = widget.task['dueDate'];

    try {
      // 1. Play animation delay so user sees the reward
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      if (!isRecurring) {
        await widget.apiService.deleteTask(taskId);
        widget.onCompleted(taskId); // Notify parent after success
      } else if (recurrenceDays != null) {
        final currentDueDate = dueDateRaw != null ? DateTime.parse(dueDateRaw).toLocal() : DateTime.now();
        final nextDueDate = currentDueDate.add(Duration(days: recurrenceDays));
        await widget.apiService.updateTask(taskId, {
          'dueDate': nextDueDate.toUtc().toIso8601String(),
        });
        widget.onCompleted(taskId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isCompleted = false; // rollback visually
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();
    
    final bool isRecurring = widget.task['isRecurring'] ?? false;
    final String title = widget.task['taskName'] ?? widget.task['title'] ?? 'Untitled';
    final String desc = widget.task['note'] ?? widget.task['description'] ?? '';

    return AnimatedOpacity(
      opacity: _isCompleted ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        transform: Matrix4.translationValues(0, _isCompleted ? 20 : 0, 0),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isCompleted ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isCompleted ? Colors.green.withAlpha(100) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A00E0).withAlpha(15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _handleComplete,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _isCompleted ? Colors.green : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isCompleted ? Colors.green : const Color(0xFF4A00E0).withAlpha(100),
                    width: 2.5,
                  ),
                ),
                child: _isCompleted 
                  ? const Icon(Icons.check, size: 18, color: Colors.white).animate().scale(curve: Curves.easeOutBack)
                  : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isCompleted ? Colors.green.shade700 : Colors.black87,
                      decoration: _isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (desc.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        desc,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                          decoration: _isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (isRecurring)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A00E0).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.repeat, size: 16, color: Color(0xFF4A00E0)),
              ),
          ],
        ),
      ).animate(target: _isCompleted ? 1 : 0)
       .shimmer(duration: 400.ms, color: Colors.green.withAlpha(100))
    ).animate().fade(delay: (widget.index * 100).ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack);
  }
}
