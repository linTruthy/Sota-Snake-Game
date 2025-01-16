import 'package:flutter/material.dart';

class SettingsDialog extends StatefulWidget {
  final double initialVolume;
  final bool initialMusicEnabled;
  final Function(double) onVolumeChanged;
  final Function(bool) onMusicToggled;

  const SettingsDialog({
    super.key,
    required this.initialVolume,
    required this.initialMusicEnabled,
    required this.onVolumeChanged,
    required this.onMusicToggled,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late double _volume;
  late bool _isMusicEnabled;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _volume = widget.initialVolume;
    _isMusicEnabled = widget.initialMusicEnabled;
    _tabController = TabController(length: 2, vsync: this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildVolumeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Master Volume',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(_volume * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.green,
                inactiveTrackColor: Colors.grey[800],
                thumbColor: Colors.white,
                overlayColor: Colors.green.withOpacity(0.2),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: _volume,
                onChanged: (value) {
                  setState(() {
                    _volume = value;
                    widget.onVolumeChanged(value);
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMusicToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Background Music',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isMusicEnabled = !_isMusicEnabled;
                widget.onMusicToggled(_isMusicEnabled);
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 50,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: _isMusicEnabled ? Colors.green : Colors.grey[700],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: _isMusicEnabled ? 22 : 2,
                    top: 2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[900]!,
                Colors.grey[850]!,
                Colors.grey[900]!,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.grey[800]!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with gradient
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.green, Colors.blue],
                ).createShader(bounds),
                child: const Text(
                  'Game Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.blue],
                    ),
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.volume_up),
                      text: 'Audio',
                    ),
                    Tab(
                      icon: Icon(Icons.settings_brightness),
                      text: 'Display',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tab Content
              SizedBox(
                height: 200,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Audio Settings
                    Column(
                      children: [
                        _buildVolumeSlider(),
                        const SizedBox(height: 16),
                        _buildMusicToggle(),
                      ],
                    ),
                    // Display Settings (placeholder)
                    const Center(
                      child: Text(
                        'Display settings coming soon...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
