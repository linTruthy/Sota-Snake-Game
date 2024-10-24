import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/achievement.dart';

class EnhancedAchievementsScreen extends StatefulWidget {
  const EnhancedAchievementsScreen({super.key});

  @override
  State<EnhancedAchievementsScreen> createState() =>
      _EnhancedAchievementsScreenState();
}

class _EnhancedAchievementsScreenState extends State<EnhancedAchievementsScreen>
    with SingleTickerProviderStateMixin {
  List<Achievement> _achievements = [];
  List<Achievement> _filteredAchievements = [];
  bool _isLoading = true;
  String _searchQuery = '';
  AchievementTier _selectedTier = AchievementTier.bronze;
  String _sortBy = 'progress'; // 'progress', 'points', 'name'

  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _filterAnimation;

  // Track expanded achievement cards
  final Set<String> _expandedAchievements = {};

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _filterAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _loadAchievements();
  }

  // @override
  // void dispose() {
  //   _confettiController.dispose();
  //   _animationController.dispose();
  //   super.dispose();
  // }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    try {
      final achievements = await AchievementService.getAchievements();
      setState(() {
        _achievements = achievements;
        _applyFilters(); // Initial filter application
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading achievements: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<Achievement> filtered = List.from(_achievements);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((achievement) {
        return achievement.title
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            achievement.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply tier filter
    if (_selectedTier != null) {
      filtered = filtered
          .where((achievement) => achievement.tier == _selectedTier)
          .toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'progress':
          return (b.progress / b.target).compareTo(a.progress / a.target);
        case 'points':
          return b.rewardPoints.compareTo(a.rewardPoints);
        case 'name':
          return a.title.compareTo(b.title);
        default:
          return 0;
      }
    });

    setState(() {
      _filteredAchievements = filtered;
      _animationController.forward(from: 0);
    });
  }

  void _toggleAchievementExpansion(String achievementId) {
    setState(() {
      if (_expandedAchievements.contains(achievementId)) {
        _expandedAchievements.remove(achievementId);
      } else {
        _expandedAchievements.add(achievementId);
      }
    });
  }

  Widget _buildStatisticsHeader() {
    final totalPoints = _achievements
        .where((a) => a.isUnlocked)
        .fold(0, (sum, a) => sum + a.rewardPoints);
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!, Colors.green[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '$totalPoints pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  _achievements.length.toString(),
                  Icons.emoji_events,
                  Colors.blue[300]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Unlocked',
                  unlockedCount.toString(),
                  Icons.lock_open,
                  Colors.green[300]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Locked',
                  (_achievements.length - unlockedCount).toString(),
                  Icons.lock_outline,
                  Colors.orange[300]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search achievements...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Tier Filter
              Expanded(
                child: DropdownButtonFormField<AchievementTier>(
                  value: _selectedTier,
                  onChanged: (AchievementTier? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTier = newValue;
                        _applyFilters();
                      });
                    }
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: AchievementTier.values.map((tier) {
                    return DropdownMenuItem(
                      value: tier,
                      child: Text(tier.toString().split('.').last),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              // Sort Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _sortBy = newValue;
                        _applyFilters();
                      });
                    }
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'progress', child: Text('Progress')),
                    DropdownMenuItem(value: 'points', child: Text('Points')),
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isExpanded = _expandedAchievements.contains(achievement.id);
    final progress = achievement.progressPercentage;
    final color = _getTierColor(achievement.tier);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(achievement.isUnlocked ? 1.0 : 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _toggleAchievementExpansion(achievement.id),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildAchievementIcon(achievement),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.title,
                          style: TextStyle(
                            color: achievement.isUnlocked
                                ? Colors.white
                                : Colors.grey[400],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          achievement.description,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
            if (!achievement.isUnlocked)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          '${achievement.progress}/${achievement.target}',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[700],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            if (isExpanded) ...[
              const Divider(height: 1, color: Colors.grey),
              _buildExpandedContent(achievement),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // Map string icon names to actual IconData
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
        return Icons.emoji_events; // Default icon
    }
  }

  Widget _buildAchievementIcon(Achievement achievement) {
    final color = _getTierColor(achievement.tier);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getIconData(achievement.iconName),
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildExpandedContent(Achievement achievement) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDetailRow(
              'Reward', '${achievement.rewardPoints} points', Icons.star),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Tier',
            achievement.tier.toString().split('.').last.toUpperCase(),
            Icons.military_tech,
          ),
          if (achievement.isUnlocked) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              'Unlocked',
              achievement.unlockedAt?.toString().split(' ')[0] ?? '',
              Icons.calendar_today,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.grey[400])),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return Colors.orange[300]!;
      case AchievementTier.silver:
        return Colors.grey[400]!;
      case AchievementTier.gold:
        return Colors.amber;
      case AchievementTier.platinum:
        return Colors.blue[300]!;
      case AchievementTier.diamond:
        return Colors.purple[300]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Achievements'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green[800]!,
                Colors.green[600]!,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAchievements,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            RefreshIndicator(
              onRefresh: _loadAchievements,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildStatisticsHeader(),
                        ),
                        const SizedBox(height: 16),
                        _buildSearchAndFilters(),
                      ],
                    ),
                  ),
                  SliverFadeTransition(
                    opacity: _filterAnimation,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildAchievementCard(
                              _filteredAchievements[index]);
                        },
                        childCount: _filteredAchievements.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
