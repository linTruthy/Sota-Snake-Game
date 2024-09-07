import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:easy_ads_flutter/easy_ads_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/username_dialog.dart';
import '../models/power_up.dart';
import '../services/play_games_service.dart';
import '../services/username_service.dart';
import 'leaderboard_screen.dart';
import '../services/leaderboard_service.dart';
import 'package:in_app_update/in_app_update.dart';

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

enum Direction { up, down, left, right }

class _SnakeGameState extends State<SnakeGame> with TickerProviderStateMixin {
  // AppUpdateInfo? _updateInfo;
  Timer? _powerUpTimer;
  int _remainingTime = 30; // Total time for power-up in seconds
  double _progress = 1.0; // Progress from 1.0 (full) to 0.0 (empty)
  bool _flexibleUpdateAvailable = false;

  Future<void> _checkForUpdate() async {
    InAppUpdate.checkForUpdate().then((info) {
      setState(() {
        //   _updateInfo = info;
        _flexibleUpdateAvailable = info.flexibleUpdateAllowed;
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          if (_flexibleUpdateAvailable) {
            InAppUpdate.performImmediateUpdate();
          } else {
            InAppUpdate.startFlexibleUpdate();
          }
        }
      });
    }).catchError((error) {
      if (kDebugMode) {
        print('Error checking for update: $error');
      }
    });
  }

  String? username;
  static const int rows = 20;
  static const int columns = 20;
  static const int initialSnakeLength = 5;
  static const Duration initialSnakeSpeed = Duration(milliseconds: 200);
  double taskProgress = 0.0;
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
  List<PowerUp> powerUps = [];

  void startRandomPowerUpGeneration() {
    final random = Random();

    // Generate random time between 10 to 30 seconds (or any range you prefer)
    int randomTime =
        random.nextInt(20) + 10; // Random time between 10 and 30 seconds

    // Start the timer with random delay
    Timer(Duration(seconds: randomTime), () {
      generatePowerUp(); // Generate power-up after random delay
      startRandomPowerUpGeneration(); // Schedule the next random power-up
    });
  }

  void generatePowerUp() {
    final random = Random();
    final position = Point(random.nextInt(columns), random.nextInt(rows));

    // Randomly choose between available power-ups
    List<String> powerUpTypes = [
      'speedBoost',
      'scoreMultiplier',
      'invincibility',
      'slowMotion'
    ];
    final type = powerUpTypes[random.nextInt(powerUpTypes.length)];

    powerUps.add(PowerUp(
        type: type, position: position, duration: const Duration(seconds: 40)));

    // Optionally, trigger any UI update or sound effect when a power-up is generated
    setState(() {
      // This will refresh the game screen with the new power-up
    });
  }

  int scoreMultiplier = 1;
  String? powerUpString;
  String powerUpType = 'speedBoost';
  void activatePowerUp(PowerUp powerUp) {
    isPowerUp = true;
    switch (powerUp.type) {
      case 'speedBoost':
        snakeSpeed = snakeSpeed * 2;
        break;
      case 'scoreMultiplier':
        scoreMultiplier = 2;
        break;
      case 'invincibility':
        isInvincible = true;
        break;
      case 'slowMotion':
        snakeSpeed = snakeSpeed ~/ 4;
        break;
    }
    powerUpString = powerUp.type;
    _remainingTime = powerUp.duration.inSeconds;
    _progress = 1.0;

    // Start the progress timer
    _powerUpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
          _progress = _remainingTime / powerUp.duration.inSeconds;
        });
      } else {
        timer.cancel();
        endPowerUp(powerUp);
      }
    });
    // Revert the effects after the duration
    // Timer(powerUp.duration, () {
    //   switch (powerUp.type) {
    //     case 'speedBoost':
    //       snakeSpeed = initialSnakeSpeed;
    //       break;

    //     case 'slowMotion':
    //       snakeSpeed = initialSnakeSpeed;
    //       break;
    //     case 'scoreMultiplier':
    //       scoreMultiplier = 1;
    //       break;
    //     case 'invincibility':
    //       isInvincible = false;
    //       break;
    //   }
    //   //cancel all other snackbars
    //   ScaffoldMessenger.of(context).clearSnackBars();
    //   //snackbar to show end of power up
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       behavior: SnackBarBehavior.floating,
    //       shape: RoundedRectangleBorder(
    //         borderRadius: BorderRadius.circular(10),
    //       ),
    //       backgroundColor: Colors.black,
    //       content: Center(
    //         child: Text('${powerUp.type} power up ended!',
    //             style: const TextStyle(color: Colors.yellow, fontSize: 16)),
    //       ),
    //       duration: const Duration(seconds: 2),
    //     ),
    //   );
    //   powerUps.remove(powerUp);
    //   isPowerUp = false;
    // });
  }

  void showPowerUpEffect(PowerUp powerUp) {
    _powerUpAnimationController.forward().then((_) {
      _powerUpAnimationController.reverse();
    });
    playSound('power_up.wav');
    //cancel all other snackbars
    ScaffoldMessenger.of(context).clearSnackBars();
    //show snackbar message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.green[800],
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flash_on, color: Colors.yellow),
            const SizedBox(width: 8),
            Text('${_getPowerUpString(powerUp.type)} activated!',
                style: const TextStyle(color: Colors.yellow, fontSize: 16)),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  final AudioPlayer audioPlayer = AudioPlayer();
  bool isSoundMuted = false;

  late AnimationController _levelUpAnimationController;
  late Animation<double> _levelUpAnimation;

  late AnimationController _highScoreAnimationController;
  late Animation<double> _highScoreAnimation;

  late AnimationController _powerUpAnimationController;
  late Animation<double> _powerUpAnimation;

  bool isPowerUp = false;

  bool isInvincible = false;

  var isMusicEnabled = true;
  double volume = 1;

  @override
  void initState() {
    super.initState();
    loadInitialData();
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
    _powerUpAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _powerUpAnimation =
        Tween<double>(begin: 1.0, end: 1.5).animate(CurvedAnimation(
      parent: _powerUpAnimationController,
      curve: Curves.easeInOut,
    ))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _powerUpAnimationController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              _powerUpAnimationController.forward();
            }
          });
    _powerUpAnimationController.forward();
    _checkForUpdate();
  }

  Future<void> loadInitialData() async {
    final highScoreFuture = loadHighScore();
    final usernameFuture = _loadUsername();

    await Future.wait([highScoreFuture, usernameFuture]);
  }

  void startPowerUpAnimation() {
    _powerUpAnimationController.forward();
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
    //showGameOverDialog();
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
    if (Random().nextInt(5) == 0 && powerUps.isEmpty) {
      powerUps.clear();
      generatePowerUp();
    }
    isPowerUp = false;
    powerUpType = 'speedBoost';
    scoreMultiplier = 1;
    taskProgress = 0.0;

    isGameOver = false;
    isPaused = false;
    score = 0;
    level = 1;
    snakeSpeed = initialSnakeSpeed;
    startGame();
    checkAndUnlockAchievements();
  }

  void checkDailyChallengeCompletion() {
    taskProgress += snakeSpeed.inSeconds;
    if (taskProgress >= 60) {
      // Complete the daily challenge
      rewardForDailyChallenge();
    }
  }

  void rewardForDailyChallenge() {
    score += 100; // Example reward
    //showDailyChallengeCompletionMessage();
    saveDailyChallengeCompletion();
  }

  void saveDailyChallengeCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('dailyChallengeCompleted', true);
    prefs.setString('lastCompletionDate', DateTime.now().toIso8601String());
  }

  void resetDailyChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastCompletionDate = prefs.getString('lastCompletionDate');
    if (lastCompletionDate != null) {
      DateTime lastCompletion = DateTime.parse(lastCompletionDate);
      if (DateTime.now().difference(lastCompletion).inDays >= 1) {
        prefs.setBool('dailyChallengeCompleted', false);
        taskProgress = 0.0;
      }
    }
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
            showGameOverDialog();
            showInterstitialAd();
          } else {
            if (snake.first == food) {
              growSnake();
              generateFood();
              if (Random().nextInt(5) == 0 && powerUps.isEmpty) {
                powerUps.clear();
                generatePowerUp();
              }

              increaseScore();
              playSound('eat.wav');
            }
            if (powerUps.isNotEmpty) {
              final powerUp = powerUps.first;
              if (snake.first == powerUp.position) {
                activatePowerUp(powerUp);
                powerUps.remove(powerUp);
              }
            }
            checkDailyChallengeCompletion();
          }
        });
      }
    });
  }

  void moveSnake() {
    Point<int> newHead = _calculateNewHeadPosition();
    setState(() {
      snake.insert(0, newHead);
      snake.removeLast();
    });
  }

  Point<int> _calculateNewHeadPosition() {
    switch (currentDirection) {
      case Direction.up:
        return Point(snake.first.x, (snake.first.y - 1 + rows) % rows);
      case Direction.down:
        return Point(snake.first.x, (snake.first.y + 1) % rows);
      case Direction.left:
        return Point((snake.first.x - 1 + columns) % columns, snake.first.y);
      case Direction.right:
        return Point((snake.first.x + 1) % columns, snake.first.y);
    }
  }

  void growSnake() {
    snake.add(snake.last);
  }

  bool isCollision() {
    // Only check for collision if not invincible
    if (!isInvincible) {
      return snake.skip(1).contains(snake.first);
    }
    return false;
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
    score += (10 * scoreMultiplier) * level;
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
      PlayGamesService.unlockAchievement('CgkIv-Wvj_EHEAIQAQ');
    }
    if (level >= 5) {
      PlayGamesService.unlockAchievement('YOUR_LEVEL_5_ACHIEVEMENT_ID');
    }
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
      audioPlayer.stop();
      audioPlayer.setVolume(volume);
      await audioPlayer.setSource(AssetSource('sounds/$soundFile'));
      await audioPlayer.resume();
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
      drawer: Drawer(
          elevation: 20,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                transform: const GradientRotation(45 * pi / 180),
                colors: [
                  const Scaffold().backgroundColor ?? Colors.black,
                  const Scaffold().backgroundColor ?? Colors.black,
                  const Scaffold().backgroundColor ?? Colors.black,
                  const Scaffold().backgroundColor ?? Colors.black,
                  const Scaffold().backgroundColor ?? Colors.black,
                  const Scaffold().backgroundColor ?? Colors.black,
                  const Scaffold().backgroundColor ?? Colors.black,
                  const Scaffold().backgroundColor ?? Colors.black,
                  Colors.green[900] ?? Colors.black,
                  Colors.green[700] ?? Colors.black,
                  Colors.green[400] ?? Colors.black,
                  Colors.green[200] ?? Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      DrawerHeader(
                        decoration: BoxDecoration(
                          color:
                              const Scaffold().backgroundColor ?? Colors.black,
                        ),
                        child: const Text(
                          'Sota Snake Game',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(CupertinoIcons.volume_up),
                        title: const Text('Settings'),
                        subtitle: Text(
                            isSoundMuted ? 'Sound: Off' : 'Sound: On',
                            style: TextStyle(
                                color: isSoundMuted ? Colors.red : Colors.green,
                                fontSize: 16)),
                        onTap: () {
                          _showSettingsDialog(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.leaderboard_rounded),
                        title: const Text('Leaderboard'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LeaderboardScreen(username: username),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(CupertinoIcons.person),
                        subtitle: Text(username ?? 'Guest'),
                        title: const Text('Profile'),
                        onTap: _promptForUsername,
                      ),
                      // ListTile(
                      //   leading: const Icon(CupertinoIcons.heart),
                      //   title: const Text('Achievements'),
                      //   onTap: () => PlayGamesService.showAchievements(),
                      // ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Developed by Truthy Systems',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          )),
      appBar: AppBar(
        title: const Text(
          'Sota Snake',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              transform: const GradientRotation(45 * pi / 180),
              colors: [
                const Scaffold().backgroundColor ?? Colors.black,
                const Scaffold().backgroundColor ?? Colors.black,
                const Scaffold().backgroundColor ?? Colors.black,
                const Scaffold().backgroundColor ?? Colors.black,
                const Scaffold().backgroundColor ?? Colors.black,
                Colors.green[800] ?? Colors.black,
                Colors.green[700] ?? Colors.black,
                Colors.green[400] ?? Colors.black,
                Colors.green[200] ?? Colors.black,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isSoundMuted
                  ? CupertinoIcons.volume_off
                  : CupertinoIcons.volume_up,
              color: Colors.white,
            ),
            onPressed: toggleSound,
          ),
          // IconButton(
          //   icon: Icon(
          //     isPaused ? CupertinoIcons.play_arrow : CupertinoIcons.pause,
          //     color: Colors.white,
          //   ),
          //   onPressed: togglePause,
          // ),
          // IconButton(
          //   icon: const Icon(CupertinoIcons.refresh, color: Colors.white),
          //   onPressed: () {
          //     setState(() {
          //       resetGame();
          //     });
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(Icons.leaderboard_rounded, color: Colors.white),
          //   onPressed: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) => LeaderboardScreen(username: username)),
          //   ),
          // ),
          // IconButton(
          //   icon: const Icon(CupertinoIcons.person, color: Colors.white),
          //   onPressed: _promptForUsername,
          // ),
        ],
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 10,
        onPressed: togglePause,
        backgroundColor: isPaused ? Colors.red : Colors.green,
        shape: const CircleBorder(),
        child: Icon(
          isPaused ? CupertinoIcons.play_arrow_solid : CupertinoIcons.pause,
          color: Colors.white,
        ),
      ),
      body: Stack(children: [
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
            if (isPowerUp)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_getPowerUpString(powerUpString),
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(
                          width: 3,
                        ),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: Colors.grey[500],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _getProgressColor()),
                              ),
                              CircleAvatar(
                                backgroundColor: _getProgressColor(),
                                radius: 15,
                                child: Text('${_remainingTime}s',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white60,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Score with fun icon and gradient text
                  Flexible(
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Score: $score',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              overflow:
                                  TextOverflow.ellipsis, // Prevent overflow
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: <Color>[
                                    Colors.orangeAccent,
                                    Colors.redAccent,
                                  ],
                                ).createShader(
                                  const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                                ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // High Score with animated scaling effect
                  Flexible(
                    child: AnimatedBuilder(
                      animation: _highScoreAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _highScoreAnimation.value,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emoji_events,
                                  color: Colors.yellow, size: 20),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '$highScore',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow
                                        .ellipsis, // Prevent overflow
                                    color: Colors.yellow,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Level Up with animated scaling and gradient text
                  Flexible(
                    child: AnimatedBuilder(
                      animation: _levelUpAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _levelUpAnimation.value,
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_upward,
                                  color: Colors.green, size: 20),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Level: $level',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow
                                        .ellipsis, // Prevent overflow
                                    foreground: Paint()
                                      ..shader = const LinearGradient(
                                        colors: <Color>[
                                          Colors.lightGreenAccent,
                                          Colors.green,
                                        ],
                                      ).createShader(
                                        const Rect.fromLTWH(
                                            0.0, 0.0, 200.0, 70.0),
                                      ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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
                  child: LayoutBuilder(builder: (context, constraints) {
                    double gridSize =
                        min(constraints.maxWidth, constraints.maxHeight);
                    return SizedBox(
                      width: gridSize,
                      height: gridSize,
                      child: GridView.builder(
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
                          final isFood = point == food;
                          return AnimatedContainer(
                              duration: snakeSpeed,
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: powerUps.any((p) => p.position == point)
                                    ? Colors.blueAccent.withOpacity(0.8)
                                    : isSnakeHead
                                        ? Colors.green[700]
                                        : isSnakeBody
                                            ? Colors.green[400]
                                            : isFood
                                                ? Colors.red
                                                : Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 3), // Shadow effect
                                  ),
                                ],
                              ));
                        },
                      ),
                    );
                  }),
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
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.deepOrange, // Text color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                            elevation: 8,
                          ),
                          onPressed: () {
                            setState(() {
                              resetGame();
                            });
                          },
                          child: const Text('Play Again'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (isPowerUp)
          Positioned(
            top: 10,
            left: 100,
            child: AnimatedBuilder(
              animation: _powerUpAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _powerUpAnimation.value,
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.yellow,
                    size: 24,
                  ),
                );
              },
            ),
          ),
      ]),
      bottomNavigationBar: BottomAppBar(
        height: 52,
        color: Colors.green[800],
        shape: const CircularNotchedRectangle(),
        notchMargin: 5.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.leaderboard_rounded, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        LeaderboardScreen(username: username)),
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {
                  resetGame();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    audioPlayer.dispose();

    _levelUpAnimationController.dispose();
    _highScoreAnimationController.dispose();
    _powerUpTimer?.cancel();
    _powerUpAnimationController.dispose();
    super.dispose();
  }

  showGameOverDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple[300],
          title:
              const Text('Game Over!', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You scored $score points!'),
              const EasySmartBannerAd(
                adSize: AdSize.banner,
                priorityAdNetworks: [
                  AdNetwork.admob,
                  AdNetwork.unity,
                  AdNetwork.facebook,
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              child: const Text('Leaderboard'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        LeaderboardScreen(username: username)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                setState(() {
                  resetGame();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Volume'),
                  Expanded(
                    child: Slider(
                      value: volume,
                      onChanged: (newVolume) {
                        setState(() {
                          volume = newVolume;
                        });
                      },
                      min: 0.0,
                      max: 1.0,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Background Music'),
                  CupertinoSwitch(
                    value: isMusicEnabled,
                    onChanged: (value) {
                      setState(() {
                        isMusicEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Revert effects and show snackbar when the power-up ends
  void endPowerUp(PowerUp powerUp) {
    setState(() {
      _progress = 0.0;
      isPowerUp = false;
    });
    switch (powerUp.type) {
      case 'speedBoost':
        snakeSpeed = initialSnakeSpeed;
        break;
      case 'scoreMultiplier':
        scoreMultiplier = 1;
        break;
      case 'invincibility':
        isInvincible = false;
        break;
      case 'slowMotion':
        snakeSpeed = initialSnakeSpeed;
        break;
    }

    // Clear all snackbars and show a message indicating power-up end
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.black,
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flash_off, color: Colors.redAccent),
            Text('${_getPowerUpString(powerUp.type)} power-up ended!',
                style: const TextStyle(color: Colors.yellow, fontSize: 16)),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    powerUps.remove(powerUp);
  }

  // Determine the progress bar color based on the remaining time
  Color _getProgressColor() {
    if (_remainingTime >= 20) {
      return Colors.green;
    } else if (_remainingTime >= 10) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

String _getPowerUpString(dynamic powerUpString) {
  switch (powerUpString) {
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
