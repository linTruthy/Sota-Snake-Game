import 'package:flutter/material.dart';
import 'dart:math' show pi;

class GameScoreDisplay extends StatefulWidget {
  final int score;
  final int highScore;
  final int level;

  const GameScoreDisplay({
    super.key,
    required this.score,
    required this.highScore,
    required this.level,
  });

  @override
  State<GameScoreDisplay> createState() => _GameScoreDisplayState();
}

class _GameScoreDisplayState extends State<GameScoreDisplay>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _highScoreController;
  late AnimationController _levelController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _highScoreAnimation;
  late Animation<double> _levelAnimation;

  @override
  void initState() {
    super.initState();

    // Score pulse animation
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _scoreAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeInOut),
    );

    // High score bounce animation
    _highScoreController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _highScoreAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _highScoreController, curve: Curves.elasticOut),
    );

    // Level rotation animation
    _levelController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    _levelAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _levelController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _highScoreController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  Widget _buildScoreCard({
    required String title,
    required String value,
    required List<Color> gradientColors,
    required Animation<double> animation,
    required IconData icon,
    bool rotate = false,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        Widget content = Container(
          width: 110,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradientColors[0].withOpacity(0.2),
                gradientColors[1].withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradientColors[0].withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: gradientColors[0],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: gradientColors[1],
                    ),
                  ),
                  const SizedBox(width: 2),
                  rotate
                      ? Transform.rotate(
                          angle: animation.value,
                          child: Icon(icon, color: gradientColors[0], size: 18),
                        )
                      : Transform.scale(
                          scale: animation.value,
                          child: Icon(icon, color: gradientColors[0], size: 18),
                        ),
                ],
              ),
            ],
          ),
        );

        return Transform.scale(
          scale: rotate ? 1.0 : animation.value,
          child: content,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreCard(
            title: 'SCORE',
            value: widget.score.toString(),
            gradientColors: const [Colors.amber, Colors.orange],
            animation: _scoreAnimation,
            icon: Icons.star,
          ),
          _buildScoreCard(
            title: 'HIGH SCORE',
            value: widget.highScore.toString(),
            gradientColors: const [Colors.purple, Colors.blue],
            animation: _highScoreAnimation,
            icon: Icons.emoji_events,
          ),
          _buildScoreCard(
            title: 'LEVEL',
            value: widget.level.toString(),
            gradientColors: const [Colors.green, Colors.teal],
            animation: _levelAnimation,
            icon: Icons.flash_on,
            rotate: true,
          ),
        ],
      ),
    );
  }
}

class ScoreCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - 20, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
