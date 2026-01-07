import 'package:flutter/material.dart';
import 'dart:ui'; // For image filter
import '../services/score_manager.dart';

class GameScoreDisplay extends StatelessWidget {
  final ScoreManager scoreManager;
  final int level;

  const GameScoreDisplay({
    super.key,
    required this.scoreManager,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return _CyberHUD(
      score: scoreManager.currentScore,
      highScore: scoreManager.highScore,
      level: level,
    );
  }
}

class _CyberHUD extends StatefulWidget {
  final int score;
  final int highScore;
  final int level;

  const _CyberHUD({
    required this.score,
    required this.highScore,
    required this.level,
  });

  @override
  State<_CyberHUD> createState() => _CyberHUDState();
}

class _CyberHUDState extends State<_CyberHUD> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void didUpdateWidget(covariant _CyberHUD oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If score increased, trigger the "Bass Kick" pulse
    if (widget.score > oldWidget.score) {
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      // Glassmorphism background for the HUD
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A12).withOpacity(0.6),
        border: const Border(
          bottom: BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1. Level Badge (Hexagon or Tech Shape)
                _buildLevelIndicator(),

                // 2. Main Score (Center, Big, Pulsing)
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: _buildScoreTicker(),
                ),

                // 3. High Score (Right, Subtle)
                _buildHighScoreDisplay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelIndicator() {
    return CustomPaint(
      painter: _TechBracketPainter(color: Colors.cyanAccent),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "LVL",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${widget.level}".padLeft(2, '0'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'Courier', // Or your custom retro font
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreTicker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "Rolling" Score Animation
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: widget.score),
          duration: const Duration(
              milliseconds: 500), // Slower duration = more satisfaction
          builder: (context, value, child) {
            return Text(
              value.toString().padLeft(6, '0'), // 000150
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: const Color(0xFF39FF14), // Neon Green
                shadows: [
                  BoxShadow(
                    color: const Color(0xFF39FF14).withOpacity(0.8),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
                fontFamily: 'Courier', // Monospaced for stable ticker
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHighScoreDisplay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 12, color: Colors.amber),
            SizedBox(width: 4),
            Text(
              "BEST",
              style: TextStyle(
                color: Colors.amber,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          widget.highScore.toString().padLeft(6, '0'),
          style: TextStyle(
            color: Colors.amber.withOpacity(0.8),
            fontSize: 14,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Creative UI Painter: Draws "Tech" brackets around items
// ---------------------------------------------------------------------------
class _TechBracketPainter extends CustomPainter {
  final Color color;

  _TechBracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final double w = size.width;
    final double h = size.height;
    const double bracketLen = 10.0;

    final path = Path();

    // Top Left Corner
    path.moveTo(0, bracketLen);
    path.lineTo(0, 0);
    path.lineTo(bracketLen, 0);

    // Bottom Right Corner
    path.moveTo(w - bracketLen, h);
    path.lineTo(w, h);
    path.lineTo(w, h - bracketLen);

    canvas.drawPath(path, paint);

    // Optional: Add tiny tech "dots"
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(const Offset(4, 4), 1.5, dotPaint);
    canvas.drawCircle(Offset(w - 4, h - 4), 1.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
