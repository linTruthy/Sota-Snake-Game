import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:easy_ads_flutter/easy_ads_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/username_dialog.dart';
import '../services/play_games_service.dart';
import '../services/username_service.dart';
import 'leaderboard_screen.dart';
import '../services/leaderboard_service.dart';

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

enum Direction { up, down, left, right }

class _SnakeGameState extends State<SnakeGame> with TickerProviderStateMixin {
  String? username;
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
  bool isSoundMuted = false;

  late AnimationController _levelUpAnimationController;
  late Animation<double> _levelUpAnimation;

  late AnimationController _highScoreAnimationController;
  late Animation<double> _highScoreAnimation;

  @override
  void initState() {
    super.initState();
    loadHighScore();
    resetGame();
    EasyAds.instance.loadAd();
    _levelUpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _levelUpAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
          parent: _levelUpAnimationController, curve: Curves.easeInOut),
    );

    _highScoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _highScoreAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
          parent: _highScoreAnimationController, curve: Curves.easeInOut),
    );
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final savedUsername = await UsernameService.getUsername();
    if (savedUsername == null) {
      _promptForUsername();
    } else {
      setState(() {
        username = savedUsername;
      });
    }
  }

  Future<void> _promptForUsername() async {
    final newUsername = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return UsernameDialog(initialUsername: username);
      },
    );

    if (newUsername != null && newUsername.isNotEmpty) {
      setState(() {
        username = newUsername;
      });
      await UsernameService.setUsername(newUsername);
    }
  }

  void _submitScore() async {
    final leaderboardService = LeaderboardService();
    try {
      await leaderboardService.submitScore(username!, score);
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting score: $e');
      }
    }
  }

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  void endGame() {
    timer?.cancel();
    isGameOver = true;
    if (score > highScore) {
      highScore = score;
      saveHighScore();
      showHighScoreEffect();
    }
    if (username != null) {
      _submitScore();
    }
    PlayGamesService.submitScore(score);
    playSound('game_over.wav');
    showInterstitialAd();
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
    checkAndUnlockAchievements();
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
              showHighScoreEffect();
            }

            if (username != null) {
              _submitScore();
            }
            PlayGamesService.submitScore(score);
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
      showLevelUpEffect();
      playSound('level_up.wav');
      checkAndUnlockAchievements();
    }
  }

  void checkAndUnlockAchievements() {
    if (score >= 100) {
      PlayGamesService.unlockAchievement('Cgklv-Wvj_EHEAIQAQ');
    }
    if (level >= 5) {
      PlayGamesService.unlockAchievement('YOUR_LEVEL_5_ACHIEVEMENT_ID');
    }
    // Add more achievements as needed
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
    playSound('click.wav');
  }

  void toggleSound() {
    setState(() {
      isSoundMuted = !isSoundMuted;
    });
  }

  Future<void> playSound(String soundFile) async {
    if (!isSoundMuted) {
      await audioPlayer.play(AssetSource('sounds/$soundFile'));
    }
  }

  void showInterstitialAd() {
    // EasyAds.instance.showInterstitialAd(
    //   adNetwork: AdNetwork.admob,
    //   adUnitId:
    //       'ca-app-pub-3940256099942544/1033173712', // Replace with your AdMob Interstitial Ad Unit ID
    // );
    EasyAds.instance.showAd(AdUnitType.interstitial);
  }

  void showLevelUpEffect() {
    _levelUpAnimationController
        .forward()
        .then((_) => _levelUpAnimationController.reverse());
  }

  void showHighScoreEffect() {
    _highScoreAnimationController
        .forward()
        .then((_) => _highScoreAnimationController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sota Snake'),
        actions: [
          IconButton(
            icon: Icon(
                isSoundMuted ? CupertinoIcons.volume_off : CupertinoIcons.volume_up),
            onPressed: toggleSound,
          ),
          IconButton(
            icon: Icon(
                isPaused ? CupertinoIcons.play_arrow : CupertinoIcons.pause),
            onPressed: togglePause,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: () {
              setState(() {
                resetGame();
              });
            },
          ),
          const IconButton(
            icon: Icon(Icons.leaderboard),
            onPressed: PlayGamesService.showLeaderboard,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.person),
            onPressed: _promptForUsername,
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
                AnimatedBuilder(
                  animation: _highScoreAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _highScoreAnimation.value,
                      child: Text(
                        'High Score: $highScore',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.yellow),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _levelUpAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _levelUpAnimation.value,
                      child: Text(
                        'Level: $level',
                        style: const TextStyle(
                            fontSize: 18, color: Colors.lightGreen),
                      ),
                    );
                  },
                ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            resetGame();
                          });
                        },
                        child: const Text('Play Again'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LeaderboardScreen()),
                          );
                        },
                        child: const Text('View Leaderboard'),
                      ),
                    ],
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
    _levelUpAnimationController.dispose();
    _highScoreAnimationController.dispose();
    super.dispose();
  }
}
