import 'package:easy_ads_flutter/easy_ads_flutter.dart';
import 'package:flutter/material.dart';
import 'package:sota_snake_game/models/leaderboard_entry.dart';
import 'package:sota_snake_game/services/leaderboard_service.dart';

class LeaderboardScreen extends StatelessWidget {
  final LeaderboardService _leaderboardService = LeaderboardService();

  LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Leaderboard'),
      ),
      body: StreamBuilder<List<LeaderboardEntry>>(
        stream: _leaderboardService.getLeaderboardStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final leaderboard = snapshot.data ?? [];

          return Column(
            children: [
              const EasySmartBannerAd(
                priorityAdNetworks: [
                  AdNetwork.admob,
                  AdNetwork.unity,
                  AdNetwork.facebook,
                ],
                adSize: AdSize.banner,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: leaderboard.length,
                  itemBuilder: (context, index) {
                    final entry = leaderboard[index];
                    return ListTile(
                      leading: Text('${index + 1}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      title: Text(entry.playerName),
                      trailing: Text(entry.score.toString(),
                          style: const TextStyle(fontSize: 18)),
                    );
                  },
                ),
              ),
              const EasySmartBannerAd(
                priorityAdNetworks: [
                  AdNetwork.admob,
                  AdNetwork.unity,
                  AdNetwork.facebook,
                ],
                adSize: AdSize.fullBanner,
              ),
            ],
          );
        },
      ),
    );
  }
}
