// lib/screens/features/habits/habit_completion_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Import ApiService if you need to fetch subtask names later
// import '../../../services/api_service.dart';

class HabitCompletionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> historyEntry;
  // Optional: Pass the full list of subtask definitions if needed
  final List<dynamic> allSubtasks;
  const HabitCompletionDetailScreen({
    super.key,
    required this.historyEntry,
    required this.allSubtasks,
    // this.allSubtasks = const [],
  });

  @override
  State<HabitCompletionDetailScreen> createState() =>
      _HabitCompletionDetailScreenState();
}

class _HabitCompletionDetailScreenState
    extends State<HabitCompletionDetailScreen> {
  // final ApiService _apiService = ApiService(); // If needed later
  // Map<String, String> _subtaskNames = {}; // To store fetched names

  @override
  void initState() {
    super.initState();
    // Optional: If you didn't pass all subtasks, you could fetch names here
    // _fetchSubtaskNamesIfNeeded();
  }

  // Optional function to fetch names if not passed
  /*
  Future<void> _fetchSubtaskNamesIfNeeded() async {
    // If allSubtasks were passed, populate map directly
    if (widget.allSubtasks.isNotEmpty) {
       setState(() {
          _subtaskNames = { for (var st in widget.allSubtasks) st['\$id'] : st['subtaskName'] };
       });
       return;
    }
    // Otherwise, fetch them (might require modifying getSubtasks or a new endpoint)
    // ... fetching logic ...
  }
  */

  @override
  Widget build(BuildContext context) {
    final DateTime completionDate =
        DateTime.parse(widget.historyEntry['completionDate']).toLocal();
    final String formattedDate = DateFormat('MMMM d, yyyy')
        .format(completionDate); // e.g., October 21, 2025
    final Set<String> completedIds =
        Set<String>.from(widget.historyEntry['completedSubtaskIds'] ?? []);
    final String notes =
        widget.historyEntry['notes'] ?? 'No notes added for this day.';

    return Scaffold(
      appBar: AppBar(title: Text('Details for $formattedDate')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          // Use ListView for potentially long notes/subtask lists
          children: [
            Text('Completion Details',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            Text('Subtasks Status:',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (widget.allSubtasks.isEmpty)
              const Text('  - (No subtasks defined for this habit)')
            else
              Column(
                // Use Column within ListView if list is short
                children: widget.allSubtasks.map((subtask) {
                  final subtaskId = subtask['\$id'] as String;
                  final subtaskName =
                      subtask['subtaskName'] ?? 'Unnamed Subtask';
                  // Check if this subtask's ID is in the completed set
                  final bool wasCompleted = completedIds.contains(subtaskId);

                  return ListTile(
                    leading: Checkbox(
                      value: wasCompleted,
                      onChanged: null, // Disable checkbox in history view
                    ),
                    title: Text(
                      subtaskName,
                      style: TextStyle(
                        // Optional: Grey out text if not completed?
                        color: wasCompleted ? Colors.black : Colors.grey,
                      ),
                    ),
                    dense: true,
                  );
                }).toList(),
              ),
            // --- End NEW ---

            const SizedBox(height: 16),

            Text('Notes:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(notes.isNotEmpty
                ? notes
                : '(No notes added)'), // Display the notes
          ],
        ),
      ),
    );
  }
}
