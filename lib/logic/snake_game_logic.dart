import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/power_up.dart'; // Ensure you import your existing PowerUp model

enum Direction { up, down, left, right }

enum GameStatus { idle, playing, paused, gameOver }

class SnakeGameLogic extends ChangeNotifier {
  final int rows;
  final int columns;

  // Game State
  List<Point<int>> snake = [];
  Point<int>? food;
  List<PowerUp> powerUps = [];
  Direction currentDirection = Direction.right;
  GameStatus status = GameStatus.idle;

  // Input Buffer (Fixes the UX "Ghost Input" issue)
  final List<Direction> _inputQueue = [];

  Timer? _gameLoopTimer;
  Duration speed;
  int score = 0;

  // Callbacks for the UI to handle audio/ads
  final VoidCallback? onEatFood;
  final VoidCallback? onGameOver;
  final VoidCallback? onPowerUp;

  final VoidCallback? onTurn;

  SnakeGameLogic({
    required this.rows,
    required this.columns,
    this.speed = const Duration(milliseconds: 200),
    this.onEatFood,
    this.onGameOver,
    this.onPowerUp,
    this.onTurn,
  }) {
    reset();
  }

  void reset() {
    snake.clear();
    // Start in the middle
    final startX = columns ~/ 2;
    final startY = rows ~/ 2;
    for (int i = 0; i < 5; i++) {
      snake.add(Point(startX - i, startY));
    }

    currentDirection = Direction.right;
    status = GameStatus.idle;
    _inputQueue.clear();
    score = 0;
    _generateFood();
    notifyListeners();
  }

  void startGame() {
    if (status == GameStatus.playing) return;
    status = GameStatus.playing;
    _gameLoopTimer = Timer.periodic(speed, (timer) => _update());
    notifyListeners();
  }

  void pauseGame() {
    if (status == GameStatus.playing) {
      status = GameStatus.paused;
      _gameLoopTimer?.cancel();
      notifyListeners();
    }
  }

  void resumeGame() {
    if (status == GameStatus.paused) {
      status = GameStatus.playing;
      _gameLoopTimer = Timer.periodic(speed, (timer) => _update());
      notifyListeners();
    }
  }

  // Improved Input Handling
  void queueDirection(Direction newDirection) {
    if (status != GameStatus.playing) return;

    // Prevent filling queue too much
    if (_inputQueue.length >= 2) return;

    // Determine the last direction we plan to move
    Direction lastPlannedDir =
        _inputQueue.isEmpty ? currentDirection : _inputQueue.last;

    // Prevent 180-degree turns
    bool isOpposite = (lastPlannedDir == Direction.up &&
            newDirection == Direction.down) ||
        (lastPlannedDir == Direction.down && newDirection == Direction.up) ||
        (lastPlannedDir == Direction.left && newDirection == Direction.right) ||
        (lastPlannedDir == Direction.right && newDirection == Direction.left);

    if (!isOpposite && newDirection != lastPlannedDir) {
      _inputQueue.add(newDirection);
      onTurn?.call();
    }
  }

  void _update() {
    if (_inputQueue.isNotEmpty) {
      currentDirection = _inputQueue.removeAt(0);
    }

    _moveSnake();

    if (_checkCollision()) {
      _gameOver();
    } else {
      _checkFood();
      notifyListeners(); // Trigger the painter
    }
  }

  void _moveSnake() {
    Point<int> newHead;
    Point<int> currentHead = snake.first;

    switch (currentDirection) {
      case Direction.up:
        newHead = Point(currentHead.x, (currentHead.y - 1 + rows) % rows);
        break;
      case Direction.down:
        newHead = Point(currentHead.x, (currentHead.y + 1) % rows);
        break;
      case Direction.left:
        newHead = Point((currentHead.x - 1 + columns) % columns, currentHead.y);
        break;
      case Direction.right:
        newHead = Point((currentHead.x + 1) % columns, currentHead.y);
        break;
    }

    snake.insert(0, newHead);
    snake.removeLast();
  }

  void _checkFood() {
    if (snake.first == food) {
      snake.add(snake.last); // Grow
      score += 10;
      onEatFood?.call();
      _generateFood();
      // Logic for powerups generation can go here
    }
  }

  bool _checkCollision() {
    // Check if head hits body (skip head index 0)
    for (int i = 1; i < snake.length; i++) {
      if (snake[i] == snake.first) return true;
    }
    return false;
  }

  void _generateFood() {
    final random = Random();
    do {
      food = Point(random.nextInt(columns), random.nextInt(rows));
    } while (snake.contains(food));
  }

  void _gameOver() {
    status = GameStatus.gameOver;
    _gameLoopTimer?.cancel();
    onGameOver?.call();
    notifyListeners();
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    super.dispose();
  }
}
