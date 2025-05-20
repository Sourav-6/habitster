import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _selectedPriority = 0; // 0: None, 1: Low, 2: Medium, 3: High
  String _selectedLabel = ''; // Store the selected label

  final List<Color> _priorityColors = [
    Colors.grey.shade400, // None
    const Color(0xFFD97BA9), // Low - Light variant
    const Color(0xFFC84F8C), // Medium - Medium variant
    const Color(0xFFB41D6C), // High - Main color
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
    super.dispose();
  }

  // Define a constant for our primary color
  static const Color primaryColor = Color(0xFFB41D6C); // Original color #B41D6C

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
            color: Colors.white.withAlpha(230), // More opaque white
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
                        label: _isToday(_selectedDate) ? 'Today' : DateFormat('MMM d').format(_selectedDate),
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
                        label: _selectedLabel.isEmpty ? 'Label' : _selectedLabel,
                        onTap: _showLabelOptions,
                      ),
                    ],
                  ),
                ),
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
        color: Colors.white,
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
        color: Colors.white,
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
          color: Colors.white.withAlpha(250),
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
                color: Colors.black.withAlpha(220), // Darker text for better readability
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
    return date.year == now.year && date.month == now.month && date.day == now.day;
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(250),
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
                    color: Colors.black.withAlpha(220),
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(250),
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

  void _createTask() {
    // Validate task name is not empty
    if (_taskNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task name'),
          backgroundColor: primaryColor,
        ),
      );
      return;
    }

    // In a real app, you would save the task data to a database or state management solution
    // Task Name: ${_taskNameController.text}
    // Note: ${_noteController.text}
    // Date: $_selectedDate
    // Priority: $_selectedPriority
    // Label: ${_selectedLabel.isEmpty ? 'None' : _selectedLabel}

    Navigator.pop(context);
  }
}