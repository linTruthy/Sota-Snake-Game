import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart' as games_services;

class PlayGamesService {
  // Singleton instance
  static final PlayGamesService _instance = PlayGamesService._internal();
  factory PlayGamesService() => _instance;
  PlayGamesService._internal();

  // Track authentication state
  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  // Initialize services and attempt sign in
  Future<void> initialize() async {
    try {
      await signIn();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Play Games Services: $e');
      }
    }
  }

  // Sign in to game services
  Future<void> signIn() async {
    try {
      await games_services.GameAuth.signIn();
      final isSignedIn = await games_services.GameAuth.isSignedIn;
      _isSignedIn = isSignedIn;

      if (_isSignedIn) {
        // Load player info after successful sign in
        await _loadPlayerInfo();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in to Play Games Services: $e');
      }
      _isSignedIn = false;
    }
  }

  // Load player information
  Future<void> _loadPlayerInfo() async {
    try {
      final playerId = await games_services.Player.getPlayerID();
      final playerName = await games_services.Player.getPlayerName();
      if (kDebugMode) {
        print('Player ID: $playerId');
        print('Player Name: $playerName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading player info: $e');
      }
    }
  }

  // Submit score to leaderboard
  Future<void> submitScore(int score) async {
    if (!_isSignedIn) {
      // Attempt silent sign-in if connection was lost
      await signIn();
      if (!_isSignedIn) return;
    }

    try {
      final scoreData = games_services.Score(
        androidLeaderboardID: 'CgkIv-Wvj_EHEAIQAg',
        iOSLeaderboardID: 'sota_snake_leaderboard',
        value: score,
      );
      await games_services.Leaderboards.submitScore(score: scoreData);
    } catch (e) {
      // Catch specific Game Services exceptions here
      // Do NOT rethrow, as this will crash the Game Logic calling it
      if (kDebugMode) print('Game Services Error: $e');
    }
  }

  // Show leaderboard UI
  Future<void> showLeaderboard() async {
    if (!_isSignedIn) {
      await signIn();
      if (!_isSignedIn) return;
    }

    try {
      await games_services.Leaderboards.showLeaderboards(
        iOSLeaderboardID: 'sota_snake_leaderboard',
        androidLeaderboardID: 'CgkIv-Wvj_EHEAIQAg',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing leaderboard: $e');
      }
    }
  }

  // Unlock an achievement
  Future<void> unlockAchievement(String achievementId) async {
    if (!_isSignedIn) return;

    try {
      final achievement = games_services.Achievement(
        androidID: achievementId,
        iOSID: achievementId,
        percentComplete: 100,
        showsCompletionBanner: true,
      );

      await games_services.Achievements.unlock(achievement: achievement);
    } catch (e) {
      if (kDebugMode) {
        print('Error unlocking achievement: $e');
      }
    }
  }

  // Increment progress for an achievement
  Future<void> incrementAchievement(String achievementId, int steps) async {
    if (!_isSignedIn) return;

    try {
      final achievement = games_services.Achievement(
        androidID: achievementId,
        iOSID: achievementId,
        steps: steps,
      );

      await games_services.Achievements.increment(achievement: achievement);
    } catch (e) {
      if (kDebugMode) {
        print('Error incrementing achievement: $e');
      }
    }
  }

  // Show achievements UI
  Future<void> showAchievements() async {
    if (!_isSignedIn) {
      await signIn();
      if (!_isSignedIn) return;
    }

    try {
      await games_services.Achievements.showAchievements();
    } catch (e) {
      if (kDebugMode) {
        print('Error showing achievements: $e');
      }
    }
  }

  // Load achievement data
  Future<List<games_services.AchievementItemData>> loadAchievements() async {
    if (!_isSignedIn) return [];

    try {
      final achievements = await games_services.Achievements.loadAchievements();
      return achievements ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('Error loading achievements: $e');
      }
      return [];
    }
  }

  // Get player's score from leaderboard
  Future<int?> getPlayerScore() async {
    if (!_isSignedIn) return null;

    try {
      return await games_services.Player.getPlayerScore();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting player score: $e');
      }
      return null;
    }
  }
}
