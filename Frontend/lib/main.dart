import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app_links/app_links.dart';
import 'screens/features/dashboard/dashboard.dart';
import 'screens/obs/onboarding_screen.dart';
import 'screens/accountCreation/signupin.dart';
import 'services/api_service.dart';
import 'theme/theme_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Onboarding & Theme flags
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('showOnboarding') ?? true;
  final isDark = prefs.getBool('is_dark_mode') ?? false;

  // Check existing login session
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'jwt_token');
  final bool isLoggedIn = token != null && token.isNotEmpty;

  // Hive init
  await Hive.initFlutter();
  await Hive.openBox('chat_sessions');

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();
  await notificationService.scheduleDailyHabitReminders();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(
        initialMode: isDark ? ThemeMode.dark : ThemeMode.light,
      ),
      child: MyApp(showOnboarding: showOnboarding, isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool showOnboarding;
  final bool isLoggedIn;

  const MyApp({super.key, required this.showOnboarding, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  final ApiService _apiService = ApiService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinking();
  }

  void _initDeepLinking() {
    _appLinks = AppLinks();

    // Handle links while the app is running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Handle links that opened the app
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) async {
    if (uri.scheme == 'habitster' && uri.host == 'auth') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        await _apiService.saveToken(token);
        
        // Navigate to Dashboard
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey, // Add navigatorKey to enable global navigation
          title: 'Habitster',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.mode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF0066),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black87),
              titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color(0xFFFF0066),
              unselectedItemColor: Colors.black38,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF0066),
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1E2C),
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E2C),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E1E2C),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withAlpha(20), width: 1),
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1E1E2C),
              selectedItemColor: Color(0xFFFF0066),
              unselectedItemColor: Colors.white38,
            ),
          ),
          home: widget.isLoggedIn 
              ? const DashboardScreen() 
              : (widget.showOnboarding ? const OnboardingScreen() : const SignUpIn()),
        );
      },
    );
  }
}
