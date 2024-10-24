import 'dart:math';
import 'package:flutter/material.dart';

import '../models/power_up.dart';

class SnakeGameBoard extends StatelessWidget {
  final int rows;
  final int columns;
  final List<Point<int>> snake;
  final Point<int>? food;
  final List<PowerUp> powerUps;
  final Duration snakeSpeed;
  final Function(DragUpdateDetails) onVerticalDragUpdate;
  final Function(DragUpdateDetails) onHorizontalDragUpdate;

  const SnakeGameBoard({
    super.key,
    required this.rows,
    required this.columns,
    required this.snake,
    required this.food,
    required this.powerUps,
    required this.snakeSpeed,
    required this.onVerticalDragUpdate,
    required this.onHorizontalDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive dimensions
        double gridSize = min(constraints.maxWidth, constraints.maxHeight);
        double cellSize = (gridSize - 32) / columns; // Account for padding

        return Container(
          // 3D Container with perspective effect
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: -5,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Add subtle perspective
              ..rotateX(0.05), // Slight tilt for 3D effect
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
                child: GestureDetector(
                  onVerticalDragUpdate: onVerticalDragUpdate,
                  onHorizontalDragUpdate: onHorizontalDragUpdate,
                  child: AspectRatio(
                    aspectRatio: columns / rows,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        childAspectRatio: 1,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: rows * columns,
                      itemBuilder: (context, index) {
                        final x = index % columns;
                        final y = index ~/ columns;
                        final point = Point(x, y);
                        
                        return GameCell(
                          point: point,
                          snake: snake,
                          food: food,
                          powerUps: powerUps,
                          snakeSpeed: snakeSpeed,
                          cellSize: cellSize,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GameCell extends StatelessWidget {
  final Point<int> point;
  final List<Point<int>> snake;
  final Point<int>? food;
  final List<PowerUp> powerUps;
  final Duration snakeSpeed;
  final double cellSize;

  const GameCell({
    super.key,
    required this.point,
    required this.snake,
    required this.food,
    required this.powerUps,
    required this.snakeSpeed,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    final isSnakeHead = point == snake.first;
    final isSnakeBody = snake.contains(point);
    final isFood = point == food;
    final isPowerUp = powerUps.any((p) => p.position == point);

    return AnimatedContainer(
      duration: snakeSpeed,
      curve: Curves.easeInOut,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..translate(0.0, 0.0, isSnakeHead ? 4.0 : 0.0),
        child: Container(
          margin: EdgeInsets.all(cellSize * 0.05),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getCellColors(isSnakeHead, isSnakeBody, isFood, isPowerUp),
            ),
            borderRadius: BorderRadius.circular(cellSize * 0.2),
            boxShadow: [
              BoxShadow(
                color: _getShadowColor(isSnakeHead, isSnakeBody, isFood, isPowerUp),
                blurRadius: isSnakeHead ? 8 : 4,
                spreadRadius: isSnakeHead ? 1 : 0,
                offset: Offset(0, isSnakeHead ? 3 : 2),
              ),
            ],
          ),
          child: _buildCellContent(isSnakeHead, isFood, isPowerUp, cellSize),
        ),
      ),
    );
  }

  List<Color> _getCellColors(bool isHead, bool isBody, bool isFood, bool isPowerUp) {
    if (isHead) {
      return [
        Colors.green[600]!,
        Colors.green[800]!,
      ];
    } else if (isBody) {
      return [
        Colors.green[400]!,
        Colors.green[600]!,
      ];
    } else if (isFood) {
      return [
        Colors.red[400]!,
        Colors.red[600]!,
      ];
    } else if (isPowerUp) {
      return [
        Colors.blue[400]!,
        Colors.blue[600]!,
      ];
    }
    return [
      Colors.grey[800]!,
      Colors.grey[900]!,
    ];
  }

  Color _getShadowColor(bool isHead, bool isBody, bool isFood, bool isPowerUp) {
    if (isHead) return Colors.green.withOpacity(0.5);
    if (isBody) return Colors.green.withOpacity(0.3);
    if (isFood) return Colors.red.withOpacity(0.3);
    if (isPowerUp) return Colors.blue.withOpacity(0.3);
    return Colors.black.withOpacity(0.2);
  }

  Widget _buildCellContent(bool isHead, bool isFood, bool isPowerUp, double size) {
    if (isHead) {
      return Center(
        child: Icon(
          Icons.pets,
          size: size * 0.5,
          color: Colors.white.withOpacity(0.7),
        ),
      );
    } else if (isFood) {
      return Center(
        child: Icon(
          Icons.apple,
          size: size * 0.4,
          color: Colors.white.withOpacity(0.7),
        ),
      );
    } else if (isPowerUp) {
      return Center(
        child: Icon(
          Icons.flash_on,
          size: size * 0.4,
          color: Colors.white.withOpacity(0.7),
        ),
      );
    }
    return const SizedBox();
  }
}