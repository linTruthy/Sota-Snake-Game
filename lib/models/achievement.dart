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
