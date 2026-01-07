import 'dart:math';
import 'package:flutter/material.dart';
import '../models/power_up.dart';

class NeonSnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int>? food;
  final List<PowerUp> powerUps;
  final int rows;
  final int columns;
  final double animationValue; // For smooth sliding (0.0 to 1.0)

  // Neon Theme Colors
  static const Color neonGreen = Color(0xFF00FF41);
  static const Color neonRed = Color(0xFFFF003C);
  static const Color neonBlue = Color(0xFF00F3FF);

  NeonSnakePainter({
    required this.snake,
    required this.food,
    required this.powerUps,
    required this.rows,
    required this.columns,
    this.animationValue = 1.0, // Default to fully moved
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    // 1. Draw Grid (Subtle Cyberpunk Grid)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (int i = 0; i <= columns; i++) {
      double x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int i = 0; i <= rows; i++) {
      double y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw Food with Bloom
    if (food != null) {
      final foodCenter =
          Offset((food!.x + 0.5) * cellWidth, (food!.y + 0.5) * cellHeight);

      // Bloom Glow
      canvas.drawCircle(
          foodCenter,
          cellWidth * 0.4,
          Paint()
            ..color = neonRed
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8) // GLOW
          );

      // Core
      canvas.drawCircle(
          foodCenter, cellWidth * 0.25, Paint()..color = Colors.white);
    }

    // 3. Draw Snake (Connected Lines)
    if (snake.isEmpty) return;

    final snakePaint = Paint()
      ..color = neonGreen
      ..strokeWidth = cellWidth * 0.8 // Slightly thinner than cell
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke; // We draw a line, not rects

    // Shadow/Glow for snake
    final glowPaint = Paint()
      ..color = neonGreen.withOpacity(0.6)
      ..strokeWidth = cellWidth * 0.9
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();

    // Start from Head
    // NOTE: To enable "smooth sliding", the head's position on canvas
    // would effectively be lerp(previousHead, currentHead, animationValue)
    // For this implementation, we draw the static path for stability first.

    if (snake.isNotEmpty) {
      final start = _getCenter(snake.first, cellWidth, cellHeight);
      path.moveTo(start.dx, start.dy);

      for (int i = 1; i < snake.length; i++) {
        final current = _getCenter(snake[i], cellWidth, cellHeight);

        // Handle screen wrapping: Don't draw a line across the whole screen
        // if the snake wraps from Right edge to Left edge.
        if ((snake[i - 1].x - snake[i].x).abs() > 1 ||
            (snake[i - 1].y - snake[i].y).abs() > 1) {
          path.moveTo(current.dx, current.dy);
        } else {
          path.lineTo(current.dx, current.dy);
        }
      }
    }

    // Draw Glow then Core
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, snakePaint);
  }

  Offset _getCenter(Point<int> p, double w, double h) {
    return Offset((p.x + 0.5) * w, (p.y + 0.5) * h);
  }

  @override
  bool shouldRepaint(covariant NeonSnakePainter oldDelegate) => true;
}
