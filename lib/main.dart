import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dress_right/theme/app_theme.dart';
import 'package:dress_right/providers/theme_provider.dart';
import 'package:dress_right/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent early system UI changes that flash white
  WidgetsBinding.instance.renderView.automaticSystemUiAdjustment = false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'DressRight',
          debugShowCheckedModeBanner: false,

          // Force consistent black background to eliminate white flash
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
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}