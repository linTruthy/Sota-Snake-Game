import 'package:flutter/material.dart';
import 'package:sota_snake_game/models/power_up.dart';

class PowerUpStack extends StatelessWidget {
  final List<PowerUp> powerUps;
  final Map<String, int> remainingTimes;
  final Map<String, Duration> durations;

  const PowerUpStack({
    super.key,
    required this.powerUps,
    required this.remainingTimes,
    required this.durations,
  });

  Color _getProgressColor(int remainingTime) {
    if (remainingTime >= 20) return Colors.green;
    if (remainingTime >= 10) return Colors.orange;
    return Colors.red;
  }

  Color _getPowerUpColor(String type) {
    switch (type) {
      case 'speedBoost': return Colors.yellow;
      case 'scoreMultiplier': return Colors.purple;
      case 'invincibility': return Colors.blue;
      case 'slowMotion': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getPowerUpIcon(String type) {
    switch (type) {
      case 'speedBoost': return Icons.flash_on;
      case 'scoreMultiplier': return Icons.stars;
      case 'invincibility': return Icons.shield;
      case 'slowMotion': return Icons.slow_motion_video;
      default: return Icons.power;
    }
  }

  String _getPowerUpString(String type) {
    switch (type) {
      case 'speedBoost': return 'Speed';
      case 'scoreMultiplier': return 'Score';
      case 'invincibility': return 'Shield';
      case 'slowMotion': return 'Slow';
      default: return 'Power';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: powerUps.map((powerUp) {
          final remainingTime = remainingTimes[powerUp.id] ?? 0;
          final duration = durations[powerUp.id] ?? const Duration(seconds: 30);
          final progress = remainingTime / duration.inSeconds;
          final color = _getPowerUpColor(powerUp.type);
          
          return Container(
            width: 110,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getProgressColor(remainingTime).withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Power-up header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getPowerUpIcon(powerUp.type),
                          color: color,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getPowerUpString(powerUp.type),
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${remainingTime}s',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(remainingTime),
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}