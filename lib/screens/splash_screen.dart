import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dress_right/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _progress = 0.0;
  Timer? _stepTimer;
  int _currentMessageIndex = 0;
  final int _totalStars = 7;
  final Random _random = Random();
  final List<String> _loadingMessages = [
    "Ironing OCPs...",
    "Blousing boots...",
    "Checking reflective belt status...",
    "Aligning chevrons...",
    "Judging unauthorized mustaches...",
    "Highlighting hairline violations...",
    "Rechecking checklist for the checklist..."
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    Future.delayed(const Duration(milliseconds: 400), _startSmoothLoading);
  }

  void _startSmoothLoading() {
    void tick() {
      if (_progress >= 1.0) {
        final delay = Duration(milliseconds: 500 + _random.nextInt(1000));
        Future.delayed(delay, () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        });
        return;
      }

      final nextStep = _progress + _random.nextDouble() * 0.02 + 0.01;
      final nextDelay = _random.nextBool()
          ? Duration(milliseconds: 30 + _random.nextInt(40))  // fast
          : Duration(milliseconds: 200 + _random.nextInt(400)); // pause

      setState(() {
        _progress = nextStep.clamp(0.0, 1.0);
        _currentMessageIndex = (_progress * _loadingMessages.length).floor().clamp(0, _loadingMessages.length - 1);
      });

      _stepTimer = Timer(nextDelay, tick);
    }

    tick();
  }

  Widget _buildStarLoader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_totalStars, (_) {
              return Image.asset(
                'assets/images/bg_star.png',
                width: 26,
                height: 26,
                color: Colors.transparent,
              );
            }),
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: _progress,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_totalStars, (_) {
                  return Image.asset(
                    'assets/images/bg_star.png',
                    width: 26,
                    height: 26,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash_background.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.65),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.10,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  'assets/images/dress_right_text.png',
                  width: 280,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildStarLoader(),
                const SizedBox(height: 12),
                Text(
                  _loadingMessages[_currentMessageIndex],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}