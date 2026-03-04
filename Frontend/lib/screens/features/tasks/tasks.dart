import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'create_task.dart';
import '../../../services/api_service.dart';
import '../../../widgets/habitster_loading_widget.dart';
import '../../../widgets/glass_card.dart';

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
              key: ValueKey(entry.value['\$id']),
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
              onRecurringUpdated: (updatedTask) {
                if (mounted) {
                  setState(() {
                    final index = _tasks.indexWhere((t) => t['\$id'] == updatedTask['\$id']);
                    if (index != -1) _tasks[index] = updatedTask;
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
              key: ValueKey(entry.value['\$id']),
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
              onRecurringUpdated: (updatedTask) {
                if (mounted) {
                  setState(() {
                    final index = _tasks.indexWhere((t) => t['\$id'] == updatedTask['\$id']);
                    if (index != -1) _tasks[index] = updatedTask;
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
              key: ValueKey(entry.value['\$id']),
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
              onRecurringUpdated: (updatedTask) {
                if (mounted) {
                  setState(() {
                    final index = _tasks.indexWhere((t) => t['\$id'] == updatedTask['\$id']);
                    if (index != -1) _tasks[index] = updatedTask;
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
            return GlassCard(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              blur: 8,
              borderColor: Colors.green.withValues(alpha: 0.2),
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.05),
                  Colors.green.withValues(alpha: 0.02),
                ],
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
                      const Color(0xFF0A0A12),
                      const Color(0xFF121220),
                    ]
                  : [
                      const Color(0xFFFAFAFF),
                      const Color(0xFFF5F9FF),
                    ],
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
                ? Colors.black.withValues(alpha: 0.35)
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
  final Function(dynamic)? onRecurringUpdated;

  const AnimatedTaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.apiService,
    required this.onCompleted,
    this.onRecurringUpdated,
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
        final updatedTask = await widget.apiService.updateTask(taskId, {
          'dueDate': nextDueDate.toUtc().toIso8601String(),
        });
        
        // Notify parent that the recurring task was updated, but leave visually complete briefly for UX.
        // It should NOT be permanently moved to completed list.
        if (widget.onRecurringUpdated != null) {
           widget.onRecurringUpdated!(updatedTask);
        }
        
        // Optionally revert checkmark after a delay so they can check it again tomorrow!
        if (mounted) {
           Future.delayed(const Duration(milliseconds: 1000), () {
             if (mounted) {
               setState(() {
                 _isChecking = false;
                 _isCompleted = false;
               });
             }
           });
        }
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
      child: GlassCard(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        blur: _isCompleted ? 5 : 15,
        borderColor: _isCompleted 
            ? Colors.green.withValues(alpha: 0.1) 
            : Colors.transparent,
        gradient: _isCompleted 
            ? LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.05),
                  Colors.green.withValues(alpha: 0.02),
                ],
              )
            : null,
        shadows: [
          BoxShadow(
            color: const Color(0xFF4A00E0).withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
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
        ),
      ).animate(target: _isCompleted ? 1 : 0)
       .shimmer(duration: 400.ms, color: Colors.green.withValues(alpha: 0.2)),
    ).animate().fade(delay: (widget.index * 100).ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}
