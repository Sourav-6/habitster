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
          // Top aesthetic header area
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Stack(
              children: [
                Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFE8EAF6),
                        Color(0xFFFFF3E0),
                      ],
                    ),
                  ),
                ),
                // Decorative elements imitating sticker art
                Positioned(
                  top: 20,
                  left: 20,
                  child: const Text('✨', style: TextStyle(fontSize: 32)),
                ),
                Positioned(
                  top: 10,
                  right: 80,
                  child: const Text('💖', style: TextStyle(fontSize: 36)),
                ),
                Positioned(
                  bottom: 10,
                  left: 60,
                  child: const Text('🌈', style: TextStyle(fontSize: 40)),
                ),
                Positioned(
                  bottom: 20,
                  right: 40,
                  child: const Text('🌟', style: TextStyle(fontSize: 32)),
                ),
                // Soft white rounded cutout overlap at the bottom of the header
                Positioned(
                  bottom: -15,
                  left: -20,
                  right: -20,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wb_sunny_outlined, size: 16, color: Color(0xFF7E57C2)),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Journal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7E57C2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'How are you feeling today?',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Mood Pills
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: _moods.entries.map((entry) {
                    final mood = entry.key;
                    final data = entry.value;
                    final isSelected = _selectedMood == mood;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _handleMoodSelect(mood),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? data['color'] : Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (data['color'] as Color).withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Circular icon background
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withOpacity(0.5) : data['color'],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(data['icon'], style: const TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  mood,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
