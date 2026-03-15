// lib/screens/features/habits/create_habit_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/api_service.dart'; // Import ApiService
import 'dart:convert';

// Local Theme Colors helper
class AppColors {
  static Color getBackgroundColor(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static const primaryColor = Color(0xFFFF0066);
  static Color getCardColor(BuildContext context) => Theme.of(context).cardColor;
  static Color getTextColor(BuildContext context) => Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
}

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
  final TextEditingController _durationValueController = TextEditingController();
  final TextEditingController _frequencyValueController = TextEditingController();
  final List<TextEditingController> _subtaskControllers = [];

  // State variables
  DateTime _startDate = DateTime.now();
  String _selectedDurationUnit = 'days'; // Default
  String _selectedFrequencyType = 'daily'; // Default
  
  // Gamification properties
  String _selectedDifficulty = 'Medium';
  String _selectedCategory = 'Productivity';

  final List<String> _weekDaysStr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _difficulties = ['Small', 'Medium', 'Hard'];
  final List<String> _categories = ['Productivity', 'Health', 'Mindfulness', 'Learning'];
  final List<String> _durations = ['days', 'weeks', 'months'];

  @override
  void dispose() {
    _habitNameController.dispose();
    _durationValueController.dispose();
    _frequencyValueController.dispose();
    for (var controller in _subtaskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020), 
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryColor,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _createHabit() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    String? frequencyValueToSend;
    if (_selectedFrequencyType == 'every_x_days') {
      frequencyValueToSend = _frequencyValueController.text;
    } else if (_selectedFrequencyType == 'specific_days') {
      if (!_selectedWeekdays.contains(true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select at least one day.'),
              backgroundColor: Colors.orange),
        );
        return; 
      }
      List<int> selectedDays = [];
      for (int i = 0; i < _selectedWeekdays.length; i++) {
        if (_selectedWeekdays[i]) selectedDays.add(i + 1);
      }
      frequencyValueToSend = json.encode(selectedDays); 
    }

    setState(() {
      _isLoading = true;
    });

    final Map<String, dynamic> habitData = {
      'habitName': _habitNameController.text.trim(),
      'startDate': _startDate.toIso8601String(),
      'durationValue': int.tryParse(_durationValueController.text) ?? 1,
      'durationUnit': _selectedDurationUnit,
      'frequencyType': _selectedFrequencyType,
      'frequencyValue': frequencyValueToSend,
      'difficulty': _selectedDifficulty,
      'category': _selectedCategory,
    };

    try {
      final newHabit = await _apiService.createHabit(habitData);
      
      // Create valid subtasks if any
      final habitId = newHabit['\$id'];
      if (habitId != null) {
        for (var controller in _subtaskControllers) {
          final subtaskName = controller.text.trim();
          if (subtaskName.isNotEmpty) {
            await _apiService.createSubtask({
              'habitId': habitId,
              'subtaskName': subtaskName,
              'isRequired': true, // Defaulting to true for basic subtasks
            });
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Habit "${newHabit['habitName']}" created!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to create habit: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
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

  InputDecoration _customInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.primaryColor.withAlpha(200)),
      filled: true,
      fillColor: AppColors.getCardColor(context).withAlpha(150),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 24),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.getTextColor(context),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.getCardColor(context).withAlpha(150),
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withAlpha(100),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.withAlpha(50),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.getTextColor(context).withAlpha(180),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'New Habit',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getTextColor(context)),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Beautiful Background Gradient blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withAlpha(30),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4A00E0).withAlpha(20),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Input
                    TextFormField(
                      controller: _habitNameController,
                      style: GoogleFonts.poppins(fontSize: 16),
                      decoration: _customInputDecoration('What do you want to build?', Icons.auto_awesome_rounded),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a name' : null,
                    ).animate().fade(duration: 400.ms).slideY(begin: 0.1),

                    _buildSectionTitle('Schedule').animate().fade(delay: 100.ms).slideY(begin: 0.1),

                    // Start Date Card
                    GestureDetector(
                      onTap: () => _selectStartDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.getCardColor(context).withAlpha(150),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryColor),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date',
                                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                                ),
                                Text(
                                  DateFormat('MMMM dd, yyyy').format(_startDate),
                                  style: GoogleFonts.poppins(
                                      fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextColor(context)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade(delay: 150.ms).slideY(begin: 0.1),

                    const SizedBox(height: 16),

                    // Frequency Selection
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildChoiceChip('Daily', _selectedFrequencyType == 'daily', () => setState(() => _selectedFrequencyType = 'daily')),
                        _buildChoiceChip('Specific Days', _selectedFrequencyType == 'specific_days', () => setState(() => _selectedFrequencyType = 'specific_days')),
                        _buildChoiceChip('Interval', _selectedFrequencyType == 'every_x_days', () => setState(() => _selectedFrequencyType = 'every_x_days')),
                      ],
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

                    // Conditional Frequency Inputs
                    if (_selectedFrequencyType == 'every_x_days') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _frequencyValueController,
                        style: GoogleFonts.poppins(fontSize: 16),
                        decoration: _customInputDecoration('Repeat every X days', Icons.repeat_rounded),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || int.tryParse(v) == null || int.parse(v) <= 0) ? 'Enter valid days' : null,
                      ).animate().fade(),
                    ],

                    if (_selectedFrequencyType == 'specific_days') ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          final isSelected = _selectedWeekdays[index];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedWeekdays[index] = !isSelected),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryColor : AppColors.getCardColor(context).withAlpha(150),
                                shape: BoxShape.circle,
                                boxShadow: isSelected ? [BoxShadow(color: AppColors.primaryColor.withAlpha(100), blurRadius: 8)] : [],
                              ),
                              child: Center(
                                child: Text(
                                  _weekDaysStr[index][0],
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.getTextColor(context).withAlpha(150),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ).animate().fade().scale(),
                    ],

                    _buildSectionTitle('Duration').animate().fade(delay: 280.ms).slideY(begin: 0.1),

                    // Duration row: number input + days/weeks/months chips
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Number input
                        SizedBox(
                          width: 110,
                          child: TextFormField(
                            controller: _durationValueController,
                            style: GoogleFonts.poppins(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: '30',
                              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14),
                              prefixIcon: const Icon(Icons.timer_outlined, color: AppColors.primaryColor),
                              filled: true,
                              fillColor: AppColors.getCardColor(context).withAlpha(150),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final n = int.tryParse(v.trim());
                              if (n == null || n <= 0) return 'Enter a valid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Unit chips
                        Expanded(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _durations.map((unit) =>
                              _buildChoiceChip(
                                unit[0].toUpperCase() + unit.substring(1),
                                _selectedDurationUnit == unit,
                                () => setState(() => _selectedDurationUnit = unit),
                              ),
                            ).toList(),
                          ),
                        ),
                      ],
                    ).animate().fade(delay: 290.ms).slideY(begin: 0.1),

                    const SizedBox(height: 8),

                    _buildSectionTitle('Gamification').animate().fade(delay: 300.ms).slideY(begin: 0.1),


                    Text('Category', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildChoiceChip(cat, _selectedCategory == cat, () => setState(() => _selectedCategory = cat)),
                        )).toList(),
                      ),
                    ).animate().fade(delay: 350.ms).slideY(begin: 0.1),

                    const SizedBox(height: 16),

                    Text('Difficulty (XP Multiplier)', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: _difficulties.map((diff) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _buildChoiceChip(diff, _selectedDifficulty == diff, () => setState(() => _selectedDifficulty = diff)),
                      )).toList(),
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.1),

                    _buildSectionTitle('Subtasks').animate().fade(delay: 450.ms).slideY(begin: 0.1),
                    
                    // Render dynamic subtask text fields
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _subtaskControllers.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _subtaskControllers[index],
                                  style: GoogleFonts.poppins(fontSize: 14),
                                  decoration: _customInputDecoration('Subtask name', Icons.check_circle_outline)
                                    .copyWith(contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _subtaskControllers[index].dispose();
                                    _subtaskControllers.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ).animate().fade().slideX(begin: 0.05),
                        );
                      },
                    ),
                    
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _subtaskControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add, color: AppColors.primaryColor),
                      label: Text('Add Subtask', style: GoogleFonts.poppins(color: AppColors.primaryColor, fontWeight: FontWeight.bold)),
                    ).animate().fade(delay: 480.ms),

                    const SizedBox(height: 48),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createHabit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: AppColors.primaryColor.withAlpha(150),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Create Habit',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ).animate().fade(delay: 500.ms).slideY(begin: 0.2),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
