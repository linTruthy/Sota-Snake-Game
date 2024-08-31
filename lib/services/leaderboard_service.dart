import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sota_snake_game/models/leaderboard_entry.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitScore(String playerName, int score) async {
    await _firestore.collection('leaderboard').add({
      'playerName': playerName,
      'score': score,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

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
}
