import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

class Username3DDialog extends StatefulWidget {
  final String? initialUsername;
  
  const Username3DDialog({
    super.key, 
    this.initialUsername,
  });

  @override
  State<Username3DDialog> createState() => _Username3DDialogState();
}

class _Username3DDialogState extends State<Username3DDialog> with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  String? _errorText;
  bool _isChecking = false;
  bool _isValid = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  final _formKey = GlobalKey<FormState>();
  
  // Enhanced inappropriate words list
  final List<String> _inappropriateWords = [
    'profanity', 'slur', 'offensive', 'inappropriate', 'vulgar',
    'sex', 'pussy', 'fuck'
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
    
    // Initialize bounce animation
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70.0,
      ),
    ]).animate(_bounceController);

    _bounceController.repeat(reverse: true);
  }

  bool _isValidUsername(String username) {
    final RegExp validUsernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    final RegExp phoneNumberRegex = RegExp(r'\d{3,}');
    
    if (!validUsernameRegex.hasMatch(username)) {
      return false;
    }
    
    if (phoneNumberRegex.hasMatch(username)) {
      return false;
    }
    
    if (_containsInappropriateContent(username)) {
      return false;
    }
    
    return true;
  }

  bool _containsInappropriateContent(String username) {
    username = username.toLowerCase();
    
    if (_inappropriateWords.contains(username)) {
      return true;
    }
    
    for (String word in _inappropriateWords) {
      if (username.contains(word)) {
        return true;
      }
    }
    
    String leetUsername = _convertToLeetSpeak(username);
    for (String word in _inappropriateWords) {
      if (leetUsername.contains(word)) {
        return true;
      }
    }
    
    return false;
  }

  String _convertToLeetSpeak(String text) {
    return text
      .replaceAll('a', '4')
      .replaceAll('e', '3')
      .replaceAll('i', '1')
      .replaceAll('o', '0')
      .replaceAll('s', '5')
      .replaceAll('t', '7');
  }

  Future<void> _checkUsername(String username) async {
    if (username.isEmpty) {
      setState(() {
        _errorText = 'Username cannot be empty';
        _isValid = false;
      });
      return;
    }

    if (!_isValidUsername(username)) {
      setState(() {
        _errorText = 'Invalid username. Use 3-20 letters, numbers, or underscores.';
        _isValid = false;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorText = null;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    bool isTaken = false; // Replace with actual API call
    
    setState(() {
      _isChecking = false;
      if (isTaken) {
        _errorText = 'This username is already taken';
        _isValid = false;
      } else {
        _isValid = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade900.withOpacity(0.9),
                    Colors.deepPurple.shade800.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title with 3D effect
                  Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(0.01 * math.pi),
                    alignment: FractionalOffset.center,
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.purple.shade300,
                          Colors.pink.shade300,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'Create Your Username',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Username input field with animation
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter username",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        errorText: _errorText,
                        prefixIcon: const Icon(CupertinoIcons.person_alt_circle,
                            color: Colors.white70),
                        suffixIcon: _isChecking
                            ? const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              )
                            : _isValid
                                ? const Icon(Icons.check_circle,
                                    color: Colors.greenAccent)
                                : _errorText != null
                                    ? const Icon(Icons.error,
                                        color: Colors.redAccent)
                                    : null,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors.purpleAccent,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        _checkUsername(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons with gradient
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isValid && !_isChecking
                            ? () {
                                Navigator.of(context).pop(_controller.text);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.disabled)) {
                                return Colors.grey.withOpacity(0.3);
                              }
                              return Colors.purpleAccent;
                            },
                          ),
                        ),
                        child: _isChecking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _bounceController.dispose();
    super.dispose();
  }
}