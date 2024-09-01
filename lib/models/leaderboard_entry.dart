import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String playerName;
  final int score;
  final DateTime? timestamp;

  LeaderboardEntry(
      {required this.playerName, required this.score, this.timestamp});

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return LeaderboardEntry(
      playerName: data['playerName'] ?? '',
      score: data['score'] ?? 0,
      timestamp: data['timestamp']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'playerName': playerName,
        'score': score,
      };
}
