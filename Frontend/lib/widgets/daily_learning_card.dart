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

  Widget _buildReadingOverlay(Color themeColor, bool isDark) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          // Smooth gradient background when expanded for reading
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [
                  Theme.of(context).cardColor,
                  themeColor.withValues(alpha: 0.15)
                ]
              : [
                  Theme.of(context).cardColor,
                  themeColor.withValues(alpha: 0.05)
                ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: themeColor.withValues(alpha: isDark ? 0.3 : 0.1),
            width: 1.5,
          )
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(_todaysTopic['icon']!, style: const TextStyle(fontSize: 20)),
                    ),
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
                  icon: Icon(Icons.close_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
                    fontSize: 15,
                    height: 1.7,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)], // Success green
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Lesson Complete! +10 XP',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(curve: Curves.easeOutBack) 
              )
            : Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        height: 10,
                        width: MediaQuery.of(context).size.width * 0.75 * _progress, // Approx width matching card
                        decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Read for \$_secondsLeft seconds to earn XP...',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
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
    final themeColor = Color(int.parse(_todaysTopic['themeColor']!.replaceFirst('0x', ''), radix: 16));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RepaintBoundary( 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutBack,
        margin: const EdgeInsets.only(bottom: 24),
        height: _isReading ? 400 : 130, // Taller for more reading space
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
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
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                themeColor.withValues(alpha: isDark ? 0.3 : 0.2),
                                themeColor.withValues(alpha: isDark ? 0.1 : 0.05),
                              ]
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: themeColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
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
                                  Icon(Icons.auto_awesome_rounded, size: 16, color: themeColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Daily Learning  •  +10 XP',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
            // Reading State (Expanded Card)
            if (_isReading)
              _buildReadingOverlay(themeColor, isDark).animate().fade(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
