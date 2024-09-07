import 'package:confetti/confetti.dart';
import 'package:easy_ads_flutter/easy_ads_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final String? username;

  LeaderboardScreen({super.key, this.username});

  @override
  State createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  final List<LeaderboardEntry> _leaderboard = [];
  final List<LeaderboardEntry> _weeklyLeaderboard = [];
  late ConfettiController _confettiController;
  late TabController _tabController;
  bool _isCelebrating = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _tabController = TabController(length: 2, vsync: this);

    _loadLeaderboards();
    EasyAds.instance.loadAd();
  }

  Future<void> _loadLeaderboards() async {
    final global = await widget._leaderboardService.getLeaderboard();
    final weekly = await widget._leaderboardService.getWeeklyLeaderboard();
    
    setState(() {
      _leaderboard.addAll(global);
      _weeklyLeaderboard.addAll(weekly);
      _checkForCelebration();
    });

    _setupLeaderboardStreams();
  }

  void _setupLeaderboardStreams() {
    widget._leaderboardService.getLeaderboardStream().listen(_updateLeaderboard);
    widget._leaderboardService.getWeeklyLeaderboardStream().listen(_updateWeeklyLeaderboard);
  }

  void _updateLeaderboard(List<LeaderboardEntry> newLeaderboard) {
    setState(() {
      _leaderboard
        ..clear()
        ..addAll(newLeaderboard);
      _checkForCelebration();
    });
  }

  void _updateWeeklyLeaderboard(List<LeaderboardEntry> newLeaderboard) {
    setState(() {
      _weeklyLeaderboard
        ..clear()
        ..addAll(newLeaderboard);
    });
  }

  void _checkForCelebration() {
    if (_leaderboard.isNotEmpty &&
        _leaderboard.first.playerName == widget.username &&
        !_isCelebrating) {
      _confettiController.play();
      _isCelebrating = true;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTrophy(int position) {
    final trophies = [
      const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
      const Icon(Icons.emoji_events, color: Colors.grey, size: 30),
      const Icon(Icons.emoji_events, color: Colors.brown, size: 30),
      const Icon(CupertinoIcons.star_fill, color: Colors.purple, size: 30),
      const Icon(CupertinoIcons.smiley, color: Colors.green, size: 30),
    ];

    return position <= trophies.length ? trophies[position - 1] : const Icon(Icons.catching_pokemon, color: Colors.blue, size: 30);
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry, int index) {
    final isCurrentUser = entry.playerName == widget.username;
    return ListTile(
      tileColor: isCurrentUser ? Colors.yellow.withOpacity(0.2) : null,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${index + 1}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          _buildTrophy(index + 1),
        ],
      ),
      title: Text(entry.playerName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isCurrentUser ? Colors.blue : null,
          )),
      trailing: Text(
        '${entry.score} pts',
        style: TextStyle(
          fontSize: 18,
          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                const SliverAppBar(
                  expandedHeight: 200.0,
                  snap: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(50),
                    ),
                  ),
                  stretch: true,
                  backgroundColor: Colors.green,
                  floating: true,
                  pinned: true,
                  forceMaterialTransparency: true,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text('🏆 Leaderboard of Champions 🏆',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    background: Icon(Icons.emoji_events, size: 48, color: Colors.amber)

                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: '🌍 Global '),
                        Tab(text: '📅 Weekly'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardView(_leaderboard),
                _buildLeaderboardView(_weeklyLeaderboard),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardView(List<LeaderboardEntry> leaderboard) {
    return Column(
      children: [
        const EasySmartBannerAd(
          priorityAdNetworks: [AdNetwork.admob, AdNetwork.unity, AdNetwork.facebook],
          adSize: AdSize.leaderboard,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadLeaderboards,
            child: ListView.builder(
              itemCount: leaderboard.length,
              itemBuilder: (context, index) => _buildLeaderboardTile(leaderboard[index], index),
            ),
          ),
        ),
        const EasySmartBannerAd(
          priorityAdNetworks: [AdNetwork.admob, AdNetwork.unity, AdNetwork.facebook],
          adSize: AdSize.leaderboard,
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).primaryColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}