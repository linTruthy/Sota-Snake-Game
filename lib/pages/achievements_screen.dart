import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../services/achievement_service.dart';
import '../models/achievement.dart';

class EnhancedAchievementsScreen extends StatefulWidget {
  const EnhancedAchievementsScreen({super.key});

  @override
  State<EnhancedAchievementsScreen> createState() =>
      _EnhancedAchievementsScreenState();
}

class _EnhancedAchievementsScreenState extends State<EnhancedAchievementsScreen>
    with TickerProviderStateMixin {
  // Data State
  List<Achievement> _allAchievements = [];
  List<Achievement> _filteredAchievements = [];
  bool _isLoading = true;
  String _activeFilter = 'ALL'; // 'ALL', 'UNLOCKED', 'LOCKED'

  // Visual State
  late ConfettiController _confettiController;
  final ScrollController _scrollController = ScrollController();

  // Staggered Animation Logic
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  bool _listAnimated = false;

  // Theme Constants
  static const Color _neonGreen = Color(0xFF39FF14);
  static const Color _neonBlue = Color(0xFF00F3FF);
  static const Color _neonGold = Color(0xFFFFD700);
  static const Color _techBg = Color(0xFF0A0A12);

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await AchievementService.getAchievements();
      if (mounted) {
        setState(() {
          _allAchievements = data;
          _isLoading = false;
        });
        _applyFilter(_activeFilter);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      if (filter == 'ALL') {
        _filteredAchievements = List.from(_allAchievements);
      } else if (filter == 'UNLOCKED') {
        _filteredAchievements =
            _allAchievements.where((a) => a.isUnlocked).toList();
      } else {
        _filteredAchievements =
            _allAchievements.where((a) => !a.isUnlocked).toList();
      }

      // Sort: Unlocked first, then by progress
      _filteredAchievements.sort((a, b) {
        if (a.isUnlocked && !b.isUnlocked) return -1;
        if (!a.isUnlocked && b.isUnlocked) return 1;
        return (b.progress / b.target).compareTo(a.progress / a.target);
      });

      _listAnimated = false; // Reset animation trigger
    });

    // Trigger animations after frame build
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _listAnimated = true);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _techBg,
      body: Stack(
        children: [
          // 1. Subtle Background Grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),

          SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(child: _buildStatsHeader()),
                  SliverToBoxAdapter(child: _buildFilterBar()),
                ];
              },
              body: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _neonBlue))
                  : _buildAchievementList(),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              colors: const [Colors.cyan, Colors.purple, Colors.amber],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: _techBg,
      floating: true,
      snap: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: _neonBlue),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "TROPHY_LOG",
        style: TextStyle(
          color: _neonBlue,
          fontFamily: 'Courier',
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: Colors.white10, height: 1),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalPoints = _allAchievements
        .where((a) => a.isUnlocked)
        .fold(0, (sum, a) => sum + a.rewardPoints);
    final maxPoints =
        _allAchievements.fold(0, (sum, a) => sum + a.rewardPoints);
    final unlockedCount = _allAchievements.where((a) => a.isUnlocked).length;
    final totalCount = _allAchievements.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress Chart
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: totalCount > 0 ? unlockedCount / totalCount : 0,
                  backgroundColor: Colors.white10,
                  color: _neonGreen,
                  strokeWidth: 8,
                ),
              ),
              Text(
                "${((unlockedCount / totalCount) * 100).toInt()}%",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Text Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                    "UNLOCKED", "$unlockedCount / $totalCount", Colors.white),
                const SizedBox(height: 8),
                _buildStatRow("SCORE", "$totalPoints / $maxPoints", _neonGold),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip("ALL", "DATABASE"),
          const SizedBox(width: 12),
          _buildFilterChip("UNLOCKED", "COMPLETED"),
          const SizedBox(width: 12),
          _buildFilterChip("LOCKED", "ENCRYPTED"),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _activeFilter == key;
    return GestureDetector(
      onTap: () => _applyFilter(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _neonBlue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _neonBlue : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementList() {
    if (_filteredAchievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              "NO DATA FOUND",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontFamily: 'Courier'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 50),
      itemCount: _filteredAchievements.length,
      itemBuilder: (context, index) {
        // Simple manual staggering animation based on index
        // Prevents heavy dependency on extra packages
        final delay = _listAnimated ? 0 : index * 50;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          opacity: _listAnimated ? 1.0 : 0.0,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutQuad,
            padding: _listAnimated
                ? EdgeInsets.zero
                : const EdgeInsets.only(top: 20),
            child: _buildAchievementTile(_filteredAchievements[index]),
          ),
        );
      },
    );
  }

  Widget _buildAchievementTile(Achievement item) {
    final isLocked = !item.isUnlocked;
    final progress = item.progressPercentage.clamp(0.0, 1.0);
    final borderColor = isLocked ? Colors.white10 : _neonBlue.withOpacity(0.6);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: isLocked
                  ? Colors.white.withOpacity(0.02)
                  : _neonBlue.withOpacity(0.05),
              border: Border(
                left: BorderSide(
                    color: isLocked ? Colors.grey : _neonBlue, width: 4),
                bottom: const BorderSide(color: Colors.white10),
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: ExpansionTile(
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              tilePadding: const EdgeInsets.all(16),
              leading: _buildHexIcon(item.iconName, isLocked),
              title: Text(
                isLocked ? "LOCKED // ${item.title}" : item.title,
                style: TextStyle(
                  color: isLocked ? Colors.white38 : Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.black,
                      valueColor: AlwaysStoppedAnimation(
                          isLocked ? Colors.grey : _neonGreen),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${(progress * 100).toInt()}%",
                        style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                            fontFamily: 'Courier'),
                      ),
                      Text(
                        "${item.progress} / ${item.target}",
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  )
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: _neonGold, size: 14),
                  Text(
                    "${item.rewardPoints}",
                    style: const TextStyle(
                        color: _neonGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ],
              ),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.description,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        height: 1.5),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHexIcon(String iconName, bool isLocked) {
    return CustomPaint(
      painter: _HexagonPainter(
        color: isLocked
            ? Colors.grey.withOpacity(0.2)
            : _neonBlue.withOpacity(0.2),
        borderColor: isLocked ? Colors.grey : _neonBlue,
      ),
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        child: Icon(
          _getIconData(iconName),
          color: isLocked ? Colors.white24 : Colors.white,
          size: 24,
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // Reusing your mapping logic
    switch (iconName) {
      case 'gamepad':
        return Icons.gamepad;
      case 'stars':
        return Icons.stars;
      case 'star':
        return Icons.star;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'trending_up':
        return Icons.trending_up;
      case 'psychology':
        return Icons.psychology;
      case 'bolt':
        return Icons.bolt;
      case 'electric_bolt':
        return Icons.electric_bolt;
      case 'straighten':
        return Icons.straighten;
      case 'task_alt':
        return Icons.task_alt;
      default:
        return Icons.emoji_events;
    }
  }
}

// ---------------------------------------------------------------------------
// Custom Painters for Shapes
// ---------------------------------------------------------------------------

class _HexagonPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _HexagonPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Flat-topped Hexagon points
    path.moveTo(w * 0.25, 0);
    path.lineTo(w * 0.75, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(w * 0.75, h);
    path.lineTo(w * 0.25, h);
    path.lineTo(0, h * 0.5);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _HexagonPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const double step = 30;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
