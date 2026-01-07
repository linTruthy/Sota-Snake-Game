import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'leaderboard_service.dart';
import 'play_games_service.dart';

class ScoreSyncManager {
  // Singleton
  static final ScoreSyncManager _instance = ScoreSyncManager._internal();
  factory ScoreSyncManager() => _instance;
  ScoreSyncManager._internal();

  static const String _queueKey = 'pending_scores_queue';

  /// Attempts to submit score. If it fails, saves to local storage.
  Future<void> submitScore({required String username, required int score}) async {
    bool uploadSuccess = false;

    // 1. Try Firebase
    try {
      await LeaderboardService().submitScore(username, score);
      uploadSuccess = true;
    } catch (e) {
      if (kDebugMode) print('🔥 Firebase Upload Failed: $e');
    }

    // 2. Try Game Services (Fire and forget, handled internally mostly, but good to wrap)
    try {
      await PlayGamesService().submitScore(score);
    } catch (e) {
      if (kDebugMode) print('🎮 GameServices Upload Failed: $e');
      // We rely more on Firebase for our internal leaderboard, so GameServices failure
      // is less critical to queue, but you can queue it if needed.
    }

    // 3. If Firebase failed, queue it.
    if (!uploadSuccess) {
      await _queueLocally(username, score);
    }
  }

  /// Saves the score to SharedPreferences to try again later
  Future<void> _queueLocally(String username, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentQueue = prefs.getStringList(_queueKey) ?? [];
    
    final Map<String, dynamic> entry = {
      'username': username,
      'score': score,
      'timestamp': DateTime.now().toIso8601String(),
    };

    currentQueue.add(jsonEncode(entry));
    await prefs.setStringList(_queueKey, currentQueue);
    
    if (kDebugMode) print('💾 Score Queued locally for later sync.');
  }

  /// Call this on App Start (main.dart) or Network Reconnect
  Future<void> processQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentQueue = prefs.getStringList(_queueKey) ?? [];

    if (currentQueue.isEmpty) return;

    if (kDebugMode) print('🔄 Processing ${currentQueue.length} offline scores...');

    final List<String> failedAgain = [];

    for (String jsonStr in currentQueue) {
      try {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        // Retry submission (Directly to service, skipping the queue wrapper to avoid loops)
        await LeaderboardService().submitScore(
          data['username'], 
          data['score']
        );
        if (kDebugMode) print('✅ Offline score synced: ${data['score']}');
      } catch (e) {
        // If it fails again, keep it in the list
        failedAgain.add(jsonStr);
      }
    }

    // Update the queue with whatever is left
    await prefs.setStringList(_queueKey, failedAgain);
  }
}