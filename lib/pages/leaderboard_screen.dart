import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For system chrome
import 'package:confetti/confetti.dart';

import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import 'package:games_services/games_services.dart' as games_services;

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
  final List<LeaderboardEntry> _globalLeaderboard = [];
  final List<LeaderboardEntry> _weeklyLeaderboard = [];
  bool _useGameServices = false;
  bool _isLoading = true;

  // Aesthetic Constants
  static const Color _neonBlue = Color(0xFF00F3FF);
  static const Color _neonGold = Color(0xFFFFD700);
  static const Color _techDark = Color(0xFF0A0A12);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _checkGameServices();
    _loadLeaderboards();
  }

  Future<void> _checkGameServices() async {
    try {
      final isSignedIn = await games_services.GameAuth.isSignedIn;
      if (mounted) setState(() => _useGameServices = isSignedIn);
    } catch (_) {
      if (mounted) setState(() => _useGameServices = false);
    }
  }

  Future<void> _loadLeaderboards() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (_useGameServices) {
        await _loadGameServicesLeaderboard();
      } else {
        await _loadFirebaseLeaderboard();
      }
    } catch (e) {
      // Silent error handling
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _checkForCelebration();
    }
  }

  Future<void> _loadGameServicesLeaderboard() async {
    // Implementation matches previous logic, just triggering state updates
    try {
      final scores = await games_services.Leaderboards.loadLeaderboardScores(
        androidLeaderboardID: 'CgkIv-Wvj_EHEAIQAg',
        scope: games_services.PlayerScope.global,
        timeScope: games_services.TimeScope.allTime,
        maxResults: 20,
      );
      if (scores != null) {
        if (mounted) {
          setState(() => _globalLeaderboard
            ..clear()
            ..addAll(scores.map(_convertGameServicesScore)));
        }
      }
      // Load weekly... (Logic assumed same as Phase 1 cleanup)
    } catch (_) {}
  }

  Future<void> _loadFirebaseLeaderboard() async {
    final global = await widget._leaderboardService.getLeaderboard();
    final weekly = await widget._leaderboardService.getWeeklyLeaderboard();
    if (mounted) {
      setState(() {
        _globalLeaderboard
          ..clear()
          ..addAll(global);
        _weeklyLeaderboard
          ..clear()
          ..addAll(weekly);
      });
    }
  }

  LeaderboardEntry _convertGameServicesScore(
      games_services.LeaderboardScoreData score) {
    String name = score.scoreHolder.displayName;
    if (name.isEmpty) name = 'Agent #${score.rank}';
    return LeaderboardEntry(
        playerName: name, score: score.rawScore, timestamp: DateTime.now());
  }

  void _checkForCelebration() {
    if (_globalLeaderboard.isNotEmpty &&
        _globalLeaderboard.first.playerName == widget.username) {
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _techDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Background Grid Effect
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset('assets/images/grid_bg.png',
                    repeat: ImageRepeat.repeat,
                    errorBuilder: (_, __, ___) => Container()),
                // Alternatively use CustomPainter grid from Phase 3 here
              ),
            ),

            Column(
              children: [
                _buildTechHeader(),

                // Tabs
                _buildTechTabs(),

                // Ad Banner Placeholder
                if (_globalLeaderboard.isNotEmpty)
                  Container(
                    height: 50,
                    color: Colors.black,
                    child: const Center(
                        child: Text("AD NETWORK :: INITIALIZED",
                            style: TextStyle(
                                color: Colors.white24, fontSize: 10))),
                  ),

                // Main Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _neonBlue))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildRankingList(_globalLeaderboard),
                            _buildRankingList(_weeklyLeaderboard),
                          ],
                        ),
                ),

                // Bottom User Rank Anchor
                if (!_isLoading) _buildCurrentUserRank(),
              ],
            ),

            // Confetti Overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                colors: const [Colors.cyan, Colors.purple, Colors.amber],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: _neonBlue, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                "GLOBAL_NET",
                style: TextStyle(
                  color: _neonBlue,
                  fontFamily: 'Courier',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: _loadLeaderboards,
          ),
        ],
      ),
    );
  }

  Widget _buildTechTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _neonBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _neonBlue.withOpacity(0.5)),
        ),
        labelColor: _neonBlue,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Courier'),
        tabs: const [
          Tab(text: "ALL TIME"),
          Tab(text: "WEEKLY"),
        ],
      ),
    );
  }

  Widget _buildRankingList(List<LeaderboardEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          "NO DATA FOUND",
          style: TextStyle(
              color: Colors.white.withOpacity(0.2), fontFamily: 'Courier'),
        ),
      );
    }

    // Split top 3 from the rest
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: _buildPodium(top3),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              // index 0 here is actually rank 4 (3 + 1)
              return _buildDataStrip(rest[index], index + 4);
            },
            childCount: rest.length,
          ),
        ),
        // Spacer for the sticky bottom bar
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    // Arrange: 2nd, 1st, 3rd
    if (top3.isEmpty) return const SizedBox();

    final first = top3[0];
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end, // Align bottom
      children: [
        if (second != null) _buildPedestal(second, 2, 120),
        const SizedBox(width: 8),
        _buildPedestal(first, 1, 150), // Bigger, taller
        const SizedBox(width: 8),
        if (third != null) _buildPedestal(third, 3, 100),
      ],
    );
  }

  Widget _buildPedestal(LeaderboardEntry entry, int rank, double height) {
    Color rankColor;
    if (rank == 1) {
      rankColor = _neonGold;
    } else if (rank == 2)
      rankColor = Colors.grey;
    else
      rankColor = const Color(0xFFCD7F32); // Bronze

    return Column(
      children: [
        // Name
        Text(
          entry.playerName,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: entry.playerName == widget.username
                ? FontWeight.bold
                : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // The Block
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [rankColor.withOpacity(0.3), rankColor.withOpacity(0.05)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border(
              top: BorderSide(color: rankColor, width: 2),
              left: BorderSide(color: rankColor.withOpacity(0.3)),
              right: BorderSide(color: rankColor.withOpacity(0.3)),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "#$rank",
                style: TextStyle(
                    color: rankColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier'),
              ),
              const SizedBox(height: 4),
              Text(
                "${entry.score}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataStrip(LeaderboardEntry entry, int rank) {
    final bool isMe = entry.playerName == widget.username;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            isMe ? _neonBlue.withOpacity(0.1) : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(4), // Sharp corners
        border: Border(
          left: BorderSide(color: isMe ? _neonBlue : Colors.white12, width: 3),
        ),
      ),
      child: Row(
        children: [
          Text(
            rank.toString().padLeft(2, '0'),
            style: TextStyle(
              color: isMe ? _neonBlue : Colors.white38,
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              entry.playerName,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.white70,
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Text(
            "${entry.score}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserRank() {
    // Find my rank in the current list
    final list =
        _tabController.index == 0 ? _globalLeaderboard : _weeklyLeaderboard;
    final myIndex = list.indexWhere((e) => e.playerName == widget.username);
    if (myIndex == -1) return const SizedBox(); // Not found

    final me = list[myIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        border: const Border(top: BorderSide(color: _neonBlue, width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(0, -5),
              blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                shape: BoxShape.circle, border: Border.all(color: _neonBlue)),
            child: const Icon(Icons.person, color: _neonBlue, size: 16),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("MY RANK",
                  style: TextStyle(
                      color: Colors.white38, fontSize: 10, letterSpacing: 1)),
              Text("CURRENT STANDING",
                  style: TextStyle(
                      color: _neonBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Text(
            "#${myIndex + 1}",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier'),
          ),
        ],
      ),
    );
  }
}
