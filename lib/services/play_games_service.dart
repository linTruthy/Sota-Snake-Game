import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

class PlayGamesService {
  static Future<void> initialize() async {
    try {
      await GamesServices.signIn();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in to Play Games Services: $e');
      }
    }
  }

  static Future<void> submitScore(int score) async {
    Score scoreData = Score(
      androidLeaderboardID: 'CgkIv-Wvj_EHEAIQAg',
      iOSLeaderboardID: 'CgkIv-Wvj_EHEAIQAg',
      value: score,
    );

    try {
      await GamesServices.submitScore(
        score: scoreData,
        //  boardID: 'YOUR_LEADERBOARD_ID',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting score: $e');
      }
    }
  }

  static Future<void> showLeaderboard() async {
    try {
      await GamesServices.showLeaderboards(
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2157467268.
     //   iOSLeaderboardID: 'CgkIv-Wvj_EHEAIQAg',
      //  androidLeaderboardID: 'CgkIv-Wvj_EHEAIQAg',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing leaderboard: $e');
      }
    }
  }

  static Future<void> unlockAchievement(String achievementId) async {
    Achievement achievement = Achievement(
      androidID: achievementId,
      iOSID: achievementId,
      steps: 100,
      showsCompletionBanner: true,
    );

    try {
      await GamesServices.unlock(achievement: achievement);
    } catch (e) {
      if (kDebugMode) {
        print('Error unlocking achievement: $e');
      }
    }
  }

  static showAchievements() {
    try {
      GamesServices.showAchievements();
    } catch (e) {
      if (kDebugMode) {
        print('Error showing achievements: $e');
      }
    }
  }
}
