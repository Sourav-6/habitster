import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'create_task.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;
  bool _isButtonExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Glassmorphic background with blurred blobs
          _buildGlassmorphicBackground(),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Tasks',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withAlpha(204), // Using withAlpha instead of withOpacity
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildTasksList(),
                  ),
                ],
              ),
            ),
          ),

          // Floating action button - positioned higher to be above navbar
          Positioned(
            bottom: 130, // Raised higher above navbar
            right: 30,
            child: _buildAddButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicBackground() {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF9F9FF), // Very light purple/white
                Color(0xFFF0F8FF), // Very light blue
              ],
            ),
          ),
        ),

        // Animated blobs with more attractive design
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Stack(
              children: [
                // Pink gradient blob
                Positioned(
                  top: -100 + 50 * math.sin(_animationController.value * math.pi * 0.7),
                  right: -80 + 40 * math.cos(_animationController.value * math.pi * 0.5),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFFF0066).withAlpha(30), // Pink
                      const Color(0xFFFF9E80).withAlpha(20), // Light orange
                    ],
                    250 + 50 * math.sin(_animationController.value * math.pi * 0.6),
                  ),
                ),

                // Yellow-purple gradient blob
                Positioned(
                  bottom: MediaQuery.of(context).size.height / 4,
                  left: -120 + 60 * math.cos(_animationController.value * math.pi * 0.4),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFf8e356).withAlpha(25), // Yellow
                      const Color(0xFF6A11CB).withAlpha(15), // Purple
                    ],
                    280 + 60 * math.sin(_animationController.value * math.pi * 0.5),
                  ),
                ),

                // Blue-cyan gradient blob
                Positioned(
                  top: MediaQuery.of(context).size.height / 3,
                  right: MediaQuery.of(context).size.width / 3 - 50 + 70 * math.sin(_animationController.value * math.pi * 0.3),
                  child: _buildGradientBlob(
                    [
                      const Color(0xFF00CCFF).withAlpha(20), // Cyan
                      const Color(0xFF2979FF).withAlpha(15), // Blue
                    ],
                    200 + 40 * math.cos(_animationController.value * math.pi * 0.6),
                  ),
                ),

                // Small decorative blobs
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.6,
                  right: MediaQuery.of(context).size.width * 0.7,
                  child: _buildGradientBlob(
                    [
                      const Color(0xFFFF4081).withAlpha(25), // Pink
                      const Color(0xFFFF80AB).withAlpha(15), // Light pink
                    ],
                    100 + 20 * math.sin(_animationController.value * math.pi * 0.8),
                  ),
                ),

                Positioned(
                  top: MediaQuery.of(context).size.height * 0.2,
                  right: MediaQuery.of(context).size.width * 0.6,
                  child: _buildGradientBlob(
                    [
                      const Color(0xFF64FFDA).withAlpha(20), // Teal
                      const Color(0xFF1DE9B6).withAlpha(15), // Light teal
                    ],
                    80 + 15 * math.cos(_animationController.value * math.pi * 0.7),
                  ),
                ),
              ],
            );
          },
        ),

        // Glassmorphic overlay
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), // Increased blur for more aesthetic effect
          child: Container(
            color: Colors.white.withAlpha(20), // Very subtle white overlay
          ),
        ),
      ],
    );
  }

  // New method for creating gradient blobs
  Widget _buildGradientBlob(List<Color> colors, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }

  Widget _buildTasksList() {
    // Placeholder for tasks list
    return Center(
      child: Text(
        'Your tasks will appear here',
        style: TextStyle(
          fontSize: 16,
          color: Colors.black.withAlpha(153), // Using withAlpha instead of withOpacity (0.6)
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isButtonExpanded = !_isButtonExpanded;
          if (_isButtonExpanded) {
            _buttonAnimationController.forward();
            // Show the create task screen
            _showCreateTaskScreen();
          } else {
            _buttonAnimationController.reverse();
          }
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFFFF4747), // Red color #FF4747
        ),
        child: AnimatedBuilder(
          animation: _buttonAnimationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _buttonAnimationController.value * math.pi / 4, // Rotate 45 degrees
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCreateTaskScreen() {
    // Show keyboard immediately
    FocusScope.of(context).requestFocus(FocusNode());

    // Show a centered dialog instead of a bottom sheet
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(100), // Semi-transparent barrier
      builder: (context) {
        // Position slightly lower than center
        return const Padding(
          padding: EdgeInsets.only(top: 80),
          child: CreateTaskScreen(),
        );
      },
    ).then((_) {
      // When the dialog is closed, reset the button
      setState(() {
        _isButtonExpanded = false;
        _buttonAnimationController.reverse();
      });
    });
  }
}