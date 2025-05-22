import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dress_right/screens/home_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // Initialize with default values
  AnimationController? _controller;
  Animation<double>? _logoScaleAnimation;
  Animation<double>? _logoPositionAnimation;
  Animation<double>? _backgroundFadeAnimation;
  
  double _progress = 0.0;
  Timer? _stepTimer;
  int _currentMessageIndex = 0;
  final int _totalStars = 7;
  final Random _random = Random();
  bool _animationsInitialized = false;
  
  // Master list of all possible messages
  final List<String> _allLoadingMessages = [
    "Pressing service dress...",
    "Checking pant-to-boot alignment...",
    "Measuring hair bulk with precision tools...",
    "Examining spice brown flag patch orientation...",
    "Verifying name tape thread color...",
    "Measuring gap between service dress jacket buttons...",
    "Ensuring OCP camo pattern meets regulations...",
    "Calculating space between occupational badges...",
    "Checking for authorized OCP boots...",
    "Measuring sleeve length to wristbone...", 
    "Aligning rank insignia precisely...",
    "Verifying all uniform items meet approved shade...",
    "Checking for proper hat-to-eyebrow distance...",
    "Examining sand t-shirt condition...",
    "Measuring belt length past buckle...",
    "Validating proper sock color...",
    "Ensuring trouser blousing hits boot third eyelet...",
    "Scanning for unauthorized morale patches...",
    "Checking if hands are in pockets...",
    "Confirming tactical cap is worn correctly...",
    "Measuring space between ribbons...",
    "Ensuring nametag is level and centered...",
    "Evaluating proper length of mustache...",
    "Examining fingernail length and polish...",
    "Verifying religious accommodation compliance...",
    "Inspecting for loose strings and threads...",
    "Measuring distance between U.S. lapel insignia...",
    "Checking all badges are properly spaced...",
    "Scanning for unauthorized phone usage while walking...",
    "Examining proper belt buckle alignment...",
    "Verifying correct blues shirt is tucked properly...",
    "Checking ball cap authorized wear locations...",
    "Ensuring all pockets are buttoned...",
    "Confirming all t-shirts are coyote brown...",
    "Checking uniform for signs of fading...",
    "Measuring distance between edge of pocket and badges...",
    "Locating authorized outer garments...",
    "Ensuring boots are properly laced...",
    "Checking for authorized subdued patches only...",
    "Validating current occupational badge wear...",
    "Loading AFI 36-2903 update 14...",
    "Verifying dress uniform measurements...",
    "Calculating service cap placement angle...",
    "Checking for authorized backpack wear method...",
    "Confirming proper placement of academic badges..."
  ];
  
  // Subset that will be used for this session
  late List<String> _loadingMessages;
  
  // Loading stages to create more realistic progress
  final List<double> _loadingStages = [];
  int _currentStage = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Create a randomized subset of messages for this session
    _loadingMessages = _getRandomizedMessages();
    
    // Create random loading stages
    _generateLoadingStages();
    
    // Initialize animation controller immediately
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500),
    );
    
    // Force colors to match splash screen exactly
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    
    // Complete animation setup after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // First remove the native splash
      FlutterNativeSplash.remove();
      
      // Then start our custom animations
      _completeAnimationSetup();
    });
  }
  
  // New method to complete animation setup
  void _completeAnimationSetup() {
    if (!mounted) return;
    
    final screenSize = MediaQuery.of(context).size;
    
    // Animation for logo scaling - start at 1.0 (same as native splash) for smooth transition
    _logoScaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    
    // Animation for logo position - start at current center position
    _logoPositionAnimation = Tween<double>(
      begin: screenSize.height * 0.35, // Center position (same as native splash)
      end: screenSize.height * 0.10,   // Final top position
    ).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    
    // Animation for background fade
    _backgroundFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    
    setState(() {
      _animationsInitialized = true;
    });
    
    // Start animations
    _controller!.forward();
    
    // Start loading progress with a shorter initial delay
    Future.delayed(const Duration(milliseconds: 300), _startImprovedLoading);
  }
  
  // Get a randomized subset of loading messages
  List<String> _getRandomizedMessages() {
    final shuffled = List<String>.from(_allLoadingMessages)..shuffle(_random);
    final messageCount = 7 + _random.nextInt(6); // Between 7 and 12 messages
    return shuffled.take(messageCount).toList();
  }
  
  // Generate more realistic loading stages
  void _generateLoadingStages() {
    // Start with 0
    _loadingStages.add(0.0);
    
    // Generate between 5-8 stages
    final numStages = 5 + _random.nextInt(4);
    
    // Create incrementally increasing stages
    for (int i = 1; i < numStages; i++) {
      // Make some stages longer than others for realism
      double progressIncrement = 0.1 + _random.nextDouble() * 0.2;
      
      // Later stages might progress faster or slower
      if (i > numStages / 2 && _random.nextBool()) {
        progressIncrement *= 0.7; // Slower for some tasks
      } else if (i > numStages * 0.7) {
        progressIncrement *= 1.3; // Faster toward the end
      }
      
      // Add next stage, ensuring we don't exceed 1.0
      final nextStage = (_loadingStages.last + progressIncrement).clamp(0.0, 0.95);
      _loadingStages.add(nextStage);
    }
    
    // Ensure the last stage is 1.0 (complete)
    _loadingStages.add(1.0);
  }
  
  // Improved loading that mimics realistic processing patterns
  void _startImprovedLoading() {
    void advanceToNextStage() {
      if (!mounted) return;
      
      // If we're at the last stage, go to home screen
      if (_currentStage >= _loadingStages.length - 1) {
        // Final short delay
        final delay = Duration(milliseconds: 200 + _random.nextInt(200));
        Future.delayed(delay, () {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        });
        return;
      }
      
      // Move to next stage and update message
      _currentStage++;
      final targetProgress = _loadingStages[_currentStage];
      
      // Smooth animation to the next stage
      void animateToStage() {
        if (!mounted) return;
        
        // If we're almost at target, just set it directly
        if ((targetProgress - _progress).abs() < 0.01) {
          setState(() {
            _progress = targetProgress;
            // Update message when we reach a new stage
            _currentMessageIndex = (_currentStage % _loadingMessages.length);
          });
          
          // Pause at this stage before moving to next
          // Shorter pauses for a faster experience
          final pauseTime = 80 + _random.nextInt(250);
          _stepTimer = Timer(Duration(milliseconds: pauseTime), advanceToNextStage);
          return;
        }
        
        // Calculate smooth step size
        final step = (targetProgress - _progress) * 0.18; // Take 18% of remaining distance
        
        setState(() {
          _progress += step;
        });
        
        // Schedule next animation frame
        final frameTime = 8 + _random.nextInt(8); // 8-16ms for smooth animation (60-120fps)
        _stepTimer = Timer(Duration(milliseconds: frameTime), animateToStage);
      }
      
      // Start animation to this stage
      animateToStage();
    }
    
    // Start the loading sequence
    advanceToNextStage();
  }

  Widget _buildStarLoader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(
          colors: [
            Colors.white.withAlpha(38), 
            Colors.white.withAlpha(13),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withAlpha(51),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_totalStars, (index) {
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
                children: List.generate(_totalStars, (index) {
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
    _controller?.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the logo position for initial display
    final screenHeight = MediaQuery.of(context).size.height;
    final initialLogoPosition = screenHeight * 0.35; // Center position
    final finalLogoPosition = screenHeight * 0.10; // Final top position
    
    // Calculate current logo position and scale
    final currentLogoPosition = _animationsInitialized && _logoPositionAnimation != null
        ? _logoPositionAnimation!.value
        : initialLogoPosition;
        
    final currentLogoScale = _animationsInitialized && _logoScaleAnimation != null
        ? _logoScaleAnimation!.value
        : 1.0; // Start at 1.0 to match native splash
        
    final bgOpacity = _animationsInitialized && _backgroundFadeAnimation != null
        ? _backgroundFadeAnimation!.value
        : 1.0;
    
    return Container(
      color: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash_background.png',
                fit: BoxFit.cover,
              ),
            ),
            
            // Black overlay that fades out
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(bgOpacity),
              ),
            ),
            
            // Logo with animations - initially positioned to match native splash
            Positioned(
              top: currentLogoPosition,
              left: 0,
              right: 0,
              child: Center(
                child: Transform.scale(
                  scale: currentLogoScale,
                  child: Image.asset(
                    'assets/images/dress_right_text.png',
                    width: 280,
                  ),
                ),
              ),
            ),
            
            // Loading indicators at bottom - fade in
            Opacity(
              opacity: _animationsInitialized ? (_controller?.value ?? 0.0) : 0.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildStarLoader(),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _loadingMessages[_currentMessageIndex],
                      key: ValueKey<int>(_currentMessageIndex),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}