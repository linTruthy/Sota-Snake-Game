import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/username_service.dart';

class UsernameDialog extends StatefulWidget {
  final String? initialUsername;

  const UsernameDialog({super.key, this.initialUsername});

  @override
  State<UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<UsernameDialog> {
  late TextEditingController _controller;
  String? _errorText;
  bool _isChecking = false;

  // List of inappropriate words (this should be more comprehensive in a real application)
  final List<String> _inappropriateWords = [
    'profanity', 'slur', 'offensive', 'inappropriate', 'vulgar','sex','pussy','fuck'
    // Add more inappropriate words here
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
  }

  bool _isValidUsername(String username) {
    // Username must be 3-20 characters long, contain only letters, numbers, and underscores
    final RegExp validUsernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    
    // Check for potential phone numbers
    final RegExp phoneNumberRegex = RegExp(r'\d{3,}');
    
    if (!validUsernameRegex.hasMatch(username)) {
      return false;
    }
    
    if (phoneNumberRegex.hasMatch(username)) {
      return false;
    }
    
    // Check for inappropriate content
    if (_containsInappropriateContent(username)) {
      return false;
    }
    
    return true;
  }

  bool _containsInappropriateContent(String username) {
    username = username.toLowerCase();
    
    // Check for exact matches
    if (_inappropriateWords.contains(username)) {
      return true;
    }
    
    // Check for partial matches
    for (String word in _inappropriateWords) {
      if (username.contains(word)) {
        return true;
      }
    }
    
    // Check for l33t speak
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
      });
      return;
    }

    if (!_isValidUsername(username)) {
      setState(() {
        _errorText = 'Invalid username. Use 3-20 letters, numbers, or underscores. Avoid inappropriate content.';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorText = null;
    });

    bool isTaken = await UsernameService.isUsernameTaken(username);

    setState(() {
      _isChecking = false;
      if (isTaken) {
        _errorText = 'This username is already taken';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialUsername == null ? 'Enter Your Username' : 'Change Username'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: "Enter username",
              errorText: _errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(CupertinoIcons.person),
            ),
            autofocus: true,
            onChanged: (value) {
              _checkUsername(value);
            },
          ),
          if (_isChecking)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: _errorText == null && !_isChecking
              ? () async {
                  if (_controller.text.isNotEmpty) {
                    await UsernameService.reserveUsername(_controller.text);
                    Navigator.of(context).pop(_controller.text);
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Theme.of(context).primaryColor,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}