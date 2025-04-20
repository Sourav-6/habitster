import 'package:flutter/material.dart';
import 'register.dart'; // Import the Register page
import 'signin.dart'; // Import the SignIn page

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
              const Spacer(flex: 2), // Increased spacer to push content down
              // Logo (larger with constrained max height)
              Flexible(
                flex: 3,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 600),
                  child: Image.asset(
                    'assets/images/gradient_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              
              // Slogan Text
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
              
              const Spacer(flex: 3), // Further increased spacer to push icons and buttons down
              
              // Activity Icons Row
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
              
              // Register Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Register(), // Navigate to Register page
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50035), // Fixed typo
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
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
              
              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignIn(), // Navigate to SignIn page
                      ),
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
              const Spacer(flex: 2), // Keeps bottom spacing
            ],
          ),
        ),
      ),
    );
  }
}