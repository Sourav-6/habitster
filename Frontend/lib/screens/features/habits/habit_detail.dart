import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../services/api_service.dart'; // Import ApiService
import 'package:table_calendar/table_calendar.dart'; // <-- Add table_calendar import
import 'dart:convert';
import 'habit_completion.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/habitster_loading_widget.dart';
import '../../../widgets/glass_card.dart';

class HabitDetailScreen extends StatefulWidget {
  // Accept the habit data map
  final Map<String, dynamic> habit;
  final bool isCompleted;

  const HabitDetailScreen({
    super.key,
    required this.habit,
    required this.isCompleted,
  });

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late AnimationController _animationController;
  List<dynamic> _subtasks = [];
  bool _isLoadingSubtasks = true;
  String? _errorSubtasks;
// Map: subtaskId -> bool (checked status)
  // --- UPDATED: State maps for subtask completion ---
  // Map: subtaskId -> bool (checked status for REQUIRED tasks)
  final Map<String, bool> _checkedRequiredSubtasks = {};
  // Map: optionGroupName -> selectedSubtaskId (for OPTIONAL groups)
  final Map<String, String?> _selectedOptionInGroup = {};
  // --- End UPDATED ---

  Map<String, dynamic>? _todaysHistory;
  List<String> _todaysCompletedSubtaskIds =
      []; // Store IDs fetched from history

  final TextEditingController _notesController = TextEditingController();
  bool _isSavingNote = false; // Loading state for saving note
  bool _isLoadingHistory = false;
  bool _isFavorite = false;
  // --- End NEW ---

  Future<void> _completeHabit() async {
    setState(() {
      _isLoadingSubtasks = true;
    }); // Reuse loading flag for completion
// --- UPDATED: Collect completed IDs from both maps ---
    // 1. Get IDs of checked REQUIRED subtasks
    final List<String> completedRequiredIds = _checkedRequiredSubtasks.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    // 2. Get IDs of selected OPTIONAL subtasks
    final List<String> selectedOptionalIds = _selectedOptionInGroup.entries
        .where((entry) => entry.value != null) // Where an option was selected
        .map((entry) =>
            entry.value!) // Get the selected subtaskId (non-null asserted)
        .toList();

    // 3. Combine the lists
    final List<String> allCompletedIds = [
      ...completedRequiredIds,
      ...selectedOptionalIds
    ];
    // --- End UPDATED ---
    String? notes; // = await _showNotesDialog(); // Placeholder for notes input

    try {
      final updatedHabit = await _apiService.completeHabit(
        widget.habit['\$id'],
        allCompletedIds, // Pass the combined list
        notes: notes,
      );

      // --- NEW: Island Gamification Update ---
      try {
        final difficulty = widget.habit['difficulty']?.toString().toLowerCase() ?? 'medium';
        if (difficulty == 'hard') {
           await _apiService.updateIslandState('addHouse');
        } else if (difficulty == 'medium') {
           await _apiService.updateIslandState('addTree', amount: 2);
        } else {
           await _apiService.updateIslandState('addTree', amount: 1);
        }
      } catch (islandErr) {
        debugPrint('Island Gamification update failed: \$islandErr');
      }
      // --- End NEW ---

      if (mounted) {
        final gamification = updatedHabit['gamification'];
        if (gamification != null) {
          // Show gamification dialog first, then pop
          await _showGamificationRewardDialog(
            gamification['xpGained'] ?? 0,
            gamification['newLevel'],
            gamification['variableRewardMsg'] as String?,
            updatedHabit['currentStreak'] ?? 0,
            updatedHabit['habitName'] ?? 'Habit',
          );
          if (mounted) {
            Navigator.pop(context, updatedHabit);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Habit "${updatedHabit['habitName']}" completed! Streak: ${updatedHabit['currentStreak']}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, updatedHabit);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSubtasks = false;
        }); // Turn off loading
      }
    }
  }

  // --- GAMIFICATION REWARD DIALOG ---
  Future<void> _showGamificationRewardDialog(int xpGained, int? newLevel, String? rewardMsg, int streak, String habitName) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: GlassCard(
              padding: const EdgeInsets.all(32),
              borderRadius: 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0066).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: Color(0xFFFF0066), size: 64)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 1.0, end: 1.2, duration: 800.ms, curve: Curves.easeInOut),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '+$xpGained XP',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF0066),
                    ),
                  ).animate().fade().slideY(begin: 0.5, curve: Curves.easeOutBack),
                  const SizedBox(height: 8),
                  Text(
                    'Journey Well Traveled',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '$streak Day Streak',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  if (rewardMsg != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard_rounded, color: Colors.amber),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              rewardMsg,
                              style: GoogleFonts.poppins(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(delay: 400.ms, duration: 600.ms, curve: Curves.elasticOut),
                  ],
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF0066), Color(0xFFFF4081)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF0066).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Awesome!',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Inside _HabitDetailScreenState class

  // --- NEW: History Calendar Logic ---
  List<dynamic> _fullHistory = []; // Store the full history
  bool _isLoadingHistoryFull = false;
  DateTime _calendarFocusedDay = DateTime.now(); // Controls calendar view month
  DateTime? _calendarSelectedDay; // Tracks tapped day

  // Fetches the full history (call once before showing calendar)
  Future<void> _fetchFullHistory() async {
    if (!mounted || _isLoadingHistoryFull) return;
    setState(() {
      _isLoadingHistoryFull = true;
    });
    try {
      _fullHistory = await _apiService.getHabitHistory(widget.habit['\$id']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading full history: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistoryFull = false;
        });
      }
    }
  }

  // Shows the calendar dialog
  void _showHistoryCalendar(BuildContext parentContext) async {
    final BuildContext capturedContext = context;
    if (_fullHistory.isEmpty && !_isLoadingHistoryFull) {
      await _fetchFullHistory();
      if (!mounted || !capturedContext.mounted) return;
    } else {
      if (!capturedContext.mounted) return;
    }

    showDialog(
      context: capturedContext,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "Activity History",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                    SizedBox(
                      height: 380,
                      child: _isLoadingHistoryFull
                          ? const Center(child: HabitsterLoadingWidget(fontSize: 24))
                          : TableCalendar(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.now().add(const Duration(days: 365)),
                              focusedDay: _calendarFocusedDay,
                              selectedDayPredicate: (day) => isSameDay(_calendarSelectedDay, day),
                              onDaySelected: (selectedDay, focusedDay) {
                                _handleDateSelection(selectedDay, capturedContext);
                                setDialogState(() {
                                  _calendarSelectedDay = selectedDay;
                                  _calendarFocusedDay = focusedDay;
                                });
                              },
                              calendarFormat: CalendarFormat.month,
                              eventLoader: _getEventsForDay,
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                markerDecoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                                cellMargin: const EdgeInsets.all(4),
                                defaultTextStyle: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                                weekendTextStyle: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                                ),
                              ),
                              headerStyle: HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                leftChevronIcon: const Icon(Icons.chevron_left_rounded),
                                rightChevronIcon: const Icon(Icons.chevron_right_rounded),
                              ),
                              onPageChanged: (focusedDay) {
                                setDialogState(() {
                                  _calendarFocusedDay = focusedDay;
                                });
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  // Helper for table_calendar to mark completed days
  List<dynamic> _getEventsForDay(DateTime day) {
    List<dynamic> events = [];
    for (var entry in _fullHistory) {
      DateTime completionDate =
          DateTime.parse(entry['completionDate']).toLocal();
      if (isSameDay(completionDate, day)) {
        events.add('Completed'); // Add a dummy event to show a marker
        break; // Only need one marker per day
      }
    }
    return events;
  }

  // Handles logic when a day is tapped
  void _handleDateSelection(DateTime selectedDay, BuildContext navContext) {
    // Find history entry for the selected date
    final historyEntry = _fullHistory.firstWhere((entry) {
      DateTime completionDate =
          DateTime.parse(entry['completionDate']).toLocal();
      return isSameDay(completionDate, selectedDay);
    }, orElse: () => null // Return null if no entry found
        );

    // --- CORRECTED STRUCTURE ---
    if (historyEntry != null) {
      // --- Logic for COMPLETED date ---

      Navigator.push(
        navContext,
        MaterialPageRoute(
          builder: (context) => HabitCompletionDetailScreen(
            historyEntry: historyEntry,
            allSubtasks: _subtasks,
          ),
        ),
      );
      // --- End logic for COMPLETED date ---
    } else {
      // --- Logic for UNMARKED date (Moved here) ---

      final selectedDayMidnight =
          DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
      final todayMidnight = DateTime.now().toUtc();
      final todayStart = DateTime.utc(
          todayMidnight.year, todayMidnight.month, todayMidnight.day);

      bool wasScheduled = _checkIfHabitWasScheduled(selectedDay);

      String message;
      Color bgColor = Colors.grey;

      if (selectedDayMidnight.isBefore(todayStart)) {
        if (wasScheduled) {
          message = 'Habit missed on this day.';
          bgColor = Colors.orange;
        } else {
          message = 'Habit not scheduled for this day.';
        }
      } else {
        if (wasScheduled) {
          message = 'Habit scheduled, not completed yet.';
        } else {
          message = 'Habit not scheduled for this day.';
        }
      }

      // Check mounted before showing SnackBar
      if (navContext.mounted) {
        ScaffoldMessenger.of(navContext).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: bgColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      // --- End logic for UNMARKED date ---
    }
    // --- END CORRECTED STRUCTURE ---
  }

  // Placeholder - Needs full implementation based on habit frequency
  bool _checkIfHabitWasScheduled(DateTime dateToCheck) {
    try {
      // Get habit details
      final String startDateString = widget.habit['startDate'];
      final String frequencyType = widget.habit['frequencyType'] ?? 'daily';
      final String? frequencyValue = widget.habit['frequencyValue'];

      // Normalize dates to midnight UTC for consistent comparison
      final DateTime startDate = DateTime.parse(startDateString).toUtc();
      final DateTime startDateMidnight =
          DateTime.utc(startDate.year, startDate.month, startDate.day);
      final DateTime dateToCheckMidnight =
          DateTime.utc(dateToCheck.year, dateToCheck.month, dateToCheck.day);

      // 1. Check if the date is before the habit even started
      if (dateToCheckMidnight.isBefore(startDateMidnight)) {
        return false;
      }

      // 2. Check based on frequency type
      switch (frequencyType) {
        case 'daily':
          return true; // If it's after start date, it was scheduled daily

        case 'every_x_days':
          if (frequencyValue == null) return false; // Invalid config
          final int daysBetween = int.tryParse(frequencyValue) ?? 0;
          if (daysBetween <= 0) return false; // Invalid config

          // Calculate days difference from the start date
          final int differenceInDays =
              dateToCheckMidnight.difference(startDateMidnight).inDays;
          // Check if the difference is a multiple of the frequency
          return (differenceInDays % daysBetween == 0);

        case 'specific_days':
          if (frequencyValue == null) return false; // Invalid config
          try {
            // Expect frequencyValue to be like "[1,3,5]" (Monday, Wednesday, Friday)
            // Note: Dart's weekday is 1 (Monday) to 7 (Sunday)
            final List<dynamic> specificDays = json.decode(frequencyValue);
            final List<int> scheduledWeekdays =
                specificDays.map((d) => d as int).toList();
            return scheduledWeekdays.contains(dateToCheckMidnight.weekday);
          } catch (e) {
            return false; // Invalid format
          }

        default:
          return false; // Unknown frequency type
      }
    } catch (e) {
      return false; // Error during calculation
    }
  }
  // --- End Updated ---
  // --- End NEW History Calendar Logic ---

  Future<void> _fetchTodaysHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = true;
    }); // Could use a separate flag or reuse _isLoadingSubtasks
    try {
      _todaysHistory =
          await _apiService.getTodaysHabitHistory(widget.habit['\$id']);
      if (_todaysHistory != null && mounted) {
        setState(() {
          // Pre-fill notes controller
          _notesController.text = _todaysHistory!['notes'] ?? '';
          // Store the completed IDs from history
          _todaysCompletedSubtaskIds =
              List<String>.from(_todaysHistory!['completedSubtaskIds'] ?? []);
          // --- NEW: Populate checked state based on history ---
          _checkedRequiredSubtasks.clear();
          _selectedOptionInGroup.clear();
          Set<String> processedGroups = {};

          // Initialize based on ALL subtasks first (like in _fetchSubtasks)
          for (var st in _subtasks) {
            final subtaskId = st['\$id'] as String;
            final groupName = st['optionGroupName'] as String?;
            final isRequired = st['isRequired'] as bool? ?? true;

            if (!isRequired && groupName != null) {
              if (!processedGroups.contains(groupName)) {
                _selectedOptionInGroup[groupName] = null; // Initialize group
                processedGroups.add(groupName);
              }
            } else {
              _checkedRequiredSubtasks[subtaskId] =
                  false; // Initialize required
            }
          }

          // Now, update state based on IDs from history
          for (String completedId in _todaysCompletedSubtaskIds) {
            // Find the corresponding subtask definition
            final subtaskDef = _subtasks.firstWhere(
                (st) => st['\$id'] == completedId,
                orElse: () =>
                    null // Handle if subtask definition is somehow missing
                );
            if (subtaskDef != null) {
              final groupName = subtaskDef['optionGroupName'] as String?;
              final isRequired = subtaskDef['isRequired'] as bool? ?? true;

              if (!isRequired && groupName != null) {
                // It's an optional task, set it as selected for its group
                _selectedOptionInGroup[groupName] = completedId;
              } else {
                // It's a required task, mark it as checked
                _checkedRequiredSubtasks[completedId] = true;
              }
            }
          }
          // --- End NEW ---
        });
      } else if (mounted) {
        // Handle case where isCompleted was true but no history found (edge case?)

        _notesController.text = '';
        _todaysCompletedSubtaskIds = [];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading today\'s notes: $e'),
              backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  DateTime _calculateEndDate() {
    DateTime start = DateTime.parse(widget.habit['startDate']).toLocal();
    int value = widget.habit['durationValue'] ?? 0;
    String unit = widget.habit['durationUnit'] ?? 'days';

    switch (unit) {
      case 'days':
        return start.add(Duration(days: value));
      case 'weeks':
        return start.add(Duration(days: value * 7));
      case 'months':
        // Approximate, could be refined
        return DateTime(start.year, start.month + value, start.day);
      default:
        return start; // Fallback
    }
  }

  double _calculateCompletionPercentage() {
    DateTime start = DateTime.parse(widget.habit['startDate']).toLocal();
    DateTime end = _calculateEndDate();
    DateTime now = DateTime.now();

    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(end) || now.isAtSameMomentAs(end)) return 100.0;

    int totalDuration = end.difference(start).inDays;
    int elapsedDuration = now.difference(start).inDays;

    if (totalDuration <= 0) return 100.0; // Avoid division by zero

    return (elapsedDuration / totalDuration * 100).clamp(0.0, 100.0);
  }

  String _calculateTimeRemaining() {
    DateTime end = _calculateEndDate();
    DateTime now = DateTime.now();
    Duration remaining = end.difference(now);

    if (remaining.isNegative) return "Completed";

    if (remaining.inDays > 30) {
      // Very approximate month calculation
      int months = (remaining.inDays / 30).floor();
      return "~$months months left";
    } else if (remaining.inDays >= 1) {
      return "${remaining.inDays} days left";
    } else if (remaining.inHours >= 1) {
      return "${remaining.inHours} hours left";
    } else {
      return "Ends today";
    }
  }

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.habit['isFavorite'] ?? false;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // --- UPDATED: Chain the fetches ---
    // Start fetching subtasks first
    _fetchSubtasks().then((_) {
      // AFTER _fetchSubtasks completes, check if mounted and if completed
      if (mounted && widget.isCompleted) {
        // Now fetch history, ensuring _subtasks is populated
        _fetchTodaysHistory();
      }
    });
    // --- End UPDATED ---
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notesController.dispose(); // Dispose the controller
    super.dispose();
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

        // Animated blobs
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
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

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

  Future<void> _saveNote() async {
    setState(() {
      _isSavingNote = true;
    });

    // We need the IDs of subtasks completed today.
    // Since this screen is only shown when completed, we *could*
    // try fetching today's history entry to get them, OR
    // make an assumption based on current state (less reliable if state resets).
    // SAFEST for now: Re-send the currently checked items.
    if (_todaysHistory == null && widget.isCompleted) {
      // Maybe try fetching history again if it failed initially?
      await _fetchTodaysHistory(); // Attempt to fetch if missing
      if (_todaysHistory == null && mounted) {
        // Check again
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Cannot save note: Previous completion details not found.'),
              backgroundColor: Colors.red),
        );
        setState(() {
          _isSavingNote = false;
        });
        return;
      }
    }
    // Use the IDs stored from the history fetch
    final List<String> completedIds = _todaysCompletedSubtaskIds;
    // --- End UPDATED ---

    try {
      // Re-call completeHabit, just adding the notes
      await _apiService.completeHabit(
        widget.habit['\$id'],
        completedIds, // Resend completed IDs (backend handles idempotency if needed)
        notes: _notesController.text, // Pass the notes from controller
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Note saved successfully!'),
              backgroundColor: Colors.green),
        );
        // Optionally pop back? Or just stay here? Staying seems reasonable.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save note: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingNote = false;
        });
      }
    }
  }
  // --- End NEW ---

  Future<void> _fetchSubtasks() async {
    setState(() {
      _isLoadingSubtasks = true;
      _errorSubtasks = null;
    });
    try {
      final subtasks = await _apiService.getSubtasks(widget.habit['\$id']);
      if (mounted) {
        setState(() {
          _subtasks = subtasks; // Keep the raw list
          _isLoadingSubtasks = false;

          // --- UPDATED: Initialize state maps ---
          _checkedRequiredSubtasks.clear();
          _selectedOptionInGroup.clear();
          Set<String> processedGroups = {}; // Keep track of groups initialized

          for (var st in _subtasks) {
            final subtaskId = st['\$id'] as String;
            final groupName = st['optionGroupName'] as String?;
            final isRequired =
                st['isRequired'] as bool? ?? true; // Default to true if null

            if (!isRequired && groupName != null) {
              // Optional Task in a group
              if (!processedGroups.contains(groupName)) {
                _selectedOptionInGroup[groupName] =
                    null; // Initialize group as null (nothing selected)
                processedGroups.add(groupName);
              }
            } else {
              // Required Task (or optional task NOT in a group - treat as required)
              _checkedRequiredSubtasks[subtaskId] =
                  false; // Initialize as unchecked
            }
          }
          // --- End UPDATED ---
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorSubtasks = e.toString();
          _isLoadingSubtasks = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String habitName = widget.habit['habitName'] ?? 'Habit';
    final int currentStreak = widget.habit['currentStreak'] ?? 0;
    // --- NEW: Calculate progress values ---
    final double percentage = _calculateCompletionPercentage();
    final String timeRemaining = _calculateTimeRemaining();
    final bool enableControls = !widget.isCompleted;
    // --- End NEW ---

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          habitName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: _isFavorite ? Colors.amber : Theme.of(context).iconTheme.color,
            ),
            onPressed: () async {
              final newFavoriteStatus = !_isFavorite;
              setState(() {
                _isFavorite = newFavoriteStatus;
              });
              try {
                await _apiService.toggleFavoriteHabit(widget.habit['\$id'], newFavoriteStatus);
                // Also update the local habit map so returning to dashboard keeps the correct state
                widget.habit['isFavorite'] = newFavoriteStatus; 
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isFavorite = !newFavoriteStatus; // revert
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update favorite status'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          _buildGlassmorphicBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Habit Info Card ---
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Streak',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.local_fire_department_rounded,
                                        color: Colors.orange, size: 24),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$currentStreak Days',
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.habit['category'] ?? 'General',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Progress Bar
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Stack(
                                  children: [
                                    FractionallySizedBox(
                                      widthFactor: (percentage / 100).clamp(0, 1),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context).primaryColor,
                                              Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.7),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Overall Progress',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              timeRemaining,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fade().slideY(begin: 0.2, curve: Curves.easeOutBack),

                  const SizedBox(height: 32),

                  // --- Subtasks Section ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtasks',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (enableControls)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          color: Theme.of(context).primaryColor,
                          onPressed: () async {
                            final Map<String, dynamic>? newSubtask =
                                await _showAddSubtaskDialog();
                            if (newSubtask != null && mounted) {
                              setState(() {
                                final subtaskId = newSubtask['\$id'] as String;
                                final groupName =
                                    newSubtask['optionGroupName'] as String?;
                                final isRequired =
                                    newSubtask['isRequired'] as bool? ?? true;

                                if (!isRequired && groupName != null) {
                                  _selectedOptionInGroup.putIfAbsent(
                                      groupName, () => null);
                                }
                                _subtasks.add(newSubtask);
                                if (isRequired) {
                                  _checkedRequiredSubtasks[subtaskId] = false;
                                }
                              });
                            }
                          },
                        ),
                    ],
                  ).animate(delay: 100.ms).fade().slideY(begin: 0.3),

                  const SizedBox(height: 12),

                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    borderRadius: 24,
                    child: _buildSubtaskListSection(enableControls),
                  ).animate(delay: 200.ms).fade().slideY(begin: 0.3),

                  const SizedBox(height: 32),

                  // History Button
                  Center(
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      borderRadius: 16,
                      child: InkWell(
                        onTap: () => _showHistoryCalendar(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'View History',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate(delay: 300.ms).fade(),

                  const SizedBox(height: 32),

                  // --- Action Buttons ---
                  if (widget.isCompleted)
                    _buildNotesSection().animate(delay: 400.ms).fade()
                  else
                    Center(
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoadingSubtasks || !enableControls
                              ? null
                              : _completeHabit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoadingSubtasks
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Complete for Today',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ).animate(delay: 400.ms).fade().scaleXY(begin: 0.9),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    if (_isLoadingHistory) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: HabitsterLoadingWidget(fontSize: 20),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes for Today',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'How was your journey today?',
            hintStyle: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: _isSavingNote ? null : _saveNote,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
            ),
            child: _isSavingNote
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    'Save Note',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // --- End NEW ---

  Widget _buildSubtaskListSection(bool enabled) {
    if (_isLoadingSubtasks) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(strokeWidth: 3)));
    }
    if (_errorSubtasks != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error loading subtasks: $_errorSubtasks',
            style: GoogleFonts.poppins(color: Colors.redAccent),
          ),
        ),
      );
    }
    if (_subtasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No subtasks defined.',
            style: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    List<dynamic> requiredTasks = [];
    Map<String, List<dynamic>> optionalGroups = {};

    for (var st in _subtasks) {
      final groupName = st['optionGroupName'] as String?;
      final isRequired = st['isRequired'] as bool? ?? true;

      if (!isRequired && groupName != null) {
        if (!optionalGroups.containsKey(groupName)) {
          optionalGroups[groupName] = [];
        }
        optionalGroups[groupName]!.add(st);
      } else {
        requiredTasks.add(st);
      }
    }

    List<Widget> children = [];

    // --- Render Required Tasks ---
    if (requiredTasks.isNotEmpty) {
      children.addAll(requiredTasks.asMap().entries.map((entry) {
        final subtask = entry.value;
        final subtaskId = subtask['\$id'] as String;
        return CheckboxListTile(
          title: Text(
            subtask['subtaskName'] ?? 'No Name',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              decoration: _checkedRequiredSubtasks[subtaskId] == true && !enabled
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          value: _checkedRequiredSubtasks[subtaskId] ?? false,
          activeColor: Theme.of(context).primaryColor,
          checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onChanged: enabled
              ? (bool? value) {
                  if (value != null && mounted) {
                    setState(() {
                      _checkedRequiredSubtasks[subtaskId] = value;
                    });
                  }
                }
              : null,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ).animate(delay: (entry.key * 50).ms).fade().slideX(begin: 0.1);
      }));
      
      if (optionalGroups.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              thickness: 1,
              indent: 20,
              endIndent: 20,
            ),
          ),
        );
      }
    }

    // --- Render Optional Groups ---
    int groupIndex = 0;
    optionalGroups.forEach((groupName, subtasksInGroup) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 12, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, 
                size: 16, 
                color: Theme.of(context).primaryColor.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(
                'Choose one: $groupName',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ).animate(delay: (groupIndex * 100).ms).fade(),
      );
      
      _selectedOptionInGroup.putIfAbsent(groupName, () => null);

      children.add(
        Theme(
          data: Theme.of(context).copyWith(
            unselectedWidgetColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
          child: Column(
            children: subtasksInGroup.asMap().entries.map((entry) {
              final subtask = entry.value;
              final subtaskId = subtask['\$id'] as String;

              return RadioListTile<String>(
                title: Text(
                  subtask['subtaskName'] ?? 'No Name',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                value: subtaskId,
                groupValue: _selectedOptionInGroup[groupName],
                activeColor: Theme.of(context).primaryColor,
                onChanged: enabled
                    ? (String? selectedId) {
                        if (mounted) {
                          setState(() {
                            _selectedOptionInGroup[groupName] = selectedId;
                          });
                        }
                      }
                    : null,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ).animate(delay: (groupIndex * 100 + entry.key * 50).ms).fade().slideX(begin: 0.1);
            }).toList(),
          ),
        ),
      );
      groupIndex++;
    });

    return Column(children: children);
  }

  // --- NEW: Function to show the Add Subtask Dialog ---
  Future<Map<String, dynamic>?> _showAddSubtaskDialog() async {
    final formKey = GlobalKey<FormState>();
    final subtaskNameController = TextEditingController();
    final newGroupNameController = TextEditingController();

    String selectedType = 'Required (AND)';
    String? selectedGroupName;
    bool isCreatingNewGroup = false;

    final existingGroups = _subtasks
        .map((st) => st['optionGroupName'] as String?)
        .where((name) => name != null)
        .toSet()
        .toList();

    final Map<String, dynamic>? newSubtaskData = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 24,
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Subtask',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: subtaskNameController,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'What needs to be done?',
                              labelStyle: GoogleFonts.poppins(fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: selectedType,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Subtask Type',
                              labelStyle: GoogleFonts.poppins(fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: ['Required (AND)', 'Optional (OR)']
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedType = value!;
                              });
                            },
                          ),
                          if (selectedType == 'Optional (OR)') ...[
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: selectedGroupName,
                              hint: Text('Select or create group', style: GoogleFonts.poppins(fontSize: 14)),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Optional Group',
                                labelStyle: GoogleFonts.poppins(fontSize: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: [
                                ...existingGroups.map((g) => DropdownMenuItem(value: g!, child: Text(g))),
                                const DropdownMenuItem(
                                  value: 'CREATE_NEW',
                                  child: Text('Create New Group...'),
                                ),
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  isCreatingNewGroup = (value == 'CREATE_NEW');
                                  selectedGroupName = value;
                                });
                              },
                            ),
                            if (isCreatingNewGroup) ...[
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: newGroupNameController,
                                style: GoogleFonts.poppins(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'New Group Name',
                                  labelStyle: GoogleFonts.poppins(fontSize: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'Please enter a group name' : null,
                              ),
                            ]
                          ],
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, null),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).primaryColor,
                                      Theme.of(context).primaryColor.withValues(alpha: 0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (!formKey.currentState!.validate()) return;
                                    final subtaskData = {
                                      'habitId': widget.habit['\$id'],
                                      'subtaskName': subtaskNameController.text,
                                      'isRequired': selectedType == 'Required (AND)',
                                      'optionGroupName': (selectedType == 'Optional (OR)')
                                          ? (isCreatingNewGroup ? newGroupNameController.text : selectedGroupName)
                                          : null,
                                    };
                                    if (selectedType == 'Optional (OR)' && subtaskData['optionGroupName'] == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please select or create an optional group.'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }
                                    try {
                                      final newSubtaskDocument = await _apiService.createSubtask(subtaskData);
                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext, newSubtaskDocument);
                                      }
                                    } catch (e) {
                                      if (mounted && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to add subtask: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: Text(
                                    'Save',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    subtaskNameController.dispose();
    newGroupNameController.dispose();
    return newSubtaskData;
  }
  // --- End NEW Dialog Function ---
}
