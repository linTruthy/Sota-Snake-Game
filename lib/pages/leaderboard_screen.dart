import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:easy_ads_flutter/easy_ads_flutter.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final String? username;
  final LeaderboardService _leaderboardService = LeaderboardService();

  LeaderboardScreen({super.key, this.username});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConfettiController _confettiController;
  bool _isCelebrating = false;
  final List<LeaderboardEntry> _globalLeaderboard = [];
  final List<LeaderboardEntry> _weeklyLeaderboard = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadLeaderboards();
    EasyAds.instance.loadAd();
  }

  Future<void> _loadLeaderboards() async {
    final global = await widget._leaderboardService.getLeaderboard();
    final weekly = await widget._leaderboardService.getWeeklyLeaderboard();

    setState(() {
      _globalLeaderboard
        ..clear()
        ..addAll(global);
      _weeklyLeaderboard
        ..clear()
        ..addAll(weekly);
      _checkForCelebration();
    });

    _setupLeaderboardStreams();
  }

  void _setupLeaderboardStreams() {
    widget._leaderboardService
        .getLeaderboardStream()
        .listen(_updateGlobalLeaderboard);
    widget._leaderboardService
        .getWeeklyLeaderboardStream()
        .listen(_updateWeeklyLeaderboard);
  }

  void _updateGlobalLeaderboard(List<LeaderboardEntry> newLeaderboard) {
    setState(() {
      _globalLeaderboard
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
    if (_globalLeaderboard.isNotEmpty &&
        _globalLeaderboard.first.playerName == widget.username &&
        !_isCelebrating) {
      _confettiController.play();
      _isCelebrating = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, int position) {
    final isCurrentUser = entry.playerName == widget.username;
    final trophyEmoji = position == 0
        ? '👑'
        : position == 1
            ? '🥈'
            : position == 2
                ? '🥉'
                : null;
    final cardGradient = isCurrentUser
        ? [Colors.amber.withOpacity(0.3), Colors.amber.withOpacity(0.1)]
        : [Colors.blue.withOpacity(0.2), Colors.purple.withOpacity(0.1)];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          // 3D Card Effect
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: cardGradient,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrentUser
                    ? Colors.amber.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCurrentUser
                      ? Colors.amber.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  Colors.white.withOpacity(0.1),
                  BlendMode.overlay,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Position Circle
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrentUser
                              ? Colors.amber.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          border: Border.all(
                            color: isCurrentUser
                                ? Colors.amber.withOpacity(0.5)
                                : Colors.blue.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${position + 1}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  isCurrentUser ? Colors.amber : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Player Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.playerName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    isCurrentUser ? Colors.amber : Colors.white,
                              ),
                            ),
                            if (entry.timestamp != null)
                              Text(
                                _formatDate(entry.timestamp!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Score
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.amber.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrentUser
                                ? Colors.amber.withOpacity(0.5)
                                : Colors.blue.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${entry.score}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isCurrentUser ? Colors.amber : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Trophy Badge
          if (trophyEmoji != null)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: position == 0
                        ? Colors.amber
                        : position == 1
                            ? Colors.grey[400]!
                            : Colors.brown,
                    width: 2,
                  ),
                ),
                child: Text(
                  trophyEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[900]!.withOpacity(0.8),
                  Colors.purple[900]!.withOpacity(0.8),
                ],
              ),
            ),
          ),
          // Main Content
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: true,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      '🏆 Leaderboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blue.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.emoji_events,
                          size: 80,
                          color: Colors.amber.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(
                          text: '🌍 Global',
                          icon: Icon(Icons.public),
                        ),
                        Tab(
                          text: '📅 Weekly',
                          icon: Icon(Icons.calendar_today),
                        ),
                      ],
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.blue.withOpacity(0.3),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: Column(
              children: [
                const EasySmartBannerAd(
                  priorityAdNetworks: [
                    AdNetwork.admob,
                    AdNetwork.unity,
                    AdNetwork.facebook
                  ],
                  adSize: AdSize.banner,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Global Leaderboard
                      RefreshIndicator(
                        onRefresh: _loadLeaderboards,
                        child: ListView.builder(
                          itemCount: _globalLeaderboard.length,
                          itemBuilder: (context, index) =>
                              _buildLeaderboardCard(
                            _globalLeaderboard[index],
                            index,
                          ),
                        ),
                      ),
                      // Weekly Leaderboard
                      RefreshIndicator(
                        onRefresh: _loadLeaderboards,
                        child: ListView.builder(
                          itemCount: _weeklyLeaderboard.length,
                          itemBuilder: (context, index) =>
                              _buildLeaderboardCard(
                            _weeklyLeaderboard[index],
                            index,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const EasySmartBannerAd(
                  priorityAdNetworks: [
                    AdNetwork.admob,
                    AdNetwork.unity,
                    AdNetwork.facebook
                  ],
                  adSize: AdSize.banner,
                ),
              ],
            ),
          ),
          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
