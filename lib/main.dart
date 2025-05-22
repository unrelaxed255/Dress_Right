// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:dress_right/providers/theme_provider.dart';
import 'package:dress_right/theme/app_theme.dart';
import 'package:dress_right/screens/splash_screen.dart';
import 'package:dress_right/services/notification_service.dart';

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Essential Flutter initialization
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service BEFORE running the app
  try {
    await NotificationService().init();
    print('✅ Notification service initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize notification service: $e');
  }
  
  // Run the app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
  
  // Remove the splash screen after a short delay
  Future.delayed(const Duration(milliseconds: 800), () {
    FlutterNativeSplash.remove();
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNotificationPermissions();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - check for any notification actions
        _handleAppResume();
        break;
      case AppLifecycleState.paused:
        // App went to background
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        break;
      case AppLifecycleState.inactive:
        // App is inactive
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }
  
  Future<void> _checkNotificationPermissions() async {
    // Check if notifications are enabled
    final areEnabled = await NotificationService().areNotificationsEnabled();
    if (!areEnabled) {
      print('⚠️ Notifications are not enabled - user may need to enable them in settings');
    } else {
      print('✅ Notifications are enabled');
    }
  }
  
  void _handleAppResume() {
    // You can add logic here to handle what happens when the app resumes
    // For example, refresh data, check for pending notifications, etc.
    print('📱 App resumed');
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'DressRight',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: AppTheme.buildTheme(isDark: false).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            scaffoldBackgroundColor: Colors.black,
          ),
          darkTheme: AppTheme.buildTheme(isDark: true).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            scaffoldBackgroundColor: Colors.black,
          ),
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}