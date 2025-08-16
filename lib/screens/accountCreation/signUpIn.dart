import 'package:flutter/material.dart';
import 'register.dart';
import 'signin.dart';

class SignUpIn extends StatelessWidget {
  const SignUpIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              ),
              const SizedBox(height: 4),
              const Text(
                "Let's transform life,\none habit at a time.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              const Spacer(flex: 6), // Increased from 4 to 6
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Woman Climbing Light Skin Tone.png',
                    height: 64,
                  ),
                  const SizedBox(width: 24),
                  Image.asset(
                    'assets/images/Person Bouncing Ball Light Skin Tone.png',
                    height: 64,
                  ),
                  const SizedBox(width: 24),
                  Image.asset(
                    'assets/images/Man In Lotus Position Dark Skin Tone.png',
                    height: 64,
                  ),
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
                    side: const BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 1), // Decreased from 2 to 1
            ],
          ),
        ),
      ),
    );
  }
}
