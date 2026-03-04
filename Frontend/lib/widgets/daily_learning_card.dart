import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class DailyLearningCard extends StatefulWidget {
  final VoidCallback? onXpGained;

  const DailyLearningCard({super.key, this.onXpGained});

  @override
  State<DailyLearningCard> createState() => _DailyLearningCardState();
}

class _DailyLearningCardState extends State<DailyLearningCard> {
  final ApiService _apiService = ApiService();

  bool _isReading = false;
  bool _isCompleted = false;
  bool _isClaiming = false;
  // true once we've confirmed via SharedPreferences that it was done today
  bool _doneTodayChecked = false;
  bool _doneToday = false;

  double _progress = 0.0;
  int _secondsLeft = 30;
  Timer? _timer;

  // Key used to store the completion date
  static const String _prefKey = 'learning_card_completed_date';

  final List<Map<String, dynamic>> _learningTopics = [
    {
      'title': 'The 2-Minute Rule',
      'category': 'Productivity',
      'icon': '⏱️',
      'themeColor': const Color(0xFF42A5F5),
      'content':
          'If a new habit takes less than two minutes to do, do it right now. Stop planning. Building the identity of someone who "shows up" is more important than the intensity of the workout. 2 minutes a day builds the neural pathways of consistency.',
    },
    {
      'title': 'Dopamine Detox',
      'category': 'Habit Science',
      'icon': '🧠',
      'themeColor': const Color(0xFFAB47BC),
      'content':
          'Dopamine is not about pleasure, it is about anticipation. When you constantly scroll short-form videos, you fry your baseline dopamine receptors, making hard work feel impossible. Fasting from cheap dopamine makes doing your actual habits feel incredibly rewarding again.',
    },
    {
      'title': 'Implementation Intentions',
      'category': 'Psychology',
      'icon': '📍',
      'themeColor': const Color(0xFFEF5350),
      'content':
          'People who explicitly state WHEN and WHERE they will perform a new habit are 2x more likely to actually do it. Stop saying "I will workout more." Start saying "I will workout at 6:00 AM in my living room." Specificity breeds execution.',
    },
    {
      'title': 'The Pomodoro Technique',
      'category': 'Focus',
      'icon': '🍅',
      'themeColor': const Color(0xFFFFA726),
      'content':
          'The human brain cannot sustain deep focus for hours on end without fatigue. Set a timer for 25 minutes of unbroken focus, followed by a strict 5-minute break. This prevents burnout and keeps your cognitive load sharp throughout the entire workday.',
    },
    {
      'title': 'Habit Stacking',
      'category': 'Habit Science',
      'icon': '🥞',
      'themeColor': const Color(0xFF26A69A),
      'content':
          'The best way to build a new habit is to map it onto an existing one. "After I pour my morning coffee [Current Habit], I will meditate for one minute [New Habit]." The existing habit acts as a powerful neurological trigger.',
    },
  ];

  late Map<String, dynamic> _todaysTopic;

  @override
  void initState() {
    super.initState();
    final int dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    _todaysTopic = _learningTopics[dayOfYear % _learningTopics.length];
    _checkDoneToday();
  }

  // Returns a user-scoped pref key so each account has its own daily gate
  Future<String> _prefKeyForUser() async {
    final token = await _apiService.getToken();
    String userId = 'guest';
    if (token != null) {
      try {
        // JWT is header.payload.signature — payload is base64url encoded
        final parts = token.split('.');
        if (parts.length == 3) {
          final payloadStr = parts[1];
          // Base64url → base64 padding
          final normalized = base64Url.normalize(payloadStr);
          final payloadJson = utf8.decode(base64Url.decode(normalized));
          final payload = json.decode(payloadJson) as Map<String, dynamic>;
          userId = (payload['userId'] ?? payload['sub'] ?? 'guest').toString();
        }
      } catch (_) {
        // Fallback — 'guest' key used if token parsing fails
      }
    }
    return 'learning_card_completed_date_$userId';
  }

  Future<void> _checkDoneToday() async {
    final prefKey = await _prefKeyForUser();
    final prefs = await SharedPreferences.getInstance();
    final String? storedDate = prefs.getString(prefKey);
    final String todayDate = _todayDateString();
    if (mounted) {
      setState(() {
        _doneToday = storedDate == todayDate;
        _doneTodayChecked = true;
      });
    }
  }

  Future<void> _markDoneToday() async {
    final prefKey = await _prefKeyForUser();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, _todayDateString());
  }

  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
    setState(() => _isClaiming = true);

    try {
      await _apiService.awardXP(10, category: 'learning');
      await _markDoneToday();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 +10 XP! You learned something new today!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onXpGained?.call();

        // Wait a moment, then dismiss the card entirely
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _doneToday = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to award learning XP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to award XP, but great job reading!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  Widget _buildCountdownTimer(Color themeColor, bool isDark) {
    // Large central ring countdown
    final double ringFraction = 1.0 - _progress;
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: ringFraction,
                strokeWidth: 6,
                backgroundColor:
                    isDark ? Colors.grey[800]! : Colors.grey[200]!,
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
              Center(
                child: Text(
                  '$_secondsLeft',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'seconds left',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildReadingOverlay(Color themeColor, bool isDark) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Theme.of(context).cardColor, themeColor.withValues(alpha: 0.15)]
                : [Theme.of(context).cardColor, themeColor.withValues(alpha: 0.05)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: themeColor.withValues(alpha: isDark ? 0.3 : 0.1),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header row
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
                      child: Text(_todaysTopic['icon'] as String,
                          style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _todaysTopic['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  onPressed: _isCompleted ? null : _cancelReading,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  _todaysTopic['content'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.7,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Bottom — Countdown or completion badge
            _isCompleted
                ? (_isClaiming
                    ? const CircularProgressIndicator()
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
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
                            const Icon(Icons.stars_rounded,
                                color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Lesson Complete! +10 XP',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(curve: Curves.easeOutBack))
                : _buildCountdownTimer(themeColor, isDark),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't render anything until we've checked prefs, and hide once done
    if (!_doneTodayChecked || _doneToday) return const SizedBox.shrink();

    final themeColor = _todaysTopic['themeColor'] as Color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        height: _isReading ? 420 : 76,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Idle compact card
            if (!_isReading)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _startReading,
                  borderRadius: BorderRadius.circular(24),
                    child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        // Left icon — smaller
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                themeColor.withValues(alpha: isDark ? 0.3 : 0.2),
                                themeColor.withValues(alpha: isDark ? 0.1 : 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themeColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(_todaysTopic['icon'] as String,
                              style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.bolt_rounded,
                                      size: 13, color: themeColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Brain Fuel  •  +10 XP",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                               Text(
                                _todaysTopic['title'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Arrow button
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_forward_ios_rounded,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              size: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Reading overlay
            if (_isReading)
              _buildReadingOverlay(themeColor, isDark)
                  .animate()
                  .fade(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
