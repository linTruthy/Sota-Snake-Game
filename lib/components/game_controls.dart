import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../logic/snake_game_logic.dart';
import '../services/feedback_manager.dart';

class GameDpad extends StatelessWidget {
  final Function(Direction) onDirectionChanged;

  const GameDpad({
    super.key,
    required this.onDirectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[900]!.withOpacity(0.5),
              border: Border.all(color: Colors.white10, width: 2),
            ),
          ),
          // UP
          Positioned(
            top: 10,
            child: _DpadButton(
              icon: CupertinoIcons.chevron_up,
              onTap: () => onDirectionChanged(Direction.up),
            ),
          ),
          // DOWN
          Positioned(
            bottom: 10,
            child: _DpadButton(
              icon: CupertinoIcons.chevron_down,
              onTap: () => onDirectionChanged(Direction.down),
            ),
          ),
          // LEFT
          Positioned(
            left: 10,
            child: _DpadButton(
              icon: CupertinoIcons.chevron_left,
              onTap: () => onDirectionChanged(Direction.left),
            ),
          ),
          // RIGHT
          Positioned(
            right: 10,
            child: _DpadButton(
              icon: CupertinoIcons.chevron_right,
              onTap: () => onDirectionChanged(Direction.right),
            ),
          ),
          // Center decoration (optional)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.green.withOpacity(0.3), Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DpadButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _DpadButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          FeedbackManager().buttonClick(); // Haptic trigger
          onTap();
        },
        borderRadius: BorderRadius.circular(30),
        splashColor: Colors.green.withOpacity(0.4),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 4)
              ]),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
