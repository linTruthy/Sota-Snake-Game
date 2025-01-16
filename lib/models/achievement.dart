

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum AchievementTier { bronze, silver, gold, platinum, diamond }

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final AchievementTier tier;
  final int target;
  final int rewardPoints;
  bool isUnlocked;
  int progress;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.tier,
    required this.target,
    required this.rewardPoints,
    this.isUnlocked = false,
    this.progress = 0,
    this.unlockedAt,
  });

  double get progressPercentage => progress / target;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'progress': progress,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromJson(
      Map<String, dynamic> json, Achievement baseAchievement) {
    return Achievement(
      id: baseAchievement.id,
      title: baseAchievement.title,
      description: baseAchievement.description,
      iconName: baseAchievement.iconName,
      tier: baseAchievement.tier,
      target: baseAchievement.target,
      rewardPoints: baseAchievement.rewardPoints,
      progress: json['progress'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }
}

// achievement_service.dart
class AchievementService {
  static const String _achievementsKey = 'achievements';

  static final List<Achievement> _baseAchievements = [
    Achievement(
      id: 'first_game',
      title: 'First Steps',
      description: 'Play your first game',
      iconName: 'gamepad',
      tier: AchievementTier.bronze,
      target: 1,
      rewardPoints: 10,
    ),
    Achievement(
      id: 'score_100',
      title: 'Century',
      description: 'Score 100 points in a single game',
      iconName: 'stars',
      tier: AchievementTier.bronze,
      target: 100,
      rewardPoints: 25,
    ),
    Achievement(
      id: 'score_500',
      title: 'High Roller',
      description: 'Score 500 points in a single game',
      iconName: 'star',
      tier: AchievementTier.silver,
      target: 500,
      rewardPoints: 50,
    ),
    Achievement(
      id: 'score_1000',
      title: 'Snake Master',
      description: 'Score 1000 points in a single game',
      iconName: 'workspace_premium',
      tier: AchievementTier.gold,
      target: 1000,
      rewardPoints: 100,
    ),
    Achievement(
      id: 'level_5',
      title: 'Rising Star',
      description: 'Reach level 5',
      iconName: 'trending_up',
      tier: AchievementTier.bronze,
      target: 5,
      rewardPoints: 30,
    ),
    Achievement(
      id: 'level_10',
      title: 'Expert Navigator',
      description: 'Reach level 10',
      iconName: 'psychology',
      tier: AchievementTier.silver,
      target: 10,
      rewardPoints: 60,
    ),
    Achievement(
      id: 'powerups_10',
      title: 'Power Hunter',
      description: 'Collect 10 power-ups',
      iconName: 'bolt',
      tier: AchievementTier.bronze,
      target: 10,
      rewardPoints: 20,
    ),
    Achievement(
      id: 'powerups_50',
      title: 'Power Master',
      description: 'Collect 50 power-ups',
      iconName: 'electric_bolt',
      tier: AchievementTier.gold,
      target: 50,
      rewardPoints: 75,
    ),
    Achievement(
      id: 'snake_length_20',
      title: 'Growing Up',
      description: 'Grow your snake to length 20',
      iconName: 'straighten',
      tier: AchievementTier.silver,
      target: 20,
      rewardPoints: 40,
    ),
    Achievement(
      id: 'daily_tasks_5',
      title: 'Task Master',
      description: 'Complete 5 daily tasks',
      iconName: 'task_alt',
      tier: AchievementTier.silver,
      target: 5,
      rewardPoints: 45,
    ),
  ];

  static Future<List<Achievement>> getAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString(_achievementsKey);

    if (savedData == null) {
      return _baseAchievements;
    }

    final List<dynamic> decoded = jsonDecode(savedData);
    final Map<String, dynamic> achievementsMap = Map.fromEntries(
      decoded.map((item) => MapEntry(item['id'], item)),
    );

    return _baseAchievements.map((achievement) {
      final savedAchievement = achievementsMap[achievement.id];
      if (savedAchievement != null) {
        return Achievement.fromJson(savedAchievement, achievement);
      }
      return achievement;
    }).toList();
  }

  static Future<void> updateAchievement(String id, int progress) async {
    final achievements = await getAchievements();
    final achievement = achievements.firstWhere((a) => a.id == id);

    achievement.progress = progress;
    if (progress >= achievement.target && !achievement.isUnlocked) {
      achievement.isUnlocked = true;
      achievement.unlockedAt = DateTime.now();
      // Show notification or celebration effect
    }

    await _saveAchievements(achievements);
  }

  static Future<void> _saveAchievements(List<Achievement> achievements) async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = achievements.map((a) => a.toJson()).toList();
    await prefs.setString(_achievementsKey, jsonEncode(achievementsJson));
  }
}
