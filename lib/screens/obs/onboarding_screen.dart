import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart'; // Added Lottie package
import '../accountCreation/signUpIn.dart';  // Add this import

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Lock to portrait mode
  ]).then((_) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
    runApp(const MyApp());
  });
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

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {  // Changed from SingleTickerProviderStateMixin
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<LottieComposition?> _cachedAnimations = [];
  bool _isLoading = true;

  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  late AnimationController _textController;
  final List<String> _welcomeLines = [
    'Ready to',
    'transform',
    'your life?'
  ];
  List<Animation<double>> _lineAnimations = [];

  @override
  void initState() {
    super.initState();
    _precacheAnimations();
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
    ]).animate(_logoController);

    _logoController.forward();

    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create staggered animations for each line
    _lineAnimations = _welcomeLines.asMap().entries.map((entry) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _textController,
          curve: Interval(
            entry.key * 0.2, // Stagger start times
            (entry.key * 0.2) + 0.6,
            curve: Curves.easeOut,
          ),
        ),
      );
    }).toList();

    _startTextAnimation();
  }

  void _startTextAnimation() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      _textController.forward();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _precacheAnimations() async {
    setState(() => _isLoading = true);
    _cachedAnimations = await Future.wait(
      _pages.map((page) => AssetLottie(page['animation']).load()).toList(),
    );
    setState(() => _isLoading = false);
  }

  final List<Map<String, dynamic>> _pages = [
    {
      'animation': 'assets/animations/waving.json',
      'title': 'Welcome to\nHabitster',
      'subtitle': 'Your journey to a better you\nstarts here.',
      'color': const Color(0xFFFF0125), // Changed to red only for first screen
    },
    {
      'animation': 'assets/animations/running.json', // Updated to use Lottie animation
      'title': RichText(
        text: const TextSpan(
          children: [
            TextSpan(text: 'Build\n', style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold)),
            TextSpan(text: 'Discipline', style: TextStyle(color: Color(0xFFE8A400), fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      'subtitle': 'Track workouts, habits, and feel the gains.',
      'color': const Color(0xFFE8A400), // Updated to new color (#e8a400)
    },
    {
      'animation': 'assets/animations/books.json', // Updated to use Lottie animation
      'title': RichText(
        text: const TextSpan(
          children: [
            TextSpan(text: 'Master\n', style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold)),
            TextSpan(text: 'Focus', style: TextStyle(color: Color(0xFF9C27B0), fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      'subtitle': 'Focus like a monk with Pomodoro and breaks.',
      'color': const Color(0xFFF7BF80), // Updated to new color (#f7bf80)
    },
    {
      'animation': 'assets/animations/study.json', // Updated to use Lottie animation
      'title': RichText(
        text: const TextSpan(
          children: [
            TextSpan(text: 'Study\n', style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold)),
            TextSpan(text: 'Smarter', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      'subtitle': 'Smash study goals with challenges and flashcards.',
      'color': const Color(0xFFCECED0), // Updated to new color (#ceced0)
      'animationScale': 0.6, // Larger animation for the study screen
    },
    {
      'animation': 'assets/animations/astro.json',
      'title': "Let's Begin\nYour Journey",
      'subtitle': 'Time to take control and build habits that last',
      'color': const Color(0xFF261832),  // Changed from E8A400 to 261832
    },
  ];

  @override
  Widget build(BuildContext context) {
    bool isLastPage = _pages[_currentPage]['isLastPage'] == true;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _currentPage == 0 ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: _currentPage == 0 ? const Color(0xFFFF0125) : _pages[_currentPage]['color'],
        systemNavigationBarIconBrightness: _currentPage == 0 ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isLastPage ? Colors.white : _pages[_currentPage]['color'],
        body: SafeArea(
          child: PageView.builder(
            controller: _pageController,
            physics: _currentPage == 0 
                ? const NeverScrollableScrollPhysics() // Disable swipe on first screen
                : const BouncingScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildFirstScreen(context);
              } else {
                return _buildOnboardingPage(context, index);
              }
            },
          ),
        ),
      ),
    );
  }

  // Custom thick arrow icon
  Widget _buildThickArrowIcon() {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) => LinearGradient(
        colors: [Colors.black, Colors.black],
      ).createShader(bounds),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 32,
        weight: 900,
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.5,
      left: 32,
      right: 32,
      child: Column(
        children: _welcomeLines.asMap().entries.map((entry) {
          return FadeTransition(
            opacity: _lineAnimations[entry.key],
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(_lineAnimations[entry.key]),
              child: Text(
                entry.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFirstScreen(BuildContext context) {
    return Container(
      color: const Color(0xFFFF0125),
      child: Stack(
        children: [
          // Center Logo with pop animation - adjusted position
          Positioned(
            top: MediaQuery.of(context).size.height * 0.12, // Adjusted position for larger logo
            left: 0,
            right: 0,
            child: ScaleTransition(
              scale: _logoAnimation,
              child: SizedBox(
                width: 320, // Increased from 280
                height: 320, // Increased from 280
                child: Image.asset(
                  'assets/images/white_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // New Welcome Text
          _buildWelcomeText(),

          // Let's Go Button - Updated styling
          Positioned(
            bottom: 60,
            left: 64,  // Increased left padding
            right: 64, // Increased right padding
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            _pageController.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: const Center(
                              child: Text(
                                "Let's begin",  // Changed text case
                                style: TextStyle(
                                  color: Color(0xFFFF0125),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
        
        // Lottie Animation - adjusted position for running animation
        Positioned(
          top: index == 1 
              ? MediaQuery.of(context).size.height * 0.12 // Lowered position for second screen
              : MediaQuery.of(context).size.height * 0.08,
          left: 0,
          right: 0,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Lottie(
                  composition: _cachedAnimations[index],
                  height: MediaQuery.of(context).size.height *
                      (index == 3 ? 0.55 
                       : index == 4 ? 0.65  // Increased size for astro animation
                       : 0.48),
                  fit: BoxFit.contain,
                ),
        ),
        
        // White rounded container at the bottom - moved above the animation
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.40, // Increased from 0.28
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
                _pages[index]['title'] is RichText 
                    ? _pages[index]['title']
                    : Text(
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
        
        // Updated Progress Indicators
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4, // Changed to show only 4 dots
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                height: 8,
                width: (i + 1) == _currentPage ? 24 : 8, // Adjusted index calculation
                decoration: BoxDecoration(
                  color: (i + 1) == _currentPage 
                      ? const Color(0xFF1A1A1A)
                      : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        
        // Get Started Button for last page, otherwise show arrow button
        index == 4 ? Positioned(
          bottom: 80,  // Positioned above progress dots
          left: 64,
          right: 64,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF261832),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpIn()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: const Center(
                    child: Text(
                      "Get Started",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ) : Positioned(
          right: 24,
          bottom: 24,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _pages[index]['color'],
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
              icon: _buildThickArrowIcon(),
            ),
          ),
        ),
        
        // Skip button
        Positioned(
          top: 16,
          right: 16,
          child: TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SignUpIn()),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(8),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Skip',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}