import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:easy_ads_flutter/easy_ads_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

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

enum MultiplayerMode { none, bluetooth, online }

class PowerUp {
  final Point<int> position;
  final PowerUpType type;

  PowerUp(this.position, this.type);
}

enum PowerUpType {
  speedBoost,
  scoreMultiplier,
  invincibility,
}

class Obstacle {
  final Point<int> position;

  Obstacle(this.position);
}

class _SnakeGameState extends State<SnakeGame> with TickerProviderStateMixin {
  String? username;
  static const int rows = 20;
  static const int columns = 20;
  static const int initialSnakeLength = 5;
  static const Duration initialSnakeSpeed = Duration(milliseconds: 200);
//
  MultiplayerMode _multiplayerMode = MultiplayerMode.none;
  List<Point<int>> _opponentSnake = [];
  // BluetoothConnection? _bluetoothConnection;
  WebSocketChannel? _webSocketChannel;
  //
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

  // New variables for special effects
  int consecutiveEats = 0;
  DateTime? lastEatTime;
  bool isBoostActive = false;
  Timer? boostTimer;
  late AnimationController _boostOverlayController;
  late Animation<double> _boostOverlayAnimation;
  late AnimationController _boostProgressController;
  late Animation<double> _boostProgressAnimation;
  late AnimationController _scoreIncrementController;
  late Animation<double> _scoreIncrementAnimation;
  int lastScore = 0;

  List<PowerUp> powerUps = [];
  List<Obstacle> obstacles = [];
  bool isInvincible = false;
  Timer? invincibilityTimer;
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
    _boostOverlayController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _boostOverlayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _boostOverlayController, curve: Curves.easeInOut),
    );

    _boostProgressController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _boostProgressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _boostProgressController, curve: Curves.linear),
    );

    _scoreIncrementController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scoreIncrementAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
          parent: _scoreIncrementController, curve: Curves.easeInOut),
    );
    generatePowerUp();
    generateObstacle();
  }

  void generatePowerUp() {
    if (powerUps.length < 2) {
      // Limit to 2 power-ups on screen
      final random = Random();
      final powerUpType =
          PowerUpType.values[random.nextInt(PowerUpType.values.length)];
      Point<int> position;
      do {
        position = Point(random.nextInt(columns), random.nextInt(rows));
      } while (snake.contains(position) ||
          food == position ||
          powerUps.any((pu) => pu.position == position) ||
          obstacles.any((o) => o.position == position));
      powerUps.add(PowerUp(position, powerUpType));
    }
  }

  void generateObstacle() {
    if (obstacles.length < level) {
      // Number of obstacles increases with level
      final random = Random();
      Point<int> position;
      do {
        position = Point(random.nextInt(columns), random.nextInt(rows));
      } while (snake.contains(position) ||
          food == position ||
          powerUps.any((pu) => pu.position == position) ||
          obstacles.any((o) => o.position == position));
      obstacles.add(Obstacle(position));
    }
  }

  //
  void startMultiplayerGame(MultiplayerMode mode) {
    setState(() {
      _multiplayerMode = mode;
      resetGame();
    });

    if (mode == MultiplayerMode.bluetooth) {
      //  _initializeBluetoothConnection();
    } else if (mode == MultiplayerMode.online) {
      _initializeOnlineConnection();
    }
  }

  void _initializeOnlineConnection() {
    final wsUrl = Uri.parse('wss://your-websocket-server.com');
    _webSocketChannel = IOWebSocketChannel.connect(wsUrl);
    _webSocketChannel!.stream.listen(_handleIncomingWebSocketData);
  }

  void _handleIncomingWebSocketData(dynamic data) {
    _updateOpponentSnake(data as String);
  }

  void _updateOpponentSnake(String data) {
    List<String> parts = data.split(',');
    setState(() {
      _opponentSnake = parts.map((part) {
        List<String> coordinates = part.split(':');
        return Point(int.parse(coordinates[0]), int.parse(coordinates[1]));
      }).toList();
    });
  }
  //

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
    if (_multiplayerMode != MultiplayerMode.none) {
      _sendSnakePosition();
    }
    if (snake.first == food) {
      growSnake();
      generateFood();
      increaseScore();
      playSound('eat.wav');
      checkConsecutiveEats();
      generatePowerUp();
      generateObstacle();
    }

    // Check for power-up collision
    final collidedPowerUp = powerUps.firstWhere(
        (pu) => pu.position == snake.first,
        orElse: () => PowerUp(const Point(-1, -1), PowerUpType.speedBoost));
    if (collidedPowerUp.position != const Point(-1, -1)) {
      activatePowerUp(collidedPowerUp);
      powerUps.remove(collidedPowerUp);
      generatePowerUp();
    }

    // Check for obstacle collision
    if (obstacles.any((o) => o.position == snake.first) && !isInvincible) {
      endGame();
    }
  }

  void activatePowerUp(PowerUp powerUp) {
    switch (powerUp.type) {
      case PowerUpType.speedBoost:
        activateSpeedBoost();
        break;
      case PowerUpType.scoreMultiplier:
        activateBoost();
        break;
      case PowerUpType.invincibility:
        activateInvincibility();
        break;
    }
    playSound('power_up.wav');
  }

  void activateSpeedBoost() {
    final currentSpeed = snakeSpeed.inMilliseconds;
    snakeSpeed = Duration(milliseconds: (currentSpeed * 0.75).round());
    timer?.cancel();
    startGame();
    Future.delayed(const Duration(seconds: 5), () {
      snakeSpeed = Duration(milliseconds: currentSpeed);
      timer?.cancel();
      startGame();
    });
  }

  void activateInvincibility() {
    setState(() {
      isInvincible = true;
    });
    invincibilityTimer?.cancel();
    invincibilityTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        isInvincible = false;
      });
    });
  }

  void checkConsecutiveEats() {
    final now = DateTime.now();
    if (lastEatTime != null && now.difference(lastEatTime!).inSeconds <= 60) {
      consecutiveEats++;
      if (consecutiveEats == 3) {
        activateBoost();
      }
    } else {
      consecutiveEats = 1;
    }
    lastEatTime = now;
  }

  void activateBoost() {
    setState(() {
      isBoostActive = true;
      lastScore = score;
    });
    showBoostOverlay();
    playSound('boost_activated.wav');
    boostTimer?.cancel();
    _boostProgressController.forward(from: 0.0);
    boostTimer = Timer(const Duration(seconds: 10), deactivateBoost);
  }

  void deactivateBoost() {
    setState(() {
      isBoostActive = false;
      consecutiveEats = 0;
    });
    _boostProgressController.stop();
    playSound('boost_deactivated.wav');
  }

  void showBoostOverlay() {
    _boostOverlayController.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        _boostOverlayController.reverse();
      });
    });
  }

  void increaseScore() {
    int baseScore = 10 * level;
    if (isBoostActive) {
      baseScore *= 2; // Double score during boost
    }
    setState(() {
      score += baseScore;
    });
    if (isBoostActive) {
      _scoreIncrementController
          .forward(from: 0.0)
          .then((_) => _scoreIncrementController.reverse());
    }
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

  void _sendSnakePosition() {
    String positionData = snake.map((p) => '${p.x}:${p.y}').join(',');

    if (_multiplayerMode == MultiplayerMode.bluetooth) {
      //  _bluetoothConnection?.output
      //   .add(Uint8List.fromList(positionData.codeUnits));
    } else if (_multiplayerMode == MultiplayerMode.online) {
      _webSocketChannel?.sink.add(positionData);
    }
  }

  void growSnake() {
    snake.add(snake.last);
  }

  bool isCollision() {
    return (snake.skip(1).contains(snake.first) ||
            (obstacles.any((o) => o.position == snake.first) &&
                !isInvincible)) &&
        (_multiplayerMode != MultiplayerMode.none &&
            _opponentSnake.contains(snake.first));
  }

  void generateFood() {
    final random = Random();
    do {
      food = Point(random.nextInt(columns), random.nextInt(rows));
    } while (snake.contains(food) || _opponentSnake.contains(food));
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

  void checkAndUnlockAchievements() {
    if (score >= 100) {
      PlayGamesService.unlockAchievement('CgkIv-Wvj_EHEAIQAQ');
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
            icon: Icon(isSoundMuted
                ? CupertinoIcons.volume_off
                : CupertinoIcons.volume_up),
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
          IconButton(
            icon: const Icon(CupertinoIcons.chart_bar_alt_fill),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LeaderboardScreen()),
            ),
            // PlayGamesService.showLeaderboard,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.person),
            onPressed: _promptForUsername,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
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
                    AnimatedBuilder(
                      animation: _scoreIncrementAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: isBoostActive
                              ? _scoreIncrementAnimation.value
                              : 1.0,
                          child: Text(
                            'Score: $score',
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  isBoostActive ? Colors.yellow : Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _highScoreAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _highScoreAnimation.value,
                          child: Text(
                            'High Score: $highScore',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.yellow),
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
              if (isBoostActive)
                AnimatedBuilder(
                  animation: _boostProgressAnimation,
                  builder: (context, child) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: LinearProgressIndicator(
                        value: _boostProgressAnimation.value,
                        backgroundColor: Colors.grey[800],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.yellow),
                      ),
                    );
                  },
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
                    child: Stack(
                      children: [
                        GridView.builder(
                          itemCount: rows * columns,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            final x = index % columns;
                            final y = index ~/ columns;
                            final point = Point(x, y);

                            final isSnakeHead = point == snake.first;
                            final isSnakeBody = snake.contains(point);
                            final isOpponentSnake =
                                _opponentSnake.contains(point);
                            final isFood = point == food;
                            final powerUp = powerUps.firstWhere(
                                (pu) => pu.position == point,
                                orElse: () => PowerUp(const Point(-1, -1),
                                    PowerUpType.speedBoost));
                            final isObstacle =
                                obstacles.any((o) => o.position == point);

                            Color cellColor = Colors.grey[800]!;
                            if (isSnakeHead) {
                              cellColor = isInvincible
                                  ? Colors.purple
                                  : Colors.green[700]!;
                            } else if (isSnakeBody) {
                              cellColor = isInvincible
                                  ? Colors.purpleAccent
                                  : Colors.green;
                            } else if (isOpponentSnake) {
                              cellColor = Colors.grey.withOpacity(0.5);
                            } else if (isFood) {
                              cellColor = Colors.red;
                            } else if (powerUp.position !=
                                const Point(-1, -1)) {
                              switch (powerUp.type) {
                                case PowerUpType.speedBoost:
                                  cellColor = Colors.blue;
                                  break;
                                case PowerUpType.scoreMultiplier:
                                  cellColor = Colors.yellow;
                                  break;
                                case PowerUpType.invincibility:
                                  cellColor = Colors.purple;
                                  break;
                              }
                            } else if (isObstacle) {
                              cellColor = Colors.orange;
                            }

                            return Container(
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: cellColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          },
                        ),
                        if (isBoostActive)
                          Container(
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.yellow, width: 4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              if (!isGameOver || isPaused)
                const EasySmartBannerAd(
                  priorityAdNetworks: [
                    AdNetwork.admob,
                    AdNetwork.unity,
                    AdNetwork.facebook,
                  ],
                  adSize: AdSize.largeBanner,
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
          AnimatedBuilder(
            animation: _boostOverlayAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _boostOverlayAnimation.value,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.yellow, size: 50),
                        SizedBox(height: 10),
                        Text(
                          'BOOST ACTIVATED!',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '2x Score for 10 seconds',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
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
    //_bluetoothConnection?.close();
    _webSocketChannel?.sink.close();
    _boostOverlayController.dispose();
    _boostProgressController.dispose();
    _scoreIncrementController.dispose();
    boostTimer?.cancel();
    invincibilityTimer?.cancel();
    super.dispose();
  }
}
