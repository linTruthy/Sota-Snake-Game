import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/leaderboard_entry.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream for the global leaderboard
  Stream<List<LeaderboardEntry>> getLeaderboardStream() {
    return _firestore
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaderboardEntry.fromFirestore(doc))
            .toList());
  }

  Future<void> submitScore(String playerName, int score) async {
    await _firestore.collection('leaderboard').add({
      'playerName': playerName,
      'score': score,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Stream for the weekly leaderboard
  Stream<List<LeaderboardEntry>> getWeeklyLeaderboardStream() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return _firestore
        .collection('leaderboard')
        .where('timestamp', isGreaterThanOrEqualTo: startOfWeek)
        .orderBy(
            'timestamp') // First orderBy must match the inequality filter field
        .orderBy('score', descending: true) // Then order by score descending
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaderboardEntry.fromFirestore(doc))
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score)));
  }

  getLeaderboard() {
    List<LeaderboardEntry> leaderboard = [];
    _firestore
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .limit(20)
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        leaderboard.add(LeaderboardEntry.fromFirestore(doc));
      }
    });
    return leaderboard;
    // return _firestore.collection('leaderboard').get();
  }

  getWeeklyLeaderboard() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    List<LeaderboardEntry> weeklyLeaderboard = [];

    _firestore
        .collection('leaderboard')
        .where('timestamp', isGreaterThanOrEqualTo: startOfWeek)
        .orderBy(
            'timestamp') // First orderBy must match the inequality filter field
        .orderBy('score', descending: true) // Then order by score descending
        .limit(20)
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        weeklyLeaderboard.add(LeaderboardEntry.fromFirestore(doc));
      }
    });
    return weeklyLeaderboard;
  }
}
