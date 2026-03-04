import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';

class DailyLearningCard extends StatefulWidget {
  final VoidCallback? onXpGained;

  const DailyLearningCard({super.key, this.onXpGained});

  @override
  State<DailyLearningCard> createState() => _DailyLearningCardState();
}

class _DailyLearningCardState extends State<DailyLearningCard> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  
  bool _isReading = false;
  bool _isCompleted = false;
  bool _isClaiming = false;
  
  double _progress = 0.0;
  int _secondsLeft = 30;
  Timer? _timer;
  
  // A curated list of habit & productivity science snippets.
  final List<Map<String, String>> _learningTopics = [
    {
      'title': 'The 2-Minute Rule',
      'category': 'Productivity',
      'icon': '⏱️',
      'themeColor': '0xFF42A5F5',
      'content': 'If a new habit takes less than two minutes to do, do it right now. Stop planning. Building the identity of someone who "shows up" is more important than the intensity of the workout. 2 minutes a day builds the neural pathways of consistency.',
    },
    {
      'title': 'Dopamine Detox',
      'category': 'Habit Science',
      'icon': '🧠',
      'themeColor': '0xFFAB47BC',
      'content': 'Dopamine is not about pleasure, it is about anticipation. When you constantly scroll short-form videos, you fry your baseline dopamine receptors, making hard work feel impossible. Fasting from cheap dopamine makes doing your actual habits feel incredibly rewarding again.',
    },
    {
      'title': 'Implementation Intentions',
      'category': 'Psychology',
      'icon': '📍',
      'themeColor': '0xFFEF5350',
      'content': 'People who explicitly state WHEN and WHERE they will perform a new habit are 2x more likely to actually do it. Stop saying "I will workout more." Start saying "I will workout at 6:00 AM in my living room." Specificity breeds execution.',
    },
    {
      'title': 'The Pomodoro Technique',
      'category': 'Focus',
      'icon': '🍅',
      'themeColor': '0xFFFFA726',
      'content': 'The human brain cannot sustain deep focus for hours on end without fatigue. Set a timer for 25 minutes of unbroken focus, followed by a strict 5-minute break. This prevents burnout and keeps your cognitive load sharp throughout the entire workday.',
    },
    {
      'title': 'Habit Stacking',
      'category': 'Habit Science',
      'icon': '🥞',
      'themeColor': '0xFF26A69A',
      'content': 'The best way to build a new habit is to map it onto an existing one. "After I pour my morning coffee [Current Habit], I will meditate for one minute [New Habit]." The existing habit acts as a powerful neurological trigger.',
    }
  ];

  late Map<String, String> _todaysTopic;

  @override
  void initState() {
    super.initState();
    // Pick a topic deterministically based on today's day of the year so it changes daily
    final int dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    _todaysTopic = _learningTopics[dayOfYear % _learningTopics.length];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startReading() {
    setState(() {
      _isReading = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
          _progress = (30 - _secondsLeft) / 30.0;
        } else {
          _isCompleted = true;
          timer.cancel();
          _claimXP();
        }
      });
    });
  }

  void _cancelReading() {
    _timer?.cancel();
    setState(() {
      _isReading = false;
      _secondsLeft = 30;
      _progress = 0.0;
    });
  }

  Future<void> _claimXP() async {
    setState(() {
      _isClaiming = true;
    });

    try {
      await _apiService.awardXP(10, category: 'learning');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 +10 XP! You learned something new today!'),
            backgroundColor: Colors.green,
          ),
        );
        // Ping parent to refresh profile
        widget.onXpGained?.call();
      }
    } catch (e) {
      debugPrint('Failed to award learning XP: \$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to award XP, but great job reading!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
  }

  Widget _buildReadingOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(_todaysTopic['icon']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      _todaysTopic['title']!,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: _isCompleted ? null : _cancelReading,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  _todaysTopic['content']!,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    height: 1.6,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Timer / Reward UI
            _isCompleted ? 
              ( _isClaiming 
                ? const CircularProgressIndicator()
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Lesson Complete! +10 XP',
                          style: GoogleFonts.poppins(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(curve: Curves.easeOutBack) 
              )
            : Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(int.parse(_todaysTopic['themeColor']!))
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Read for \$_secondsLeft seconds to earn XP...',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(int.parse(_todaysTopic['themeColor']!));
    
    return RepaintBoundary( // Avoid rebuilding the whole dashboard during timer tick
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        height: _isReading ? 350 : 120, // Expands when reading
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Idle State (Small Card)
            if (!_isReading)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _startReading,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        // Left Icon Block
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_todaysTopic['icon']!, style: const TextStyle(fontSize: 32)),
                        ),
                        const SizedBox(width: 20),
                        // Text Block
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.school, size: 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Daily Learning  •  +10 XP',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _todaysTopic['title']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right Arrow
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              
            // Reading State (Expanded Card)
            if (_isReading)
              _buildReadingOverlay().animate().fade(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
