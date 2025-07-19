import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback? onComplete;

  const TutorialOverlay({super.key, this.onComplete});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<TutorialStep> tutorialSteps = [
    TutorialStep(
      title: "Welcome to Sota Snake! 🐍",
      description: "Let's learn how to play in just a few simple steps.",
      alignment: Alignment.center,
      highlightArea: const RelativeRect.fromLTRB(100, 100, 100, 100),
    ),
    TutorialStep(
      title: "Control Your Snake",
      description:
          "Swipe in any direction to move your snake. Collect food to grow longer and score points!",
      alignment: Alignment.bottomCenter,
      highlightArea: const RelativeRect.fromLTRB(50, 200, 50, 100),
    ),
    TutorialStep(
      title: "Power-Ups ⚡",
      description: """Collect special items for amazing abilities:
• Speed Boost
• Score Multiplier
• Invincibility
• Slow Motion""",
      alignment: Alignment.centerRight,
      highlightArea: const RelativeRect.fromLTRB(200, 100, 20, 100),
    ),
    TutorialStep(
      title: "Track Your Progress",
      description:
          "Watch your score grow and level up as you play. Try to beat the high score!",
      alignment: Alignment.topCenter,
      highlightArea: const RelativeRect.fromLTRB(20, 20, 20, 400),
    ),
    TutorialStep(
      title: "Daily Challenges 🎯",
      description:
          "Complete daily tasks to earn bonus points and climb the leaderboard!",
      alignment: Alignment.centerLeft,
      highlightArea: const RelativeRect.fromLTRB(20, 100, 200, 100),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
    if (!isFirstTime) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  void _handleNext() {
    if (currentStep < tutorialSteps.length - 1) {
      _animationController.reverse().then((_) {
        setState(() {
          currentStep++;
        });
        _animationController.forward();
      });
    } else {
      _completeTutorial();
      Navigator.of(context).pop();
    }
  }

  void _handleSkip() {
    _completeTutorial();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTutorial = tutorialSteps[currentStep];

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Semi-transparent background
          Container(
            color: Colors.black.withOpacity(0.7),
          ),

          // Spotlight effect
          Positioned.fill(
            child: CustomPaint(
              painter: SpotlightPainter(
                area: currentTutorial.highlightArea,
                radius: 100,
              ),
            ),
          ),

          // Tutorial content
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Align(
                    alignment: currentTutorial.alignment,
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Progress indicators
                            Row(
                              children: List.generate(
                                tutorialSteps.length,
                                (index) => Expanded(
                                  child: Container(
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: index <= currentStep
                                          ? Colors.green
                                          : Colors.grey[700],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title
                            Text(
                              currentTutorial.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            // Description
                            Text(
                              currentTutorial.description,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: _handleSkip,
                                  child: Text(
                                    'Skip Tutorial',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _handleNext,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currentStep == tutorialSteps.length - 1
                                            ? "Let's Play!"
                                            : 'Next',
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class TutorialStep {
  final String title;
  final String description;
  final Alignment alignment;
  final RelativeRect highlightArea;

  TutorialStep({
    required this.title,
    required this.description,
    required this.alignment,
    required this.highlightArea,
  });
}

class SpotlightPainter extends CustomPainter {
  final RelativeRect area;
  final double radius;

  SpotlightPainter({required this.area, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final center = Offset(
      (size.width - area.left - area.right) / 2 + area.left,
      (size.height - area.top - area.bottom) / 2 + area.top,
    );

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) =>
      area != oldDelegate.area || radius != oldDelegate.radius;
}
