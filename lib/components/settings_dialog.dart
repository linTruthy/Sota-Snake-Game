import 'package:flutter/material.dart';
import 'dart:ui';

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

class _SettingsDialogState extends State<SettingsDialog> with SingleTickerProviderStateMixin {
  late double _volume;
  late bool _isMusicEnabled;
  late AnimationController _appearController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _volume = widget.initialVolume;
    _isMusicEnabled = widget.initialMusicEnabled;

    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _appearController,
      curve: Curves.easeOutQuad,
    );
    _appearController.forward();
  }

  @override
  void dispose() {
    _appearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          // Blur behind the dialog for focus
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F16).withOpacity(0.95), // Deep dark tech
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  
                  // AUDIO SECTION
                  _buildSectionHeader("AUDIO SUBSYSTEMS"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        _buildTechSlider(
                          label: "MASTER GAIN",
                          value: _volume,
                          onChanged: (val) {
                            setState(() => _volume = val);
                            widget.onVolumeChanged(val);
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTechToggle(
                          label: "BGM STREAM",
                          value: _isMusicEnabled,
                          onChanged: (val) {
                            setState(() => _isMusicEnabled = val);
                            widget.onMusicToggled(val);
                          },
                        ),
                      ],
                    ),
                  ),

                  // GRAPHICS SECTION (Placeholder for future)
                  const SizedBox(height: 10),
                  _buildSectionHeader("VISUAL OPTICS"),
                   Padding(
                    padding: const EdgeInsets.all(20),
                    child: Opacity(
                      opacity: 0.5,
                      child: Text(
                        "// ADDITIONAL MODULES OFFLINE //",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'Courier',
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),

                  // FOOTER BUTTONS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "DISMISS",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                            foregroundColor: Colors.cyanAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            side: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("APPLY CONFIG"),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.cyanAccent.withOpacity(0.2))),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings_suggest, color: Colors.cyanAccent, size: 20),
            const SizedBox(width: 10),
            Text(
              "SYSTEM CONFIGURATION",
              style: TextStyle(
                color: Colors.cyanAccent.withOpacity(0.9),
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "// $title",
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildTechSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              "${(value * 100).toInt()}%",
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 30,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white10),
          ),
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.cyanAccent,
              inactiveTrackColor: Colors.grey[900],
              thumbColor: Colors.white,
              overlayColor: Colors.cyanAccent.withOpacity(0.2),
              trackHeight: 12, // Chunky track
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0), // Hide standard thumb
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
              trackShape: const RectangularSliderTrackShape(),
            ),
            // Custom Stack to create "Segmented" look
            child: Stack(
              children: [
                Slider(
                  value: value,
                  onChanged: onChanged,
                ),
                // Scanlines overlay to make it look segmented
                IgnorePointer(
                  child: Row(
                    children: List.generate(20, (index) {
                      return Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(right: BorderSide(color: Colors.black, width: 2)),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? Colors.cyanAccent.withOpacity(0.5) : Colors.white10,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: value ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            // Custom Sci-Fi Switch
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 20,
              decoration: BoxDecoration(
                color: value ? Colors.cyanAccent : Colors.grey[800],
                borderRadius: BorderRadius.circular(2), // Sharp corners
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: value ? 22 : 2,
                    top: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.rectangle, // Square Toggle for "Tech" feel
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}