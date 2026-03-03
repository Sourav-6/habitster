import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../widgets/habitster_loading_widget.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _selectedPriority = 0; // 0: None, 1: Low, 2: Medium, 3: High
  String _selectedLabel = ''; // Store the selected label
  bool _isRecurring = false;
  final TextEditingController _recurrenceDaysController =
      TextEditingController();
  // --- End NEW ---

  final List<Color> _priorityColors = [
    Colors.grey.shade400, // None
    const Color(0xFFFFB3B3), // Low - Light variant
    const Color(0xFFFF8080), // Medium - Medium variant
    const Color(0xFFFF4747), // High - Main color
  ];

  final FocusNode _taskNameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // No need to use Future.delayed as we'll use autofocus property instead
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _noteController.dispose();
    _taskNameFocusNode.dispose();
    _recurrenceDaysController.dispose();
    super.dispose();
  }

  // Define a constant for our primary color
  static const Color primaryColor = Color(0xFFFF4747); // Updated to #FF4747

  @override
  Widget build(BuildContext context) {
    // Request focus to show keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_taskNameFocusNode);
      }
    });

    // Make sure we're positioned correctly above the keyboard

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withAlpha(240), // Use theme card color
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 15,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 12.0,
              right: 12.0,
              top: 8.0,
              bottom: 8.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task name input with send button
                _buildTaskNameField(),
                const SizedBox(height: 8),

                // Note input that grows as you type
                _buildNoteField(),
                const SizedBox(height: 8),

                // Action buttons row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildActionButton(
                        icon: Icons.calendar_today_rounded,
                        label: _isToday(_selectedDate)
                            ? 'Today'
                            : DateFormat('MMM d').format(_selectedDate),
                        onTap: _selectDate,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.flag_rounded,
                        label: _getPriorityText(),
                        color: _priorityColors[_selectedPriority],
                        onTap: _selectPriority,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.label_rounded,
                        label:
                            _selectedLabel.isEmpty ? 'Label' : _selectedLabel,
                        onTap: _showLabelOptions,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Repeat Task'),
                  value: _isRecurring,
                  onChanged: (bool value) {
                    setState(() {
                      _isRecurring = value;
                    });
                  },
                  activeThumbColor: primaryColor, // Use your primary color
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),

                // Only show the days input if recurring is enabled
                if (_isRecurring) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: TextField(
                      controller: _recurrenceDaysController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Repeat every (days)',
                        hintText: 'e.g., 7',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8), // Add some spacing at the bottom
                // --- End NEW Recurrence Section ---
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 opacity = 13 alpha
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _taskNameController,
              autofocus: true,
              focusNode: _taskNameFocusNode,
              decoration: InputDecoration(
                hintText: 'Task name (required)',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                ),
                prefixIcon: const Icon(
                  Icons.task_alt_rounded,
                  color: primaryColor,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              onSubmitted: (_) => _createTask(),
            ),
          ),
          // Send button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: _createTask,
              child: Container(
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.send_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 opacity = 13 alpha
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: _noteController,
        maxLines: null, // Allow unlimited lines
        minLines: 1, // Start with 1 line
        decoration: InputDecoration(
          hintText: 'Add note',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
          ),
          prefixIcon: const Icon(
            Icons.note_rounded,
            color: primaryColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13), // 0.05 opacity = 13 alpha
              blurRadius: 5,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: color ?? primaryColor,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getPriorityText() {
    switch (_selectedPriority) {
      case 0:
        return 'None';
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'None';
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _selectPriority() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 15,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Priority',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(
                  _priorityColors.length,
                  (index) => ListTile(
                    leading: Icon(
                      Icons.flag_rounded,
                      color: _priorityColors[index],
                    ),
                    title: Text(_getPriorityTextByIndex(index)),
                    onTap: () {
                      setState(() {
                        _selectedPriority = index;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPriorityTextByIndex(int index) {
    switch (index) {
      case 0:
        return 'None';
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'None';
    }
  }

  void _showLabelOptions() {
    // Default labels like Todoist
    final List<String> defaultLabels = [
      'Personal',
      'Work',
      'Health',
      'Shopping',
      'Family',
      'Education',
    ];

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 15,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Label',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withAlpha(220),
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(
                  defaultLabels.length,
                  (index) => ListTile(
                    leading: const Icon(
                      Icons.label_rounded,
                      color: primaryColor,
                    ),
                    title: Text(defaultLabels[index]),
                    onTap: () {
                      setState(() {
                        _selectedLabel = defaultLabels[index];
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // lib/screens/features/tasks/create_task.dart

  void _createTask() async {
    // <-- Make the function async
    if (_taskNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task name'),
          backgroundColor: primaryColor, // Use your defined primary color
        ),
      );
      return;
    }

    int? recurrenceDays;
    if (_isRecurring) {
      if (_recurrenceDaysController.text.isEmpty ||
          int.tryParse(_recurrenceDaysController.text) == null ||
          int.parse(_recurrenceDaysController.text) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter a valid number of days to repeat'),
              backgroundColor: Colors.orange),
        );
        return;
      }
      recurrenceDays = int.parse(_recurrenceDaysController.text);
    }

    // 1. Prepare the task data map
    final Map<String, dynamic> taskData = {
      'taskName': _taskNameController.text,
      'note': _noteController.text.isNotEmpty ? _noteController.text : null,
      'dueDate': _selectedDate.toIso8601String(), // Send in ISO 8601 format
      'priority': _selectedPriority,
      'label': _selectedLabel.isNotEmpty ? _selectedLabel : null,
      'isRecurring': _isRecurring,
      'recurrenceDays': _isRecurring ? recurrenceDays : null,
      // 'isRecurring': false, // Add logic for recurring tasks later
      // 'recurrenceDays': null, // Add logic for recurring tasks later
    };

    // --- NEW: Validate recurrence days if needed ---

    // Show a loading indicator (optional, but good UX)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: HabitsterLoadingWidget(fontSize: 24)),
    );

    try {
      // 2. Call the API service
      final newTask = await _apiService.createTask(taskData);

      // 3. Close loading indicator and the create task dialog
      if (mounted) {
        Navigator.pop(context); // Close loading indicator
        Navigator.pop(context, newTask); // Close dialog and return the new task
      }
    } catch (e) {
      // 4. Handle errors
      if (mounted) {
        Navigator.pop(context); // Close loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
