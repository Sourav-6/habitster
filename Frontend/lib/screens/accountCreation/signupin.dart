import 'package:flutter/material.dart';
import 'register.dart';
import 'signin.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SignUpIn extends StatelessWidget {
  const SignUpIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Flexible(
                flex: 10,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxHeight: 12000, maxWidth: double.infinity),
                  child: Image.asset(
                    'assets/images/habitsterGradient.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ).animate()
                .fade(duration: 800.ms)
                .scaleXY(begin: 0.8, end: 1.0, duration: 800.ms, curve: Curves.easeOutBack)
                .shimmer(delay: 1000.ms, duration: 1500.ms), // Add a nice shine effect after it appears
              const SizedBox(height: 4),
              Text(
                "Let's transform life,\none habit at a time.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(180),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ).animate()
                .fade(delay: 500.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0.0, curve: Curves.easeOut),
              const SizedBox(height: 16),
              const Spacer(flex: 6), // Increased from 4 to 6
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Woman Climbing Light Skin Tone.png',
                    height: 64,
                  ).animate().fade(delay: 600.ms).slideX(begin: -0.5),
                  const SizedBox(width: 24),
                  Image.asset(
                    'assets/images/Person Bouncing Ball Light Skin Tone.png',
                    height: 64,
                  ).animate().fade(delay: 800.ms).scaleXY(begin: 0.8),
                  const SizedBox(width: 24),
                  Image.asset(
                    'assets/images/Man In Lotus Position Dark Skin Tone.png',
                    height: 64,
                  ).animate().fade(delay: 1000.ms).slideX(begin: 0.5),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Register()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0066), // Updated color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignIn()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.labelLarge?.color,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 1), // Decreased from 2 to 1
              const SizedBox(height: 16),

              SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse("https://habitster.onrender.com/auth/google");
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: Image.asset('assets/images/google_logo.png', height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.login)),
                    label: Text("Continue with Google",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.87))),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
