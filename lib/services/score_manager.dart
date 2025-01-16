import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart' as games_services;
import 'package:shared_preferences/shared_preferences.dart';

class ScoreManager {
  static const String _localHighScoreKey = 'highScore';

  // Singleton pattern
  static final ScoreManager _instance = ScoreManager._internal();
  factory ScoreManager() => _instance;
  ScoreManager._internal();

  int _currentScore = 0;
  int _highScore = 0;
  bool _isInitialized = false;

  int get currentScore => _currentScore;
  int get highScore => _highScore;

  // Initialize score manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadHighScore();
    _isInitialized = true;
  }

  // Load high score from all available sources
  Future<void> _loadHighScore() async {
    int? gameServicesScore;
    int localScore = 0;

    // Load local score
    final prefs = await SharedPreferences.getInstance();
    localScore = prefs.getInt(_localHighScoreKey) ?? 0;

    // Try to load score from Game Services if signed in
    try {
      final isSignedIn = await games_services.GameAuth.isSignedIn;
      if (isSignedIn) {
        gameServicesScore = await games_services.Player.getPlayerScore();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading Game Services score: $e');
      }
    }

    // Use the highest score from either source
    _highScore = max(localScore, gameServicesScore ?? 0);

    // If Game Services score is lower, update it
    if (gameServicesScore != null && localScore > gameServicesScore) {
      await _submitScoreToGameServices(localScore);
    }

    // If local score is lower, update it
    if (localScore < _highScore) {
      await _saveLocalHighScore(_highScore);
    }
  }

  // Update current score
  Future<void> updateScore(int newScore) async {
    _currentScore = newScore;

    // Check if this is a new high score
    if (newScore > _highScore) {
      _highScore = newScore;
      await _saveHighScore(newScore);
    }
  }

  // Reset current score
  void resetScore() {
    _currentScore = 0;
  }

  // Save high score to all available storage
  Future<void> _saveHighScore(int score) async {
    // Save locally
    await _saveLocalHighScore(score);

    // Save to Game Services
    await _submitScoreToGameServices(score);
  }

  // Save score to local storage
  Future<void> _saveLocalHighScore(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_localHighScoreKey, score);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving local high score: $e');
      }
    }
  }

  // Submit score to Game Services
  Future<void> _submitScoreToGameServices(int score) async {
    try {
      final isSignedIn = await games_services.GameAuth.isSignedIn;
      if (!isSignedIn) return;

      final scoreData = games_services.Score(
        androidLeaderboardID: 'CgkIv-Wvj_EHEAIQAg',
        iOSLeaderboardID: 'sota_snake_leaderboard',
        value: score,
      );

      await games_services.Leaderboards.submitScore(score: scoreData);
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting score to Game Services: $e');
      }
    }
  }

  // Sync scores between local storage and Game Services
  Future<void> syncScores() async {
    await _loadHighScore();
  }

  // Get formatted score string
  String getFormattedScore() {
    return _currentScore.toString().padLeft(4, '0');
  }

  // Get formatted high score string
  String getFormattedHighScore() {
    return _highScore.toString().padLeft(4, '0');
  }
}
