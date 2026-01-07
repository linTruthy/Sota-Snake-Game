import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/username_service.dart';

class Username3DDialog extends StatefulWidget {
  final String? initialUsername;

  const Username3DDialog({
    super.key,
    this.initialUsername,
  });

  @override
  State<Username3DDialog> createState() => _Username3DDialogState();
}

class _Username3DDialogState extends State<Username3DDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;

  // Logic State
  String? _statusMessage;
  bool _isChecking = false;
  bool _isValid = false;
  Color _statusColor = Colors.cyanAccent;

  // Animation State
  late AnimationController _appearController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  Timer? _debounceTimer;

  final List<String> _inappropriateWords = [
    'profanity',
    'slur',
    'admin',
    'root',
    'god',
    'system',
    'null'
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
    _statusMessage = "AWAITING INPUT...";

    // Holographic pop-in animation
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnim = CurvedAnimation(
      parent: _appearController,
      curve: Curves.easeOutBack,
    );

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeIn),
    );

    _appearController.forward();
  }

  void _onTextChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    setState(() {
      _isChecking = true;
      _statusMessage = "ANALYZING SYNTAX...";
      _statusColor = Colors.amber;
      _isValid = false;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _validateAndCheck(value);
    });
  }

  Future<void> _validateAndCheck(String username) async {
    // 1. Local Validation (Instant)
    if (username.isEmpty) {
      _setStatus("INPUT REQUIRED", Colors.redAccent, valid: false);
      return;
    }

    final validChars = RegExp(r'^[a-zA-Z0-9_]{3,15}$');
    if (!validChars.hasMatch(username)) {
      _setStatus("INVALID SYNTAX (3-15 CHARS, ALPHANUMERIC)", Colors.redAccent,
          valid: false);
      return;
    }

    // Basic profanity check
    if (_inappropriateWords.any((w) => username.toLowerCase().contains(w))) {
      _setStatus("DENIED: RESERVED WORD", Colors.redAccent, valid: false);
      return;
    }

    // 2. Cloud Validation (Async)
    setState(() => _statusMessage = "CONNECTING TO MAINFRAME...");

    try {
      bool isTaken = await UsernameService.isUsernameTaken(username);
      if (isTaken) {
        _setStatus("IDENTITY ALREADY CLAIMED", Colors.orangeAccent,
            valid: false);
      } else {
        _setStatus("AVAILABLE // READY TO INITIALIZE", const Color(0xFF39FF14),
            valid: true);
      }
    } catch (e) {
      _setStatus("CONNECTION ERROR", Colors.redAccent, valid: false);
    }
  }

  void _setStatus(String msg, Color color, {required bool valid}) {
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _statusMessage = msg;
      _statusColor = color;
      _isValid = valid;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _appearController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dark Overlay with Blur
          Positioned.fill(
            child: GestureDetector(
              onTap: () =>
                  Navigator.of(context).pop(), // Click outside to close?
              child: Container(color: Colors.black87),
            ),
          ),

          Center(
            child: AnimatedBuilder(
              animation: _appearController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: child,
                  ),
                );
              },
              child: _buildHoloTerminal(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoloTerminal() {
    return CustomPaint(
      painter: _SciFiCardPainter(borderColor: _statusColor),
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.terminal, color: _statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "IDENTITY PROTOCOL v2.0",
                  style: TextStyle(
                    color: _statusColor.withOpacity(0.8),
                    fontFamily: 'Courier',
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // The Label
            const Text(
              "ENTER CODENAME:",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),

            // Custom Terminal Input
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                border:
                    Border(bottom: BorderSide(color: _statusColor, width: 2)),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(">",
                        style: TextStyle(color: Colors.white54, fontSize: 18)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      cursorColor: _statusColor,
                      cursorWidth: 10, // Block cursor
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: _onTextChanged,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9_]')),
                        LengthLimitingTextInputFormatter(15),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Status Monitor (Typing Animation logic could go here, simply text for now)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                border: Border.all(color: _statusColor.withOpacity(0.3)),
              ),
              child: Text(
                _isChecking ? "[ $_statusMessage ]" : "$_statusMessage",
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 10,
                  fontFamily: 'Courier',
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "ABORT",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildTechButton(
                  text: "INITIALIZE",
                  isEnabled: _isValid && !_isChecking,
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    Navigator.of(context).pop(_controller.text);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechButton(
      {required String text,
      required bool isEnabled,
      required VoidCallback onTap}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1.0 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isEnabled ? _statusColor : Colors.grey[800],
              // Cut corner on top-right and bottom-left
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                          color: _statusColor.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2))
                    ]
                  : [],
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isEnabled ? Colors.black : Colors.white38,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Painter for the Sci-Fi "Cut Corner" Card
// ---------------------------------------------------------------------------
class _SciFiCardPainter extends CustomPainter {
  final Color borderColor;
  _SciFiCardPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const cut = 20.0;

    final paint = Paint()
      ..color = const Color(0xFF0F0F1A)
          .withOpacity(0.95) // Dark Navy/Black background
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // The Sci-Fi Shape (Cut Top Left, Cut Bottom Right)
    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h - cut)
      ..lineTo(w - cut, h)
      ..lineTo(0, h)
      ..lineTo(0, cut)
      ..close();

    // Draw Fill
    canvas.drawPath(path, paint);

    // Draw Border
    canvas.drawPath(path, borderPaint);

    // Add glowing accent lines
    final accentPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 3;

    // Corner Accents
    canvas.drawLine(
        const Offset(cut - 5, 0), const Offset(cut + 10, 0), accentPaint);
    canvas.drawLine(
        Offset(w - cut + 5, h), Offset(w - cut - 10, h), accentPaint);
  }

  @override
  bool shouldRepaint(covariant _SciFiCardPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}
