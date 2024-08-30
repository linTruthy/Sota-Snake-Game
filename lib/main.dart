import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:easy_ads_flutter/easy_ads_flutter.dart';

const IAdIdManager adIdManager = TestAdIdManager();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyAds.instance.initialize(
    isShowAppOpenOnAppStateChange: false,
    adIdManager,
    unityTestMode: false,
    fbTestMode: false,
    adMobAdRequest: const AdRequest(),
    admobConfiguration: RequestConfiguration(
        testDeviceIds: ["73D83286C35132200529A93C555F5FD6"]),
    fbTestingId: 'd3b083f0-2987-4d05-a402-aba2011070f4',
    fbiOSAdvertiserTrackingEnabled: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sota Snake Game',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
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
  static const Duration initialSnakeSpeed = Duration(milliseconds: 200);

  List<Point<int>> snake = [];
  Point<int>? food;
  Direction currentDirection = Direction.right;
  bool isGameOver = false;
  bool isPaused = false;
  Timer? timer;
  int score = 0;
  int highScore = 0;
  int level = 1;
  Duration snakeSpeed = initialSnakeSpeed;

  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    loadHighScore();
    resetGame();
    EasyAds.instance.loadAd();
  }

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
  }

  void resetGame() {
    snake.clear();
    for (int i = 0; i < initialSnakeLength; i++) {
      snake.add(Point(initialSnakeLength - i, 0));
    }
    currentDirection = Direction.right;
    generateFood();
    isGameOver = false;
    isPaused = false;
    score = 0;
    level = 1;
    snakeSpeed = initialSnakeSpeed;
    startGame();
  }

  void startGame() {
    timer = Timer.periodic(snakeSpeed, (Timer timer) {
      if (!isPaused) {
        setState(() {
          moveSnake();
          if (isCollision()) {
            timer.cancel();
            isGameOver = true;
            if (score > highScore) {
              highScore = score;
              saveHighScore();
            }
            playSound('game_over.wav');
            showInterstitialAd();
          } else {
            if (snake.first == food) {
              growSnake();
              generateFood();
              increaseScore();
              playSound('eat.wav');
            }
          }
        });
      }
    });
  }

  void moveSnake() {
    Point<int> newHead;

    switch (currentDirection) {
      case Direction.up:
        newHead = Point(snake.first.x, (snake.first.y - 1 + rows) % rows);
        break;
      case Direction.down:
        newHead = Point(snake.first.x, (snake.first.y + 1) % rows);
        break;
      case Direction.left:
        newHead = Point((snake.first.x - 1 + columns) % columns, snake.first.y);
        break;
      case Direction.right:
        newHead = Point((snake.first.x + 1) % columns, snake.first.y);
        break;
    }

    snake.insert(0, newHead);
    snake.removeLast();
  }

  void growSnake() {
    snake.add(snake.last);
  }

  bool isCollision() {
    return snake.skip(1).contains(snake.first);
  }

  void generateFood() {
    final random = Random();
    do {
      food = Point(random.nextInt(columns), random.nextInt(rows));
    } while (snake.contains(food));
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

  void increaseScore() {
    score += 10 * level;
    if (score % 100 == 0) {
      level++;
      snakeSpeed = Duration(
          milliseconds:
              max(50, initialSnakeSpeed.inMilliseconds - (level - 1) * 20));
      timer?.cancel();
      startGame();
    }
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
    playSound('click.wav');
  }

  Future<void> playSound(String soundFile) async {
    await audioPlayer.play(AssetSource('sounds/$soundFile'));
  }

  void showInterstitialAd() {
    // EasyAds.instance.showInterstitialAd(
    //   adNetwork: AdNetwork.admob,
    //   adUnitId:
    //       'ca-app-pub-3940256099942544/1033173712', // Replace with your AdMob Interstitial Ad Unit ID
    // );
    EasyAds.instance.showAd(AdUnitType.interstitial);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sota Snake Game'),
        actions: [
          IconButton(
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: togglePause,
          ),
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
          const EasySmartBannerAd(
            priorityAdNetworks: [
              AdNetwork.admob,
              AdNetwork.unity,
              AdNetwork.facebook,
            ],
            adSize: AdSize.banner,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Score: $score', style: const TextStyle(fontSize: 18)),
                Text('High Score: $highScore',
                    style: const TextStyle(fontSize: 18)),
                Text('Level: $level', style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: columns / rows,
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
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final x = index % columns;
                    final y = index ~/ columns;

                    final point = Point(x, y);
                    final isSnakeHead = point == snake.first;
                    final isSnakeBody = snake.contains(point);
                    final isFood = point == food;

                    return Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSnakeHead
                            ? Colors.green[700]
                            : isSnakeBody
                                ? Colors.green
                                : isFood
                                    ? Colors.red
                                    : Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (!isGameOver)
            const EasySmartBannerAd(
            priorityAdNetworks: [
              AdNetwork.admob,
              AdNetwork.unity,
              AdNetwork.facebook,
            ],
            adSize: AdSize.fullBanner,
          ),
          if (isGameOver)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [

                  const Text(
                    'Game Over!',
                    style: TextStyle(fontSize: 24, color: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        resetGame();
                      });
                    },
                    child: const Text('Play Again'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 50), // Space for banner ad
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    audioPlayer.dispose();
    // EasyAds.instance.destroyAds()
    super.dispose();
  }
}
