import 'dart:math';
import 'package:flutter/material.dart';

class ScreenShake extends StatefulWidget {
  final Widget child;
  // Expose a controller so parent can trigger shake
  final ShakeController controller;

  const ScreenShake({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<ScreenShake> createState() => _ScreenShakeState();
}

class ShakeController extends ChangeNotifier {
  void shake() => notifyListeners();
}

class _ScreenShakeState extends State<ScreenShake>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _shakeAnim;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Shake duration
    );

    // Damped oscillation curve
    _shakeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.bounceOut);

    widget.controller.addListener(_triggerShake);
  }

  void _triggerShake() {
    _animController.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_triggerShake);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final double shakeAmount =
            (1.0 - _shakeAnim.value) * 10; // Max 10px offset
        if (shakeAmount == 0) return child!;

        final dx = (_random.nextDouble() - 0.5) * shakeAmount;
        final dy = (_random.nextDouble() - 0.5) * shakeAmount;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
