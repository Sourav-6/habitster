// lib/screens/features/habits/habit_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../services/api_service.dart'; // Import ApiService
import 'package:table_calendar/table_calendar.dart'; // <-- Add table_calendar import
import 'dart:convert';
import 'habit_completion.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/habitster_loading_widget.dart';

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

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final ApiService _apiService = ApiService();
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
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFFF0066), size: 64)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 1.0, end: 1.2, duration: 600.ms, curve: Curves.easeInOut),
                const SizedBox(height: 16),
                Text(
                  '+$xpGained XP!',
                  style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFFFF0066)),
                ).animate().fade().slideY(begin: 0.5, curve: Curves.easeOutBack),
                const SizedBox(height: 8),
                Text(
                  'You crushed "$habitName".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text('$streak Day Streak', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (rewardMsg != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.card_giftcard, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(child: Text(rewardMsg, style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.elasticOut),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0066),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Awesome!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
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
    // Fetch history first if not already done (or if might be stale)
    if (_fullHistory.isEmpty && !_isLoadingHistoryFull) {
      await _fetchFullHistory();
      if (!mounted || !capturedContext.mounted) {
        return;
      }
      // Check again after await
    } else {
      // If history was already loaded, still check original context
      if (!capturedContext.mounted) return;
    }

    showDialog(
      context: capturedContext, // Use context from builder/parent
      builder: (dialogContext) {
        // Use StatefulBuilder for calendar's internal state management
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("${widget.habit['habitName']} - History"),
            contentPadding:
                EdgeInsets.zero, // Remove default padding for calendar
            content: SizedBox(
              // Constrain calendar size
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height *
                  0.6, // Adjust height as needed
              child: _isLoadingHistoryFull
                  ? const Center(child: HabitsterLoadingWidget(fontSize: 24))
                  : TableCalendar(
                      firstDay:
                          DateTime.utc(2020, 1, 1), // Adjust range as needed
                      lastDay: DateTime.now()
                          .add(const Duration(days: 365)), // Allow future view?
                      focusedDay: _calendarFocusedDay,
                      selectedDayPredicate: (day) {
                        // Use `_calendarSelectedDay` to manage selection state
                        return isSameDay(_calendarSelectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        // Handle date tapping logic HERE
                        _handleDateSelection(selectedDay, capturedContext);
                        // --- End FIX --- // Pass parentContext for navigation
                        // Close dialog immediately after selection? Or keep open? Let's keep open for now.
                        setDialogState(() {
                          // Update selection in dialog
                          _calendarSelectedDay = selectedDay;
                          _calendarFocusedDay =
                              focusedDay; // update `_focusedDay` here as well
                        });
                      },
                      calendarFormat: CalendarFormat.month,
                      eventLoader:
                          _getEventsForDay, // Function to mark completed dates
                      calendarStyle: CalendarStyle(
                        // Customize appearance if desired
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withAlpha(50),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          // Decoration for event markers
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        weekendTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(180)),
                        outsideTextStyle: TextStyle(color: Theme.of(context).disabledColor),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false, // Hide format button
                        titleCentered: true,
                      ),
                      onPageChanged: (focusedDay) {
                        // Update focused day when user swipes months
                        setDialogState(() {
                          _calendarFocusedDay = focusedDay;
                        });
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              )
            ],
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
    _notesController.dispose(); // Dispose the controller
    super.dispose();
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
      appBar: AppBar(title: Text(habitName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Display Habit Info (UPDATED) ---
            Text('Current Streak: 🔥 $currentStreak',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            // Display Percentage Complete & Days Left
            Row(
              // Use a Row for better layout
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value:
                        percentage / 100.0, // Needs value between 0.0 and 1.0
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${percentage.toStringAsFixed(0)}%'), // Show percentage
              ],
            ),
            const SizedBox(height: 5),
            Text('Time Remaining: $timeRemaining',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                )),
            const SizedBox(height: 20),

            // --- Subtasks Section ---
            const Text('Subtasks:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildSubtaskListSection(
                enableControls), // Use helper for conditional display
            const SizedBox(height: 20),

            if (enableControls)
              Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Subtask'),
                  onPressed: () async {
                    // --- Await the data map ---
                    final Map<String, dynamic>? newSubtask =
                        await _showAddSubtaskDialog();
                    // --- Use WidgetsBinding to add to state ---
                    if (newSubtask != null) {
                      if (!mounted) return;

                      setState(() {
                        final subtaskId = newSubtask['\$id'] as String;
                        final groupName =
                            newSubtask['optionGroupName'] as String?;
                        final isRequired =
                            newSubtask['isRequired'] as bool? ?? true;

                        // 🔑 IMPORTANT: initialize optional group BEFORE UI sees it
                        if (!isRequired && groupName != null) {
                          _selectedOptionInGroup.putIfAbsent(
                              groupName, () => null);
                        }

                        _subtasks.add(newSubtask);

                        if (isRequired) {
                          _checkedRequiredSubtasks[subtaskId] = false;
                        }
                      });
                      // End addPostFrameCallback
                    }
                    // --- End Use ---
                  },
                ),
              ),

            const SizedBox(height: 30),

            Center(
              // Or adjust layout as needed
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('History'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300]), // Neutral color?
                onPressed: () {
                  _showHistoryCalendar(context); // Call the new dialog function
                },
              ),
            ),
            const SizedBox(height: 20),

            // --- UPDATED: Show Notes Section OR Action Buttons ---
            if (widget.isCompleted)
              _buildNotesSection() // Show notes input if completed
            else
              Center(
                child: ElevatedButton(
                  onPressed: _isLoadingSubtasks || !enableControls
                      ? null
                      : _completeHabit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor),
                  child: _isLoadingSubtasks
                      ? const SizedBox(
                          // Constrain the indicator size
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color.fromARGB(255, 255, 255,
                                255), // White indicator on colored button
                          ),
                        )
                      : const Text('Complete for Today',
                          style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        ),
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
        const Text(
          'Notes for Today:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3, // Allow a few lines for notes
          decoration: InputDecoration(
            hintText: 'Add any notes about today\'s habit...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton(
            onPressed: _isSavingNote ? null : _saveNote, // Call save function
            child: _isSavingNote
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save Note'),
          ),
        ),
      ],
    );
  }

  // --- End NEW ---

  // Helper to build subtask list or loading/error indicators
  Widget _buildSubtaskListSection(bool enabled) {
    if (_isLoadingSubtasks) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator()));
    }
    if (_errorSubtasks != null) {
      return Center(child: Text('Error loading subtasks: $_errorSubtasks'));
    }
    if (_subtasks.isEmpty) {
      return const ListTile(title: Text('No subtasks defined.'));
    }

    // --- NEW: Grouping and Sorting Logic ---
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

    // --- Render Required Tasks First ---
    if (requiredTasks.isNotEmpty) {
      children.addAll(requiredTasks.map((subtask) {
        final subtaskId = subtask['\$id'] as String;
        return CheckboxListTile(
          title: Text(subtask['subtaskName'] ?? 'No Name'),
          value: _checkedRequiredSubtasks[subtaskId] ?? false,
          onChanged: enabled
              ? (bool? value) {
                  // Only allow changes if enabled
                  if (value != null) {
                    if (!mounted) return;
                    setState(() {
                      _checkedRequiredSubtasks[subtaskId] = value;
                    });
                  }
                }
              : null,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        );
      }));
      // Add a divider if there are also optional groups
      if (optionalGroups.isNotEmpty) {
        children.add(const Divider(thickness: 1, height: 20));
      }
    }

    // --- Render Optional Groups ---

    optionalGroups.forEach((groupName, subtasksInGroup) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            'Choose one: $groupName',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      );
      _selectedOptionInGroup.putIfAbsent(groupName, () => null);

      children.add(
        RadioGroup<String>(
          groupValue: _selectedOptionInGroup[groupName],
          onChanged: (String? selectedId) {
            if (!enabled || !mounted) return;

            setState(() {
              _selectedOptionInGroup[groupName] = selectedId;
            });
          },
          child: Column(
            children: subtasksInGroup.map((subtask) {
              final subtaskId = subtask['\$id'] as String;

              return RadioListTile<String>(
                title: Text(subtask['subtaskName'] ?? 'No Name'),
                value: subtaskId,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ),
        ),
      );

      children.add(const Divider(thickness: 1, height: 20));
    });

    // Add a divider after each group if needed

    // Remove the last divider if it exists
    if (children.isNotEmpty && children.last is Divider) {
      children.removeLast();
    }

    return Column(children: children);
    // --- End NEW Grouping/Rendering ---
  }

  // --- NEW: Function to show the Add Subtask Dialog ---
  Future<Map<String, dynamic>?> _showAddSubtaskDialog() async {
    final formKey = GlobalKey<FormState>();
    final subtaskNameController = TextEditingController();
    final newGroupNameController = TextEditingController();

    String selectedType =
        'Required (AND)'; // 'Required (AND)' or 'Optional (OR)'
    String? selectedGroupName; // For selecting an existing OR group
    bool isCreatingNewGroup = false;

    // Find existing optional groups for this habit
    final existingGroups = _subtasks
        .map((st) => st['optionGroupName'] as String?)
        .where((name) => name != null)
        .toSet()
        .toList();

    final Map<String, dynamic>? newSubtaskData =
        await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage the dialog's own state
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add a New Subtask'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: subtaskNameController,
                        decoration:
                            const InputDecoration(labelText: 'Subtask Name'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Cannot be empty'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        decoration:
                            const InputDecoration(labelText: 'Subtask Type'),
                        items: ['Required (AND)', 'Optional (OR)']
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedType = value!;
                          });
                        },
                      ),
                      if (selectedType == 'Optional (OR)') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedGroupName,
                          hint: const Text('Select group or create new'),
                          decoration: const InputDecoration(
                              labelText: 'Optional Group'),
                          items: [
                            ...existingGroups.map((g) =>
                                DropdownMenuItem(value: g!, child: Text(g))),
                            const DropdownMenuItem(
                                value: 'CREATE_NEW',
                                child: Text('Create New Group...')),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              isCreatingNewGroup = (value == 'CREATE_NEW');
                              selectedGroupName = value;
                            });
                          },
                        ),
                        if (isCreatingNewGroup) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: newGroupNameController,
                            decoration: const InputDecoration(
                                labelText: 'New Group Name'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Cannot be empty'
                                : null,
                          ),
                        ]
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, null), // Pop with null
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final subtaskData = {
                      'habitId': widget.habit['\$id'],
                      'subtaskName': subtaskNameController.text,
                      'isRequired': selectedType == 'Required (AND)',
                      'optionGroupName': (selectedType == 'Optional (OR)')
                          ? (isCreatingNewGroup
                              ? newGroupNameController.text
                              : selectedGroupName)
                          : null,
                    };

                    // Basic validation for group name
                    if (selectedType == 'Optional (OR)' &&
                        subtaskData['optionGroupName'] == null) {
                      // Use 'context' directly here from the builder
                      ScaffoldMessenger.of(context).showSnackBar(
                        // Use builderContext
                        const SnackBar(
                            content: Text(
                                'Please select or create an optional group.'),
                            backgroundColor: Colors.orange),
                      );
                      return;
                    }

                    try {
                      final newSubtaskDocument =
                          await _apiService.createSubtask(subtaskData);
                      if (!dialogContext.mounted) return;
                      // --- Return the data map on Success ---
                      Navigator.pop(
                          dialogContext, newSubtaskDocument); // Pop with data
                    } catch (e) {
                      // --- Use 'context' from builder for SnackBar ---
                      // Also ensure the main State's 'mounted' is checked
                      if (mounted && context.mounted) {
                        // Check both
                        ScaffoldMessenger.of(context).showSnackBar(
                          // Use context
                          SnackBar(
                              content: Text('Failed to add subtask: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                      // --- End Use ---
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
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
