import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
//import 'package:easy_ads_flutter/easy_ads_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/game_controls.dart';
import '../components/gameover_dialog.dart';
import '../components/game_score_display.dart';
import '../logic/snake_game_logic.dart';
import '../models/daily_task.dart';
import '../models/power_up.dart';
import '../services/daily_task.dart';
import '../services/feedback_manager.dart';
import '../services/play_games_service.dart';
import '../services/score_manager.dart';
import '../services/username_service.dart';
import 'leaderboard_screen.dart';
import '../services/leaderboard_service.dart';
import 'package:in_app_update/in_app_update.dart';

import '../components/settings_dialog.dart';
import 'game_board.dart';

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> with TickerProviderStateMixin {
  Timer? _powerUpTimer;

  bool _flexibleUpdateAvailable = false;
//
  int _foodEatenCount = 0;
  List<DailyTask> _activeTasks = [];
  Map<String, Timer> _powerUpTimers = {};
  List<PowerUp> _activePowerUps = [];
  Map<String, int> _remainingTimes = {};
  Map<String, Duration> _powerUpDurations = {};
  final ScoreManager _scoreManager = ScoreManager();
  late ConfettiController _taskConfettiController;
  bool _showTaskCompletionBanner = false;
  String _completedTaskTitle = '';
  Timer? _bannerTimer;
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

  late SnakeGameLogic _gameLogic;

  @override
  void initState() {
    super.initState();
    FeedbackManager().initialize();
    _gameLogic = SnakeGameLogic(
        rows: 20,
        columns: 20,
        onEatFood: () {
          _scoreManager.updateScore(_gameLogic.score);
          FeedbackManager().eat(); // Sound + Medium Haptic
        },
        onGameOver: () {
          FeedbackManager().gameOver(); // Heavy Haptic + Sound
          showGameOverDialog();
        },
        onPowerUp: () {
          FeedbackManager().powerUp();
          // ... show visual effect logic
        },
        onTurn: () {
          // Only haptic on manual input, logic handles this via queueDirection
          // But if you want vibration EXACTLY when the button is pressed,
          // handle it in the UI widget (GestureDetector/Dpad).
          // If you want it when the snake actually TURNS, put it here.
          // Recommendation: Handle it on BUTTON PRESS (UI layer) for instant feedback.
        });

    loadInitialData();
    resetGame();
    _scoreManager.resetScore();
    _loadDailyTasks();
 //   EasyAds.instance.loadAd();
    _taskConfettiController =
        ConfettiController(duration: const Duration(seconds: 2));
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

  void _showTaskCompletion(DailyTask task) {
    setState(() {
      _showTaskCompletionBanner = true;
      _completedTaskTitle = task.title;
    });

    _taskConfettiController.play();
    playSound('level_up.wav'); // Reuse existing success sound

    // Clear any existing banner timer
    _bannerTimer?.cancel();

    // Auto-hide banner after 3 seconds
    _bannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showTaskCompletionBanner = false;
        });
      }
    });

    // Check if all tasks are complete
    if (_activeTasks.every((task) => task.isCompleted)) {
      _showAllTasksCompleted();
    }
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
          final score = _scoreManager.currentScore;
          progress = score;
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
          // Use the dedicated food eaten counter
          progress = _foodEatenCount;
          break;
        case TaskType.levelReached:
          progress = level;
          break;
      }

      // Ensure progress doesn't exceed target
      progress = min(progress, task.target);

      if (progress > 0 && progress != task.progress) {
        DailyTaskService.updateTaskProgress(task.id, progress);
      }
      if (progress >= task.target && !task.isCompleted) {
        _showTaskCompletion(task);
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
   // showInterstitialAd();
  }

  Future<void> saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    final highScore = _scoreManager.highScore;
    await prefs.setInt('highScore', highScore);
  }

  void resetGame() {
    _foodEatenCount = 0;
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
            //showInterstitialAd();
          } else {
            if (snake.first == food) {
              growSnake();
              generateFood();
              _foodEatenCount++;
              if (Random().nextInt(5) == 0 && powerUps.isEmpty) {
                powerUps.clear();
                generatePowerUp();
              }

              increaseScore();
              _updateTaskProgress();
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

  // void showInterstitialAd() {
  //   EasyAds.instance
  //       .showAd(AdUnitType.interstitial, adNetwork: AdNetwork.admob);
  // }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Title and Username

            ListenableBuilder(
                listenable: _gameLogic,
                builder: (context, _) {
                  return GameScoreDisplay(
                    scoreManager:
                        _scoreManager, // Update ScoreManager to pull from logic or sync them
                    level: 1, // You can add level logic to the class later
                  );
                }),
            Expanded(
              flex: 3, // Give board 3/5ths of space
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SnakeGameBoard(gameLogic: _gameLogic),
              ),
            ),
            Expanded(
              flex: 2, // Give controls 2/5ths of space
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Only show D-Pad if user prefers it (or maybe screen is big enough)
                  // You can wrap this in a Visibility widget controlled by Settings
                  GameDpad(
                    onDirectionChanged: (direction) {
                      // Haptic is handled inside the Dpad button itself
                      _gameLogic.queueDirection(direction);
                    },
                  ),

                  const SizedBox(height: 10),

                  // Play/Pause/Restart Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildGameButton(
                          icon: Icons.refresh,
                          onTap: () {
                            FeedbackManager().buttonClick();
                            _gameLogic.reset();
                          }),
                      _buildGameButton(
                          icon: Icons.play_arrow_rounded,
                          isBig: true,
                          onTap: () {
                            FeedbackManager().buttonClick();
                            _gameLogic.startGame();
                          }),
                      _buildGameButton(
                          icon: Icons.settings,
                          onTap: () {
                            FeedbackManager().buttonClick();
                            _showSettingsDialog(context);
                          }),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameButton(
      {required IconData icon,
      required VoidCallback onTap,
      bool isBig = false}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: EdgeInsets.all(isBig ? 20 : 12),
        decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent, width: 2)),
        child: Icon(icon, color: Colors.greenAccent, size: isBig ? 40 : 24),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    audioPlayer.dispose();
    _taskConfettiController.dispose();
    _bannerTimer?.cancel();
    _levelUpAnimationController.dispose();
    _highScoreAnimationController.dispose();
    _powerUpTimer?.cancel();
    _powerUpAnimationController.dispose();
    for (var timer in _powerUpTimers.values) {
      timer.cancel();
    }
    _powerUpTimers.clear();
    _gameLogic.dispose();
    super.dispose();
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
        return SettingsDialog(
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

  void _showAllTasksCompleted() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green[900]!,
                  Colors.green[800]!,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green[400]!,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 50,
                ),
                const SizedBox(height: 16),
                const Text(
                  '🎉 All Tasks Completed! 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Congratulations! You\'ve completed all daily tasks.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Continue Playing',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
