import 'package:easy_ads_flutter/easy_ads_flutter.dart';
import 'package:flutter/material.dart';
import 'package:sota_snake_game/models/leaderboard_entry.dart';
import 'package:sota_snake_game/services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final LeaderboardService _leaderboardService = LeaderboardService();

  LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<LeaderboardEntry> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    widget._leaderboardService.getLeaderboardStream().listen((leaderboard) {
      setState(() {
        _updateLeaderboard(leaderboard);
      });
    });
  }

  void _updateLeaderboard(List<LeaderboardEntry> newLeaderboard) {
    final oldLeaderboard = _leaderboard;
    _leaderboard = newLeaderboard;

    final diff = newLeaderboard.length - oldLeaderboard.length;
    if (diff > 0) {
      for (int i = 0; i < diff; i++) {
        _listKey.currentState?.insertItem(oldLeaderboard.length + i);
      }
    } else if (diff < 0) {
      for (int i = 0; i < -diff; i++) {
        _listKey.currentState?.removeItem(
          oldLeaderboard.length - i - 1,
          (context, animation) => _buildLeaderboardTile(
            oldLeaderboard[oldLeaderboard.length - i - 1],
            oldLeaderboard.length - i - 1,
            animation,
          ),
        );
      }
    }
  }

  Widget _buildTrophy(int position) {
    IconData icon;
    Color color;
    switch (position) {
      case 1:
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case 2:
        icon = Icons.emoji_events;
        color = Colors.grey[300]!;
        break;
      case 3:
        icon = Icons.emoji_events;
        color = Colors.brown[300]!;
        break;
      default:
        icon = Icons.egg;
        color = Colors.grey[400]!;
    }
    return Icon(icon, color: color, size: 30);
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${index + 1}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            _buildTrophy(index + 1),
          ],
        ),
        title: Text(entry.playerName),
        trailing: Text(entry.score.toString(), style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Leaderboard'),
      ),
      body: Column(
        children: [
          const EasySmartBannerAd(
            priorityAdNetworks: [
              AdNetwork.admob,
              AdNetwork.unity,
              AdNetwork.facebook,
            ],
            adSize: AdSize.leaderboard,
          ),
          Expanded(
            child: AnimatedList(
              key: _listKey,
              initialItemCount: _leaderboard.length,
              itemBuilder: (context, index, animation) {
                final entry = _leaderboard[index];
                return _buildLeaderboardTile(entry, index, animation);
              },
            ),
          ),
          const EasySmartBannerAd(
            priorityAdNetworks: [
              AdNetwork.admob,
              AdNetwork.unity,
              AdNetwork.facebook,
            ],
            adSize: AdSize.leaderboard,
          ),
        ],
      ),
    );
  }
}
