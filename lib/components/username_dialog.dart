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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
  }

  Future<void> _checkUsername(String username) async {
    if (username.isEmpty) {
      setState(() {
        _errorText = 'Username cannot be empty';
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
            ),
            autofocus: true,
            onChanged: (value) {
              _checkUsername(value);
            },
          ),
          if (_isChecking)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: CircularProgressIndicator(),
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
        TextButton(
          onPressed: _errorText == null && !_isChecking
              ? () async {
                  if (_controller.text.isNotEmpty) {
                    await UsernameService.reserveUsername(_controller.text);
                  
                    Navigator.of(context).pop(_controller.text);
                  }
                }
              : null,
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
