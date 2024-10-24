import 'package:flutter/material.dart';

class DailyTask {
  final String id;
  final String title;
  final String description;
  final int rewardPoints;
  final TaskType type;
  final int target;
  int progress;
  bool isCompleted;
  DateTime? completedAt;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardPoints,
    required this.type,
    required this.target,
    this.progress = 0,
    this.isCompleted = false,
    this.completedAt,
  });

  double get progressPercentage => progress / target;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rewardPoints': rewardPoints,
      'type': type.toString(),
      'target': target,
      'progress': progress,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      rewardPoints: map['rewardPoints'],
      type: TaskType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => TaskType.score,
      ),
      target: map['target'],
      progress: map['progress'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null 
        ? DateTime.parse(map['completedAt'])
        : null,
    );
  }
}

enum TaskType {
  score,
  timeAlive,
  powerUps,
  foodEaten,
  levelReached
}

extension TaskTypeExtension on TaskType {
  String get displayName {
    switch (this) {
      case TaskType.score:
        return 'Score Points';
      case TaskType.timeAlive:
        return 'Survive Time';
      case TaskType.powerUps:
        return 'Collect Power-ups';
      case TaskType.foodEaten:
        return 'Eat Food';
      case TaskType.levelReached:
        return 'Reach Level';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskType.score:
        return Icons.stars;
      case TaskType.timeAlive:
        return Icons.timer;
      case TaskType.powerUps:
        return Icons.flash_on;
      case TaskType.foodEaten:
        return Icons.restaurant;
      case TaskType.levelReached:
        return Icons.trending_up;
    }
  }
}