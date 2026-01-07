import 'dart:math';
import 'dart:ui';
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
  late AnimationController _appearController;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  late ConfettiController _confettiController;
  bool _isNewHighScore = false;

  @override
  void initState() {
    super.initState();
    _isNewHighScore = widget.score >= widget.highScore && widget.score > 0;

    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnim = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOutBack),
    );
    
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeIn),
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    _appearController.forward();
    if (_isNewHighScore) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _appearController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Important for overlay
      body: Stack(
        children: [
          // 1. Heavy Blur Background (Keeps user in the game, not a menu)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.8)),
            ),
          ),
          
          // 2. Main Content
          Center(
            child: AnimatedBuilder(
              animation: _appearController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: child,
                  ),
                );
              },
              child: _buildReportCard(context),
            ),
          ),
          
          // 3. Confetti (Top Center for High Score)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 20, 
              minBlastForce: 8,
              emissionFrequency: 0.05,
              numberOfParticles: 30, 
              gravity: 0.2,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A), // Tech Black
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isNewHighScore ? Colors.amber : Colors.redAccent.withOpacity(0.5), 
          width: 2
        ),
        boxShadow: [
          BoxShadow(
            color: (_isNewHighScore ? Colors.amber : Colors.red).withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            _isNewHighScore ? "NEW RECORD!" : "MISSION FAILED",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
              letterSpacing: 3,
              color: _isNewHighScore ? Colors.amber : Colors.redAccent,
              shadows: [
                Shadow(color: (_isNewHighScore ? Colors.amber : Colors.redAccent).withOpacity(0.5), blurRadius: 10)
              ]
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, width: 60, color: Colors.white24), // Separator
          const SizedBox(height: 32),

          // Big Score Display
          Column(
            children: [
              const Text(
                "FINAL SCORE",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.score.toString(),
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0, // Tighten height
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Comparison Bar
          _buildComparisonRow("HIGH SCORE", widget.highScore),
          
          const SizedBox(height: 40),

          // Primary Action: PLAY AGAIN (Huge)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                 // Trigger callback immediately
                 widget.onPlayAgain();
                 // This ensures the painter rebuilds with new game state on next frame
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14), // Neon Green
                foregroundColor: Colors.black,
                elevation: 10,
                shadowColor: const Color(0xFF39FF14).withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: 28),
                  SizedBox(width: 8),
                  Text(
                    "RETRY MISSION",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Secondary Actions Row
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.leaderboard,
                  label: "RANKINGS",
                  onTap: widget.onShowLeaderboard,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.home,
                  label: "MENU",
                  onTap: () => Navigator.of(context).pop(), // Close dialog, assuming underlay handles it
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}