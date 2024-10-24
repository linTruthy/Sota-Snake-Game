import 'package:flutter/material.dart';

class PowerUpIndicator extends StatelessWidget {
  final int remainingTime;
  final Duration duration;
  final String powerUpType;
  final double progress;

  const PowerUpIndicator({
    super.key,
    required this.remainingTime,
    required this.duration,
    required this.powerUpType,
    required this.progress,
  });

  Color _getProgressColor() {
    if (remainingTime >= 20) {
      return Colors.green;
    } else if (remainingTime >= 10) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getPowerUpString() {
    switch (powerUpType) {
      case 'speedBoost':
        return 'Speed Boost';
      case 'scoreMultiplier':
        return 'Score Multiplier';
      case 'invincibility':
        return 'Invincibility';
      case 'slowMotion':
        return 'Slow Motion';
      default:
        return 'Power Up';
    }
  }

  IconData _getPowerUpIcon() {
    switch (powerUpType) {
      case 'speedBoost':
        return Icons.flash_on;
      case 'scoreMultiplier':
        return Icons.stars;
      case 'invincibility':
        return Icons.shield;
      case 'slowMotion':
        return Icons.slow_motion_video;
      default:
        return Icons.power;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getProgressColor().withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Power-up type and icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getProgressColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getPowerUpIcon(),
                      color: _getProgressColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getPowerUpString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(),
                    ),
                  ),
                ],
              ),
              // Time remaining counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getProgressColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getProgressColor().withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: _getProgressColor(),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${remainingTime}s',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 3D Progress Bar
          Stack(
            children: [
              // Background with 3D effect
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              // Progress indicator with gradient and shine effect
              SizedBox(
                height: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      // Main progress bar
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _getProgressColor().withOpacity(0.7),
                                _getProgressColor(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Shine effect
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}