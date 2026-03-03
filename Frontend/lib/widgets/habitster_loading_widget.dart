import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HabitsterLoadingWidget extends StatelessWidget {
  final double fontSize;
  final Color? color;
  
  const HabitsterLoadingWidget({super.key, this.fontSize = 24.0, this.color});

  @override
  Widget build(BuildContext context) {
    final letters = 'habitster'.split('').map((letter) => Text(
      letter,
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color ?? const Color(0xFFFF0066),
        letterSpacing: 1.2,
      ),
    )).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: letters.animate(
        interval: 80.ms,
        onPlay: (controller) => controller.repeat(),
      )
      .moveY(begin: 0, end: -12, duration: 350.ms, curve: Curves.easeOutSine)
      .then()
      .moveY(begin: -12, end: 0, duration: 350.ms, curve: Curves.easeInSine)
      .then(delay: 500.ms) // short pause between waves
      ,
    );
  }
}
