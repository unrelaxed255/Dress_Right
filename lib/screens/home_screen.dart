// lib/screens/home_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dress_right/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late AnimationController _parallaxController;
  late Animation<double> _cloudAnimation;
  late Animation<double> _parallaxAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main cloud movement - slow drift
    _cloudController = AnimationController(
      duration: const Duration(seconds: 20), // Faster for testing
      vsync: this,
    );
    
    // Parallax effect for depth - slightly faster
    _parallaxController = AnimationController(
      duration: const Duration(seconds: 15), // Faster for testing
      vsync: this,
    );
    
    _cloudAnimation = Tween<double>(
      begin: -0.3,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _cloudController,
      curve: Curves.easeInOut,
    ));
    
    _parallaxAnimation = Tween<double>(
      begin: -0.2,
      end: 0.2,
    ).animate(CurvedAnimation(
      parent: _parallaxController,
      curve: Curves.easeInOut,
    ));
    
    // Start the animations
    _cloudController.repeat(reverse: true);
    _parallaxController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _parallaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    final goldColor = const Color(0xFFFFD700);
    final creamColor = const Color(0xFFF5F5DC);

    // Lock the orientations you want
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isLandscape ? 60 : 80),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: _buildLogoText(isLandscape, creamColor),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Stack(
            children: [
              // Animated wallpaper layers
              _buildAnimatedBackground(),

              // Main content
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: isLandscape ? 15 : 30,
                    left: 24,
                    right: 24,
                  ),
                  child: orientation == Orientation.portrait
                      ? _buildPortraitLayout(context, goldColor)
                      : _buildLandscapeLayout(context, goldColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Static wallpaper - no movement!
        Positioned.fill(
          child: Image.asset(
            'assets/images/wallpaper.png',
            fit: BoxFit.cover,
          ),
        ),
        
        // Moving cloud shadows - creates depth illusion
        AnimatedBuilder(
          animation: _cloudAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    0.3 + (_cloudAnimation.value * 0.4), 
                    -0.2 + (_cloudAnimation.value * 0.3)
                  ),
                  radius: 1.5 + (_cloudAnimation.value * 0.2),
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            );
          },
        ),
        
        // Drifting light rays - like sun through clouds
        AnimatedBuilder(
          animation: _parallaxAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.5 + (_parallaxAnimation.value * 0.8), -1.0),
                  end: Alignment(0.5 + (_parallaxAnimation.value * 0.8), 1.0),
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                    Colors.white.withOpacity(0.08),
                    Colors.transparent,
                    Colors.white.withOpacity(0.03),
                  ],
                  stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                ),
              ),
            );
          },
        ),
        
        // Floating cloud wisps - individual moving elements
        AnimatedBuilder(
          animation: _cloudAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // Wisp 1
                Positioned(
                  top: 100 + (_cloudAnimation.value * 30),
                  left: 50 + (_cloudAnimation.value * 80),
                  child: Container(
                    width: 120,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Wisp 2
                Positioned(
                  top: 200 + (_cloudAnimation.value * -40),
                  right: 30 + (_cloudAnimation.value * 60),
                  child: Container(
                    width: 80,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Wisp 3
                Positioned(
                  bottom: 150 + (_cloudAnimation.value * 25),
                  left: 20 + (_cloudAnimation.value * -30),
                  child: Container(
                    width: 100,
                    height: 35,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        
        // Atmospheric shimmer - like heat waves
        AnimatedBuilder(
          animation: Listenable.merge([_cloudAnimation, _parallaxAnimation]),
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue.withOpacity(0.02 + (_cloudAnimation.value * 0.01)),
                    Colors.transparent,
                    Colors.white.withOpacity(0.01 + (_parallaxAnimation.value * 0.01)),
                    Colors.transparent,
                    Colors.black.withOpacity(0.1 + (_cloudAnimation.value * 0.03)),
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                ),
              ),
            );
          },
        ),
        
        // Subtle color temperature shifts - like changing weather
        AnimatedBuilder(
          animation: _parallaxAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.8 + (_parallaxAnimation.value * 1.6), -0.5),
                  radius: 2.0,
                  colors: [
                    Colors.orange.withOpacity(0.02),
                    Colors.blue.withOpacity(0.01),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogoText(bool isLandscape, Color creamColor) {
    return AnimatedBuilder(
      animation: _cloudAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_cloudAnimation.value * 2, 0),
          child: Text(
            "DRESSRIGHT",
            style: TextStyle(
              fontFamily: 'Impact',
              fontSize: isLandscape ? 32 : 40,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: creamColor,
              shadows: [
                Shadow(
                  color: Colors.black.withAlpha(150),
                  offset: const Offset(2, 2),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(BuildContext context, Color goldColor) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Info card with subtle float animation
        AnimatedBuilder(
          animation: _parallaxAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _parallaxAnimation.value * 5),
              child: _buildGlassPanel(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.info_outline, color: Colors.white70),
                    SizedBox(width: 12),
                    Text('No pending inspections',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            );
          },
        ),
        const Spacer(),
        // Buttons with floating animation
        AnimatedBuilder(
          animation: _cloudAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _cloudAnimation.value * 3),
              child: Column(
                children: [
                  _buildBubbleButton(
                    icon: Icons.grid_view,
                    label: 'Workcenter Management',
                    baseColor: const Color(0xFF192841),
                    highlightColor: const Color(0xFF3A8DFF),
                    accentColor: Colors.white,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildBubbleButton(
                    icon: Icons.checklist_rounded,
                    label: 'Start Inspection',
                    baseColor: const Color(0xFF0A1E3D),
                    highlightColor: const Color(0xFF0066CC),
                    accentColor: goldColor,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, Color goldColor) {
    return Row(
      children: [
        // Info card
        Expanded(
          flex: 3,
          child: AnimatedBuilder(
            animation: _parallaxAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _parallaxAnimation.value * 5),
                child: _buildGlassPanel(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.info_outline, color: Colors.white70),
                      SizedBox(width: 12),
                      Text('No pending inspections',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        // Buttons
        Expanded(
          flex: 4,
          child: AnimatedBuilder(
            animation: _cloudAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _cloudAnimation.value * 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBubbleButton(
                      icon: Icons.grid_view,
                      label: 'Workcenter Management',
                      baseColor: const Color(0xFF192841),
                      highlightColor: const Color(0xFF3A8DFF),
                      accentColor: Colors.white,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 16),
                    _buildBubbleButton(
                      icon: Icons.checklist_rounded,
                      label: 'Start Inspection',
                      baseColor: const Color(0xFF0A1E3D),
                      highlightColor: const Color(0xFF0066CC),
                      accentColor: goldColor,
                      onPressed: () {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGlassPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(76),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(76),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBubbleButton({
    required IconData icon,
    required String label,
    required Color baseColor,
    required Color highlightColor,
    required Color accentColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: baseColor.withAlpha(153),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: highlightColor.withAlpha(76),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  highlightColor.withAlpha(217),
                  baseColor.withAlpha(242),
                ],
                stops: const [0.2, 1.0],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(64), width: 1.0),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -15,
                  left: -10,
                  right: -10,
                  height: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.0, -0.5),
                        radius: 1.0,
                        colors: [
                          Colors.white.withAlpha(64),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPressed,
                    splashColor: highlightColor.withAlpha(76),
                    highlightColor: highlightColor.withAlpha(25),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: accentColor, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            label,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}