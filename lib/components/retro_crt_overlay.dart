import 'package:flutter/material.dart';

class RetroCrtEffect extends StatelessWidget {
  final Widget child;

  const RetroCrtEffect({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The Game Content (The underlying widget)
        child,

        // 2. Scanline Overlay (Horizontal lines)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ScanlinePainter(),
            ),
          ),
        ),

        // 3. Vignette Shader (Darken edges)
        Positioned.fill(
          child: IgnorePointer(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return RadialGradient(
                  center: Alignment.center,
                  radius: 1.0, // Adjust for corner darkness
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3), // Subtle inner shadow
                    Colors.black.withOpacity(0.8), // Dark corners
                  ],
                  stops: const [0.6, 0.8, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcOver, // Draws on top
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        
        // 4. (Optional) Subtle Screen Tint
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: const Color(0xFF00FF41).withOpacity(0.02), // Very faint matrix green tint
            ),
          ),
        ),
      ],
    );
  }
}

// Highly performant painter for scanlines
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.15) // Scanline darkness
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw a line every 3 pixels
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter oldDelegate) => false;
}