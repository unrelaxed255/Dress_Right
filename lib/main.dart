// lib/main.dart
import 'package:dress_right/providers/inspection_provider.dart';
import 'package:dress_right/providers/member_provider.dart';
import 'package:dress_right/providers/theme_provider.dart';
import 'package:dress_right/repositories/inspection_repository.dart';
import 'package:dress_right/repositories/member_repository.dart';
import 'package:dress_right/screens/splash_screen.dart';
import 'package:dress_right/services/notification_service.dart';
import 'package:dress_right/storage/hive_boxes.dart';
import 'package:dress_right/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();

  final memberRepository = MemberRepository();
  final inspectionRepository = InspectionRepository();

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MemberProvider(memberRepository)),
        ChangeNotifierProvider(create: (_) => InspectionProvider(inspectionRepository)),
      ],
      child: const MyApp(),
    ),
  );

  Future.delayed(const Duration(milliseconds: 800), FlutterNativeSplash.remove);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed');
    }
  }

  Future<void> _checkNotificationPermissions() async {
    final enabled = await NotificationService().areNotificationsEnabled();
    if (!enabled) {
      debugPrint('Notifications disabled');
    }
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
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
