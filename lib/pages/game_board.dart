
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/power_up.dart';

enum Direction { up, down, left, right }

class SnakeGameBoard extends StatefulWidget {
  final int rows;
  final int columns;
  final List<Point<int>> snake;
  final Point<int>? food;
  final List<PowerUp> powerUps;
  final Duration snakeSpeed;
  final void Function(Direction) onDirectionChange; // Updated type signature

  const SnakeGameBoard({
    super.key,
    required this.rows,
    required this.columns,
    required this.snake,
    required this.food,
    required this.powerUps,
    required this.snakeSpeed,
    required this.onDirectionChange,
  });

  @override
  State<SnakeGameBoard> createState() => _SnakeGameBoardState();
}

class _SnakeGameBoardState extends State<SnakeGameBoard> {
  static const double minSwipeDistance = 10.0;
  static const double diagonalThreshold = 0.5;

  Offset? _startPosition;
  Direction? _lastDirection;
  DateTime _lastDirectionChange = DateTime.now();

  static const debounceDuration = Duration(milliseconds: 100);

  void _handlePanStart(DragStartDetails details) {
    _startPosition = details.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_startPosition == null) return;

    if (DateTime.now().difference(_lastDirectionChange) < debounceDuration) {
      return;
    }

    final dx = details.localPosition.dx - _startPosition!.dx;
    final dy = details.localPosition.dy - _startPosition!.dy;

    if (dx.abs() < minSwipeDistance && dy.abs() < minSwipeDistance) {
      return;
    }

    final absDx = dx.abs();
    final absDy = dy.abs();

    final isDiagonal = (absDx / absDy).abs() > (1 - diagonalThreshold) &&
        (absDx / absDy).abs() < (1 + diagonalThreshold);

    Direction? newDirection;

    if (!isDiagonal) {
      if (absDx > absDy) {
        newDirection = dx > 0 ? Direction.right : Direction.left;
      } else {
        newDirection = dy > 0 ? Direction.down : Direction.up;
      }
    } else {
      if (absDx > absDy) {
        newDirection = dx > 0 ? Direction.right : Direction.left;
      } else {
        newDirection = dy > 0 ? Direction.down : Direction.up;
      }
    }

    if (newDirection != null && newDirection != _lastDirection) {
      _lastDirection = newDirection;
      _lastDirectionChange = DateTime.now();
      widget.onDirectionChange(newDirection);
      _startPosition = details.localPosition;
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _startPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: LayoutBuilder(
        builder: (context, constraints) {
          double gridSize = min(constraints.maxWidth, constraints.maxHeight);
          double cellSize = (gridSize - 32) / widget.columns;

          return Container(
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
                ..setEntry(3, 2, 0.001)
                ..rotateX(0.05),
              alignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: widget.columns / widget.rows,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.columns,
                    childAspectRatio: 1,
                  ),
                  itemCount: widget.rows * widget.columns,
                  itemBuilder: (context, index) {
                    final x = index % widget.columns;
                    final y = index ~/ widget.columns;
                    final point = Point(x, y);

                    return GameCell(
                      point: point,
                      snake: widget.snake,
                      food: widget.food,
                      powerUps: widget.powerUps,
                      snakeSpeed: widget.snakeSpeed,
                      cellSize: cellSize,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
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
      decoration: BoxDecoration(
        color: _getCellColor(isSnakeHead, isSnakeBody, isFood, isPowerUp),
        borderRadius: BorderRadius.circular(4),
      ),
      margin: const EdgeInsets.all(1),
    );
  }

  Color _getCellColor(bool isHead, bool isBody, bool isFood, bool isPowerUp) {
    if (isHead) return Colors.green;
    if (isBody) return Colors.green[700]!;
    if (isFood) return Colors.red;
    if (isPowerUp) return Colors.blue;
    return Colors.grey[900]!;
  }
}
