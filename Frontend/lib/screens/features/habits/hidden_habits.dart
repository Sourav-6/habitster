// lib/screens/features/habits/hidden_habits_screen.dart
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class HiddenHabitsScreen extends StatefulWidget {
  const HiddenHabitsScreen({super.key});

  @override
  State<HiddenHabitsScreen> createState() => _HiddenHabitsScreenState();
}

class _HiddenHabitsScreenState extends State<HiddenHabitsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _hiddenHabits = [];
  bool _isLoading = true;
  String? _error;
  
// Loading state for saving note
  // --- End NEW ---

  @override
  void initState() {
    super.initState();
    _fetchHiddenHabits();
  }



  Future<void> _fetchHiddenHabits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final habits = await _apiService.getHiddenHabits();
      if (mounted) {
        setState(() {
          _hiddenHabits = habits;
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

  // --- NEW: Function to unhide a habit ---
  Future<void> _unhideHabit(String habitId) async {
    try {
      await _apiService.showHabit(habitId);
      if (mounted) {
        setState(() {
          _hiddenHabits
              .removeWhere((h) => h['\$id'] == habitId); // Remove locally
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habit restored to main list.')),
        );
        if (mounted) {
          Navigator.pop(context, true); // Return true to signal a change
        }
        // --- END ADD ---
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error unhiding habit: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
  // --- End NEW ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hidden Habits')),
      body: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_hiddenHabits.isEmpty) {
      return const Center(child: Text('No habits are currently hidden.'));
    }

    return ListView.builder(
      itemCount: _hiddenHabits.length,
      itemBuilder: (context, index) {
        final habit = _hiddenHabits[index];
        return ListTile(
          title: Text(habit['habitName'] ?? 'No Name'),
          subtitle: Text('Streak: ${habit['currentStreak'] ?? 0}'),
          trailing: IconButton(
            // Add Unhide button
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Unhide Habit',
            onPressed: () => _unhideHabit(habit['\$id']),
          ),
        );
      },
    );
  }
}
