import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:easy_ads_flutter/easy_ads_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/gameover_dialog.dart';
import '../components/power_up_stack.dart';
import '../game_score_display.dart';
import '../models/daily_task.dart';
import '../models/power_up.dart';
import '../services/daily_task.dart';
import '../services/play_games_service.dart';
import '../services/score_manager.dart';
import '../services/username_service.dart';
import 'achievements_screen.dart';
import 'daily_task_screen.dart';
import 'leaderboard_screen.dart';
import '../services/leaderboard_service.dart';
import 'package:in_app_update/in_app_update.dart';

import 'settings_dialog.dart';
import 'snake_game_board.dart';

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> with TickerProviderStateMixin {
  Timer? _powerUpTimer;

  bool _flexibleUpdateAvailable = false;
//
  List<DailyTask> _activeTasks = [];
  Map<String, Timer> _powerUpTimers = {};
  List<PowerUp> _activePowerUps = [];
  Map<String, int> _remainingTimes = {};
  Map<String, Duration> _powerUpDurations = {};
  final ScoreManager _scoreManager = ScoreManager();
//
  Future<void> _checkForUpdate() async {
    InAppUpdate.checkForUpdate().then((info) {
      setState(() {
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
  //int score = 0;
  //int highScore = 0;
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
    setState(() {
      _activePowerUps.add(powerUp);
      _remainingTimes[powerUp.id] = powerUp.duration.inSeconds;
      _powerUpDurations[powerUp.id] = powerUp.duration;
    });

    // Apply power-up effect
    _applyPowerUpEffect(powerUp);

    // Start timer for this power-up
    _powerUpTimers[powerUp.id] =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTimes[powerUp.id]! > 0) {
          _remainingTimes[powerUp.id] = _remainingTimes[powerUp.id]! - 1;
        } else {
          _removePowerUp(powerUp);
          timer.cancel();
        }
      });
    });
  }

  void _applyPowerUpEffect(PowerUp powerUp) {
    switch (powerUp.type) {
      case 'speedBoost':
        snakeSpeed = snakeSpeed * 2;
        break;
      case 'scoreMultiplier':
        scoreMultiplier *= 2;
        break;
      case 'invincibility':
        isInvincible = true;
        break;
      case 'slowMotion':
        snakeSpeed = snakeSpeed ~/ 8;
        break;
    }
  }

  void _removePowerUp(PowerUp powerUp) {
    // Remove the power-up effect
    switch (powerUp.type) {
      case 'speedBoost':
        snakeSpeed = initialSnakeSpeed;
        break;
      case 'scoreMultiplier':
        scoreMultiplier ~/= 2;
        break;
      case 'invincibility':
        isInvincible = false;
        break;
      case 'slowMotion':
        snakeSpeed = initialSnakeSpeed;
        break;
    }

    setState(() {
      _activePowerUps.removeWhere((p) => p.id == powerUp.id);
      _remainingTimes.remove(powerUp.id);
      _powerUpDurations.remove(powerUp.id);
    });
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
  // late Animation<double> _levelUpAnimation;

  late AnimationController _highScoreAnimationController;
  //late Animation<double> _highScoreAnimation;

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
    _scoreManager.resetScore();
    _loadDailyTasks();
    EasyAds.instance.loadAd();
    _levelUpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _highScoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
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

  Future<void> _loadDailyTasks() async {
    final tasks = await DailyTaskService.getDailyTasks();
    setState(() {
      _activeTasks = tasks;
    });
  }

  void _updateTaskProgress() {
    if (_activeTasks.isEmpty) return;

    for (var task in _activeTasks) {
      if (task.isCompleted) continue;

      int progress = 0;
      switch (task.type) {
        case TaskType.score:
          progress = _scoreManager.currentScore;
          break;
        case TaskType.timeAlive:
          // Convert game time to seconds
          progress =
              (timer?.tick ?? 0) * (snakeSpeed.inMilliseconds / 1000).round();
          break;
        case TaskType.powerUps:
          // Count collected power-ups
          progress = _activePowerUps.length;
          break;
        case TaskType.foodEaten:
          // Calculate from snake length
          progress = snake.length - initialSnakeLength;
          break;
        case TaskType.levelReached:
          progress = level;
          break;
      }

      if (progress > 0) {
        DailyTaskService.updateTaskProgress(task.id, progress);
      }
    }
  }

  Future<void> loadInitialData() async {
    //final highScoreFuture = loadHighScore();
    final usernameFuture = _loadUsername();

    await Future.wait([usernameFuture]);
  }

  void startPowerUpAnimation() {
    _powerUpAnimationController.forward();
  }
  //

  Future<void> _loadUsername() async {
    final savedUsername = await UsernameService.getUsername();
    if (savedUsername == null) {
      _initializeUsername();
    } else {
      setState(() {
        username = savedUsername;
      });
    }
  }

  void _initializeUsername() async {
    String? username = await UsernameService.getUsername();

    if (username == null && mounted) {
      // Only show dialog if we couldn't get a username from Game Services
      username = await UsernameService.requestUsername(context);
    }

    if (username != null) {
      setState(() {
        this.username = username;
      });
    }
  }

  void _submitScore() async {
    final leaderboardService = LeaderboardService();
    final score = _scoreManager.currentScore;
    try {
      await leaderboardService.submitScore(username!, score);
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting score: $e');
      }
    }
  }

  // Future<void> loadHighScore() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     highScore = prefs.getInt('highScore') ?? 0;
  //     final score = _scoreManager.currentScore;
  //   });
  // }

  void endGame() {
    timer?.cancel();
    isGameOver = true;
    final score = _scoreManager.currentScore;
    _updateTaskProgress();
    final highScore = _scoreManager.highScore;
    if (score > highScore) {
      //  highScore = score;
      saveHighScore();
      showHighScoreEffect();
    }
    if (username != null) {
      _submitScore();
    }
    PlayGamesService().submitScore(score);
    playSound('game_over.wav');
    //showGameOverDialog();
    showInterstitialAd();
  }

  Future<void> saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    final highScore = _scoreManager.highScore;
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
     _scoreManager.resetScore();
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
    int score = _scoreManager.currentScore;
    _scoreManager.updateScore(score + 100);

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
          // Update tasks periodically (every 5 seconds)
          if (timer.tick % (5000 ~/ snakeSpeed.inMilliseconds) == 0) {
            _updateTaskProgress();
          }
          if (isCollision()) {
            timer.cancel();
            isGameOver = true;
            final score = _scoreManager.currentScore;
            final highScore = _scoreManager.highScore;
            if (score > highScore) {
              //  highScore = score;
              saveHighScore();
              showHighScoreEffect();
            }

            if (username != null) {
              _submitScore();
            }
            PlayGamesService().submitScore(score);
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
                _updateTaskProgress();
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
    int newScore = calculateNewScore(); // Your score calculation
    _scoreManager.updateScore(newScore);
  }

  void checkAndUnlockAchievements() {
    final score = _scoreManager.currentScore;
    if (score >= 100) {
      PlayGamesService().unlockAchievement('CgkIv-Wvj_EHEAIQAQ');
    }
    if (level >= 5) {
      PlayGamesService().unlockAchievement('YOUR_LEVEL_5_ACHIEVEMENT_ID');
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
    EasyAds.instance
        .showAd(AdUnitType.interstitial, adNetwork: AdNetwork.admob);
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

// Helper method to build menu items
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.grey[850]!.withOpacity(0.5),
                  Colors.grey[900]!.withOpacity(0.5),
                ],
              ),
              border: Border.all(
                color: Colors.grey[800]!.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.green[400], size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[900]!,
                  Colors.grey[850]!,
                  Colors.grey[900]!,
                ],
              ),
            ),
            child: Column(
              children: [
                // Profile Header
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green[900]!,
                        Colors.grey[900]!,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Animated Pattern Overlay
                      ...List.generate(
                        5,
                        (index) => AnimatedPositioned(
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeInOut,
                          child: Transform.rotate(
                            angle: pi / 4,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.05),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                  stops: const [0.4, 0.6],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Profile Content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green[400]!,
                                    Colors.green[600]!,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.person,
                                  size: 40, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              username ?? 'Guest',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[900]!.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Player Profile',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildMenuItem(
                        icon: CupertinoIcons.doc_checkmark,
                        title: 'Daily Tasks',
                        subtitle: 'New',
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DailyTasksScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: CupertinoIcons.settings,
                        title: 'Settings',
                        subtitle: isSoundMuted ? 'Sound: Off' : 'Sound: On',
                        onTap: () => _showSettingsDialog(context),
                      ),
                      _buildMenuItem(
                        icon: Icons.leaderboard_rounded,
                        title: 'Leaderboard',
                        subtitle: 'View top players',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LeaderboardScreen(username: username),
                          ),
                        ),
                      ),
                      _buildMenuItem(
                        icon: CupertinoIcons.person,
                        title: 'Profile',
                        subtitle: username ?? 'Guest',
                        onTap: _initializeUsername,
                      ),
                      _buildMenuItem(
                        icon: CupertinoIcons.heart,
                        title: 'Achievements',
                        subtitle: 'View your progress',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const EnhancedAchievementsScreen()),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: CupertinoIcons.info_circle,
                        title: 'How to Play',
                        subtitle: 'View your progress',
                        onTap: () => _showHowToPlayDialog(context),
                      ),
                    ],
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[800]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.games, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 8),
                          Text(
                            'Sota Snake v1.1.1',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Truthy Systems',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48), // Reduced height
          child: AppBar(
            automaticallyImplyLeading: false, // Disable default drawer button
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    Colors.black87,
                    Colors.green.shade900,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Menu Button wrapped in Builder
                    Builder(
                      builder: (BuildContext context) => IconButton(
                        icon: Icon(Icons.menu, color: Colors.green.shade400),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),

                    // Title and Username
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sota Snake',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade200,
                                ],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 200, 70)),
                          ),
                        ),
                        Text(
                          'Welcome, ${username ?? 'Guest'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade400.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Sound Toggle Button
                    IconButton(
                      icon: Icon(
                        isSoundMuted
                            ? CupertinoIcons.volume_off
                            : CupertinoIcons.volume_up,
                        color: isSoundMuted
                            ? Colors.red.shade400
                            : Colors.green.shade400,
                      ),
                      onPressed: toggleSound,
                    ),
                  ],
                ),
              ),
            ),
            elevation: 0, // Remove default shadow
          ),
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
              if (_activePowerUps.isEmpty)
                const EasySmartBannerAd(
                  priorityAdNetworks: [
                    AdNetwork.admob,
                    AdNetwork.unity,
                    AdNetwork.facebook,
                  ],
                  adSize: AdSize.banner,
                ),
              if (_activePowerUps.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: PowerUpStack(
                    powerUps: _activePowerUps,
                    remainingTimes: _remainingTimes,
                    durations: _powerUpDurations,
                  ),
                ),
              const SizedBox(height: 3),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GameScoreDisplay(
                  scoreManager: _scoreManager,
                  level: level,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: SnakeGameBoard(
                    rows: rows,
                    columns: columns,
                    snake: snake,
                    food: food,
                    powerUps: powerUps,
                    snakeSpeed: snakeSpeed,
                    onDirectionChange: (Direction newDirection) {
                      if (!isPaused && !isGameOver) {
                        setState(() {
                          changeDirection(newDirection);
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              if (!isGameOver || isPaused) ...[
                if (_activePowerUps.isEmpty)
                  const EasySmartBannerAd(
                    priorityAdNetworks: [
                      AdNetwork.admob,
                      AdNetwork.unity,
                      AdNetwork.facebook,
                    ],
                    adSize: AdSize.banner,
                  )
              ],
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
        bottomNavigationBar: Container(
          height: 68,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[900]!,
                Colors.grey[850]!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Top Glow Line
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.green.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main Content
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Leaderboard Button
                  _buildGlowingButton(
                    icon: CupertinoIcons.graph_circle_fill,
                    color: Colors.amber,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LeaderboardScreen(username: username),
                      ),
                    ),
                    glowColor: Colors.amber.withOpacity(0.3),
                  ),

                  // Center Play/Pause Button
                  Transform.translate(
                    offset: const Offset(0, -25),
                    child: _buildGlowingButton(
                      icon: isPaused
                          ? CupertinoIcons.play_arrow
                          : CupertinoIcons.pause,
                      color: Colors.green,
                      onTap: togglePause,
                      isLarge: true,
                      glowColor: Colors.green.withOpacity(0.3),
                    ),
                  ),

                  // Reset Button
                  _buildGlowingButton(
                    icon: CupertinoIcons.refresh,
                    color: Colors.blue,
                    onTap: () {
                      setState(() {
                        resetGame();
                      });
                    },
                    glowColor: Colors.blue.withOpacity(0.3),
                  ),
                ],
              ),

              // Bottom Glow Line
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.green.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildGlowingButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
    required Color glowColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isLarge ? 30 : 15),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isLarge ? 30 : 15),
          child: Container(
            padding: EdgeInsets.all(isLarge ? 20 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(isLarge ? 38 : 15),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: isLarge ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              size: isLarge ? 28 : 20,
              color: Colors.white,
            ),
          ),
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
    for (var timer in _powerUpTimers.values) {
      timer.cancel();
    }
    _powerUpTimers.clear();
    super.dispose();
  }

  void _showHowToPlayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'How to Play',
            style: TextStyle(color: Colors.green),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInstructionCard(
                  icon: Icons.swipe,
                  title: 'Controls',
                  description: 'Swipe in any direction to move the snake.',
                ),
                const SizedBox(height: 16),
                _buildInstructionCard(
                  icon: Icons.restaurant,
                  title: 'Eat Food',
                  description:
                      'Collect red food dots to grow longer and score points.',
                ),
                const SizedBox(height: 16),
                _buildInstructionCard(
                  icon: Icons.flash_on,
                  title: 'Power-ups',
                  description: 'Collect blue power-ups for special abilities.',
                ),
                const SizedBox(height: 16),
                _buildInstructionCard(
                  icon: Icons.warning,
                  title: 'Avoid Collisions',
                  description:
                      'Don\'t hit the snake\'s body or it\'s game over!',
                ),
                const SizedBox(height: 16),
                _buildInstructionCard(
                  icon: Icons.task_alt,
                  title: 'Daily Tasks',
                  description:
                      'Complete daily challenges to earn bonus points.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Got it!',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GameOverDialog(
          score: _scoreManager.currentScore,
          highScore: _scoreManager.highScore,
          onPlayAgain: () {
            Navigator.of(context).pop();
            setState(() {
              resetGame();
            });
          },
          onShowLeaderboard: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeaderboardScreen(username: username),
              ),
            );
          },
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EnhancedSettingsDialog(
          initialVolume: volume,
          initialMusicEnabled: isMusicEnabled,
          onVolumeChanged: (newVolume) {
            setState(() {
              volume = newVolume;
            });
          },
          onMusicToggled: (enabled) {
            setState(() {
              isMusicEnabled = enabled;
            });
          },
        );
      },
    );
  }

  // Revert effects and show snackbar when the power-up ends
  void endPowerUp(PowerUp powerUp) {
    setState(() {
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

  int calculateNewScore() {
    int score = _scoreManager.currentScore;
    score += (10 * scoreMultiplier) * level;
    _updateTaskProgress();
    if (score % 100 == 0) {
      level++;
      _updateTaskProgress();
      snakeSpeed = Duration(
          milliseconds:
              max(50, initialSnakeSpeed.inMilliseconds - (level - 1) * 20));
      timer?.cancel();
      startGame();
      showLevelUpEffect();
      playSound('level_up.wav');
      checkAndUnlockAchievements();
    }
    return score;
  }

  // Determine the progress bar color based on the remaining time
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
