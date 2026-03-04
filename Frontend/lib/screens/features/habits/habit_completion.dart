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
      appBar: AppBar(
        title: Text(
          'Details for $formattedDate',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          // Use ListView for potentially long notes/subtask lists
          children: [
            Text('Completion Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            Text('Subtasks Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (widget.allSubtasks.isEmpty)
              Text('  - (No subtasks defined for this habit)', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)))
            else
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: widget.allSubtasks.map((subtask) {
                    final subtaskId = subtask['\$id'] as String;
                    final subtaskName = subtask['subtaskName'] ?? 'Unnamed Subtask';
                    // Check if this subtask's ID is in the completed set
                    final bool wasCompleted = completedIds.contains(subtaskId);

                    return ListTile(
                      leading: Checkbox(
                        value: wasCompleted,
                        onChanged: null, // Disable checkbox in history view
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.disabled)) {
                            return wasCompleted ? Theme.of(context).primaryColor : Colors.transparent;
                          }
                          return null;
                        }),
                      ),
                      title: Text(
                        subtaskName,
                        style: TextStyle(
                          color: wasCompleted 
                              ? Theme.of(context).textTheme.bodyLarge?.color 
                              : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.4),
                          decoration: wasCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
            
            const SizedBox(height: 32),

            Text('Notes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              ),
              child: Text(
                notes.isNotEmpty ? notes : '(No notes added)',
                style: TextStyle(
                  color: notes.isNotEmpty 
                      ? Theme.of(context).textTheme.bodyLarge?.color 
                      : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  fontStyle: notes.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ), 
          ],
        ),
      ),
    );
  }
}
