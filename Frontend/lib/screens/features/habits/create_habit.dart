// lib/screens/features/habits/create_habit_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../../services/api_service.dart'; // Import ApiService
import 'dart:convert';

class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  final List<bool> _selectedWeekdays = List.filled(7, false);

  // Form Controllers
  final TextEditingController _habitNameController = TextEditingController();
  final TextEditingController _durationValueController =
      TextEditingController();
  final TextEditingController _frequencyValueController =
      TextEditingController();

  // State variables
  DateTime _startDate = DateTime.now();
  String _selectedDurationUnit = 'days'; // Default
  String _selectedFrequencyType = 'daily'; // Default

  @override
  void dispose() {
    _habitNameController.dispose();
    _durationValueController.dispose();
    _frequencyValueController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020), // Allow past dates? Or just DateTime.now()?
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _createHabit() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't submit if form is invalid
    }

    String? frequencyValueToSend;
    if (_selectedFrequencyType == 'every_x_days') {
      frequencyValueToSend = _frequencyValueController.text;
    } else if (_selectedFrequencyType == 'specific_days') {
      // Validate at least one day is selected
      if (!_selectedWeekdays.contains(true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please select at least one day for specific day frequency.'),
              backgroundColor: Colors.orange),
        );
        return; // Stop submission
      }
      // Convert selected days (true indices) to list of weekday numbers (1-7)
      List<int> selectedDays = [];
      for (int i = 0; i < _selectedWeekdays.length; i++) {
        if (_selectedWeekdays[i]) {
          selectedDays.add(i + 1); // DateTime uses 1 for Monday, 7 for Sunday
        }
      }
      // Convert list to JSON string for storage
      frequencyValueToSend =
          json.encode(selectedDays); // Need import 'dart:convert';
    }

    setState(() {
      _isLoading = true;
    });

    // Prepare data for API
    final Map<String, dynamic> habitData = {
      'habitName': _habitNameController.text,
      'startDate': _startDate.toIso8601String(),
      'durationValue': int.tryParse(_durationValueController.text) ?? 0,
      'durationUnit': _selectedDurationUnit,
      'frequencyType': _selectedFrequencyType,
      // Only include frequencyValue if relevant type is selected
      'frequencyValue': frequencyValueToSend,
    };

    try {
      final newHabit = await _apiService.createHabit(habitData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Habit "${newHabit['habitName']}" created!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Pop screen and indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to create habit: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Habit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _habitNameController,
                decoration: const InputDecoration(labelText: 'Habit Name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 16),

              // Start Date Picker
              Row(
                children: [
                  Expanded(
                    child: Text(
                        'Start Date: ${DateFormat('yyyy-MM-dd').format(_startDate)}'),
                  ),
                  TextButton(
                    onPressed: () => _selectStartDate(context),
                    child: const Text('Select Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Duration
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _durationValueController,
                      decoration: const InputDecoration(labelText: 'Duration'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Enter valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedDurationUnit,
                      items: ['days', 'weeks', 'months']
                          .map((unit) =>
                              DropdownMenuItem(value: unit, child: Text(unit)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedDurationUnit = value!),
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Frequency Type
              DropdownButtonFormField<String>(
                initialValue: _selectedFrequencyType,
                items: [
                  'daily',
                  'every_x_days',
                  'specific_days'
                ] // Add more later?
                    .map((type) => DropdownMenuItem(
                        value: type, child: Text(type.replaceAll('_', ' '))))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedFrequencyType = value!),
                decoration: const InputDecoration(labelText: 'Frequency'),
              ),
              const SizedBox(height: 16),

              // Frequency Value (Conditional)
              if (_selectedFrequencyType == 'every_x_days')
                TextFormField(
                  controller: _frequencyValueController,
                  decoration:
                      const InputDecoration(labelText: 'Repeat every (days)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        int.tryParse(value) == null ||
                        int.parse(value) <= 0) {
                      return 'Enter valid days';
                    }
                    return null;
                  },
                ),

              if (_selectedFrequencyType == 'specific_days')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Repeat on:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    ToggleButtons(
                      isSelected: _selectedWeekdays,
                      onPressed: (int index) {
                        setState(() {
                          _selectedWeekdays[index] = !_selectedWeekdays[index];
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      // Add styling as needed (selectedColor, fillColor, etc.)
                      children: const [
                        // Monday to Sunday
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('Mon')),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('Tue')),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('Wed')),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('Thu')),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('Fri')),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('Sat')),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('Sun')),
                      ],
                    ),
                    // Add validation feedback if no day is selected
                    if (!_selectedWeekdays.contains(true))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Please select at least one day.',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12),
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createHabit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Habit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
