import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

class MoodTrackerCard extends StatefulWidget {
  final String? initialMood;
  final Function(String) onMoodSelected;

  const MoodTrackerCard({
    super.key,
    this.initialMood,
    required this.onMoodSelected,
  });

  @override
  State<MoodTrackerCard> createState() => _MoodTrackerCardState();
}

class _MoodTrackerCardState extends State<MoodTrackerCard> {
  String? _selectedMood;
  final ApiService _apiService = ApiService();
  bool _isSaving = false;

  final Map<String, Map<String, dynamic>> _moods = {
    'Great': {'icon': '😃', 'color': const Color(0xFFB2DFDB)},
    'Good': {'icon': '😊', 'color': const Color(0xFFC5CAE9)},
    'Okay': {'icon': '😐', 'color': const Color(0xFFE1BEE7)},
    'Not Great': {'icon': '😟', 'color': const Color(0xFFFFCCBC)},
    'Bad': {'icon': '😔', 'color': const Color(0xFFF8BBD0)},
  };

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood;
  }

  Future<void> _handleMoodSelect(String mood) async {
    if (_isSaving) return;
    setState(() {
      _selectedMood = mood;
      _isSaving = true;
    });

    widget.onMoodSelected(mood);

    try {
      await _apiService.saveDailyMood(mood);
    } catch (e) {
      debugPrint('Failed to save mood: \$e');
      // Revert if error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save mood. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7E57C2).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF7E57C2)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Journal',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            Text(
                              'How are you feeling today?',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Mood Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _moods.entries.map((entry) {
                      final mood = entry.key;
                      final data = entry.value;
                      final isSelected = _selectedMood == mood;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _handleMoodSelect(mood),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? data['color'] : Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: (data['color'] as Color).withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(data['icon'], style: const TextStyle(fontSize: 20)),
                                    if (isSelected) const SizedBox(width: 6),
                                    if (isSelected)
                                      Text(
                                        mood,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
