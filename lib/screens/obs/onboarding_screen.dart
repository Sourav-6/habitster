import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitster',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'image': 'assets/images/hammy_waving.png',
      'title': 'Welcome to\nHabitster',
      'subtitle': 'Your journey to a better you\nstarts here.',
      'color': const Color(0xFFFFE500), // Bright yellow
    },
    {
      'image': 'assets/images/jim_strongman.png',
      'title': 'Build\nDiscipline',
      'subtitle': 'Track workouts, habits, and feel the gains.',
      'color': const Color(0xFF9C27B0), // Purple
    },
    {
      'image': 'assets/images/layla_book.png',
      'title': 'Master\nFocus',
      'subtitle': 'Focus like a monk with Pomodoro and breaks.',
      'color': const Color(0xFF2196F3), // Blue
    },
    {
      'image': 'assets/images/albert_study.png',
      'title': 'Study\nSmarter',
      'subtitle': 'Smash study goals with challenges and flashcards.',
      'color': const Color(0xFFFF9800), // Orange
    },
    {
      // Special last page with multiple characters
      'image': 'assets/images/group_shot.png',
      'title': 'Just for You',
      'subtitle': 'Time to take control and build habits',
      'color': const Color(0xFFFFE500), // Bright yellow (same as first page)
      'isLastPage': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow, // Background outside the card
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemCount: _pages.length,
          itemBuilder: (context, index) {
            if (_pages[index]['isLastPage'] == true) {
              return _buildLastOnboardingPage(context, index);
            } else {
              return _buildOnboardingPage(context, index);
            }
          },
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(BuildContext context, int index) {
    return Stack(
      children: [
        // Background color
        Container(
          color: _pages[index]['color'],
        ),
        
        // White rounded container at the bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.28, // Original height
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pages[index]['title'],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _pages[index]['subtitle'],
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black.withOpacity(0.6),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Mascot Image
        Positioned(
          top: MediaQuery.of(context).size.height * 0.15,
          left: 0,
          right: 0,
          child: Image.asset(
            _pages[index]['image'],
            height: MediaQuery.of(context).size.height * 0.45,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.45,
                width: double.infinity,
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: Colors.black.withOpacity(0.5),
                ),
              );
            },
          ),
        ),
        
        // Progress Indicators
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  color: i == _currentPage 
                      ? Colors.black 
                      : Colors.grey.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        
        // Next Button
        Positioned(
          right: 24,
          bottom: 24,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(
                Icons.arrow_forward,
                color: Colors.black,
                size: 28,
              ),
            ),
          ),
        ),
        
        // Skip button
        Positioned(
          top: 16,
          right: 24,
          child: TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
            child: Text(
              'Skip',
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLastOnboardingPage(BuildContext context, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Light cream color
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          // Title
          Text(
            _pages[index]['title'],
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          Expanded(
            child: Center(
              // Group of character images
              child: Image.asset(
                _pages[index]['image'],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.black.withOpacity(0.5),
                  );
                },
              ),
            ),
          ),
          
          // Subtitle
          Text(
            _pages[index]['subtitle'],
            style: TextStyle(
              fontSize: 18,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 40),
          
          // Progress indicators and Get Started button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Progress dots
              Row(
                children: List.generate(
                  _pages.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: i == index 
                          ? Colors.black 
                          : Colors.grey.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              
              // Get Started button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE500), // Bright yellow
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habitster Dashboard')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Welcome to Habitster!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your journey to better habits starts now.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}