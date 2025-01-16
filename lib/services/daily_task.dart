import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_task.dart';

class DailyTaskService {
  static const String _lastGeneratedKey = 'lastGeneratedDate';
  static const String _tasksKey = 'dailyTasks';

  static Future<List<DailyTask>> getDailyTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final lastGenerated = prefs.getString(_lastGeneratedKey);
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastGenerated != today) {
      // Generate new tasks for today
      final tasks = _generateDailyTasks();
      await _saveTasks(tasks);
      await prefs.setString(_lastGeneratedKey, today);
      return tasks;
    }

    // Return existing tasks
    return _loadTasks();
  }

  static List<DailyTask> _generateDailyTasks() {
    final random = Random();
    final tasks = <DailyTask>[];
    final taskTypes = TaskType.values.toList()..shuffle();

    // Generate 3 random tasks
    for (int i = 0; i < 3; i++) {
      final type = taskTypes[i];
      final task = DailyTask(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: _getTaskTitle(type),
        description: _getTaskDescription(type),
        rewardPoints: _getRewardPoints(type),
        type: type,
        target: _getTaskTarget(type),
      );
      tasks.add(task);
    }

    return tasks;
  }

  static String _getTaskTitle(TaskType type) {
    switch (type) {
      case TaskType.score:
        return 'Score Champion';
      case TaskType.timeAlive:
        return 'Survival Expert';
      case TaskType.powerUps:
        return 'Power Hunter';
      case TaskType.foodEaten:
        return 'Food Collector';
      case TaskType.levelReached:
        return 'Level Master';
    }
  }

  static String _getTaskDescription(TaskType type) {
    final target = _getTaskTarget(type);
    switch (type) {
      case TaskType.score:
        return 'Reach a score of $target points in a single game';
      case TaskType.timeAlive:
        return 'Stay alive for $target seconds';
      case TaskType.powerUps:
        return 'Collect $target power-ups';
      case TaskType.foodEaten:
        return 'Eat $target pieces of food';
      case TaskType.levelReached:
        return 'Reach level $target';
    }
  }

  static int _getTaskTarget(TaskType type) {
    final random = Random();
    switch (type) {
      case TaskType.score:
        return (random.nextInt(5) + 1) * 100;
      case TaskType.timeAlive:
        return (random.nextInt(3) + 1) * 30;
      case TaskType.powerUps:
        return random.nextInt(3) + 1;
      case TaskType.foodEaten:
        return (random.nextInt(5) + 1) * 5;
      case TaskType.levelReached:
        return random.nextInt(3) + 2;
    }
  }

  static int _getRewardPoints(TaskType type) {
    final random = Random();
    switch (type) {
      case TaskType.score:
        return 50 + random.nextInt(51);
      case TaskType.timeAlive:
        return 40 + random.nextInt(41);
      case TaskType.powerUps:
        return 30 + random.nextInt(31);
      case TaskType.foodEaten:
        return 35 + random.nextInt(36);
      case TaskType.levelReached:
        return 45 + random.nextInt(46);
    }
  }

  static Future<void> _saveTasks(List<DailyTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((task) => task.toMap()).toList();
    await prefs.setString(_tasksKey, jsonEncode(tasksJson));
  }

  static Future<List<DailyTask>> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_tasksKey);
    if (tasksJson == null) return [];

    final List<dynamic> decoded = jsonDecode(tasksJson);
    return decoded.map((json) => DailyTask.fromMap(json)).toList();
  }

  static Future<void> updateTaskProgress(String taskId, int progress) async {
    final tasks = await _loadTasks();
    final taskIndex = tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    tasks[taskIndex].progress = progress;
    if (progress >= tasks[taskIndex].target && !tasks[taskIndex].isCompleted) {
      tasks[taskIndex].isCompleted = true;
      tasks[taskIndex].completedAt = DateTime.now();
    }

    await _saveTasks(tasks);
  }
}
