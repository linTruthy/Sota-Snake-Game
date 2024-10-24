import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class GameOverDialog extends StatefulWidget {
  final int score;
  final int highScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onShowLeaderboard;

  const GameOverDialog({
    super.key,
    required this.score,
    required this.highScore,
    required this.onPlayAgain,
    required this.onShowLeaderboard,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;
  bool _isHighScore = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize scale animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    // Initialize confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Check for high score
    _isHighScore = widget.score >= widget.highScore;

    // Start animations
    _animationController.forward();
    if (_isHighScore) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti effect
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 1,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ],
          ),
        ),
        
        // Main Dialog
        ScaleTransition(
          scale: _scaleAnimation,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            content: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[900]!,
                    Colors.grey[850]!,
                    Colors.grey[900]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.grey[800]!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                   Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Colors.red,
                          Colors.yellow,
                          Colors.green,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'Game Over!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Score Display
                  _buildScoreCard(
                    'Your Score',
                    widget.score,
                    Icons.emoji_events,
                    Colors.amber,
                    isHighScore: _isHighScore,
                  ),
                  const SizedBox(height: 16),
                  _buildScoreCard(
                    'High Score',
                    widget.highScore,
                    Icons.bar_chart,
                    Colors.blue,
                  ),

                  // High Score Message
                  if (_isHighScore) ...[
                    const SizedBox(height: 16),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.2),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: const Text(
                            '🎉 New High Score! 🎉',
                            style: TextStyle(
                              color: Colors.yellow,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButton(
                    'Play Again',
                    Icons.replay,
                    Colors.green,
                    widget.onPlayAgain,
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    'Leaderboard',
                    Icons.leaderboard,
                    Colors.blue,
                    widget.onShowLeaderboard,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(String title, int score, IconData icon, Color color,
      {bool isHighScore = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              Text(
                score.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isHighScore) ...[
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.yellow,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}