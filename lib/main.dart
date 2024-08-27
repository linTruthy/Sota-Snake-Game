import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SnakeGame(),
    );
  }
}

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

enum Direction { up, down, left, right }

class _SnakeGameState extends State<SnakeGame> {
  static const int rows = 20;
  static const int columns = 20;
  static const int initialSnakeLength = 5;
  static const Duration snakeSpeed = Duration(milliseconds: 200);

  List<Point<int>> snake = [];
  Point<int>? food;
  Direction currentDirection = Direction.right;
  bool isGameOver = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  void resetGame() {
    snake.clear();
    for (int i = 0; i < initialSnakeLength; i++) {
      snake.add(Point(initialSnakeLength - i, 0));
    }
    currentDirection = Direction.right;
    generateFood();
    isGameOver = false;
    startGame();
  }

  void startGame() {
    timer = Timer.periodic(snakeSpeed, (Timer timer) {
      setState(() {
        moveSnake();
        if (isCollision()) {
          timer.cancel();
          isGameOver = true;
        } else {
          if (snake.first == food) {
            growSnake();
            generateFood();
          }
        }
      });
    });
  }

  void moveSnake() {
    Point<int> newHead;

    switch (currentDirection) {
      case Direction.up:
        newHead = Point(snake.first.x, snake.first.y - 1);
        break;
      case Direction.down:
        newHead = Point(snake.first.x, snake.first.y + 1);
        break;
      case Direction.left:
        newHead = Point(snake.first.x - 1, snake.first.y);
        break;
      case Direction.right:
        newHead = Point(snake.first.x + 1, snake.first.y);
        break;
    }

    snake.insert(0, newHead);
    snake.removeLast();
  }

  void growSnake() {
    snake.add(snake.last);
  }

  bool isCollision() {
    return snake.skip(1).contains(snake.first) ||
        snake.first.x < 0 ||
        snake.first.x >= columns ||
        snake.first.y < 0 ||
        snake.first.y >= rows;
  }

  void generateFood() {
    final random = Random();
    food = Point(random.nextInt(columns), random.nextInt(rows));
    while (snake.contains(food)) {
      food = Point(random.nextInt(columns), random.nextInt(rows));
    }
  }

  void changeDirection(Direction newDirection) {
    if ((currentDirection == Direction.up && newDirection != Direction.down) ||
        (currentDirection == Direction.down && newDirection != Direction.up) ||
        (currentDirection == Direction.left &&
            newDirection != Direction.right) ||
        (currentDirection == Direction.right &&
            newDirection != Direction.left)) {
      currentDirection = newDirection;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sota Snake Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                resetGame();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: columns / (rows + 2),
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy < 0) {
                  changeDirection(Direction.up);
                } else if (details.delta.dy > 0) {
                  changeDirection(Direction.down);
                }
              },
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx < 0) {
                  changeDirection(Direction.left);
                } else if (details.delta.dx > 0) {
                  changeDirection(Direction.right);
                }
              },
              child: GridView.builder(
                itemCount: rows * columns,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final x = index % columns;
                  final y = index ~/ columns;

                  final point = Point(x, y);
                  final isSnakeBody = snake.contains(point);
                  final isFood = point == food;

                  return Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isSnakeBody
                          ? Colors.green
                          : isFood
                              ? Colors.red
                              : Colors.black,
                    ),
                  );
                },
              ),
            ),
          ),
          if (isGameOver)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Game Over!',
                style: TextStyle(fontSize: 24, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
