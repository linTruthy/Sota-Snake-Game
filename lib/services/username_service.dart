import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:games_services/games_services.dart' as games_services;

import '../components/username_dialog.dart';
class UsernameService {
  static const String _usernameKey = 'username';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String?> getUsername() async {
    // First try to get cached username
    final prefs = await SharedPreferences.getInstance();
    final cachedUsername = prefs.getString(_usernameKey);
    if (cachedUsername != null) {
      return cachedUsername;
    }

    // Try to get Game Services profile name
    try {
      final isSignedIn = await games_services.GameAuth.isSignedIn;
      if (isSignedIn) {
        final playerName = await games_services.Player.getPlayerName();
        if (playerName != null && playerName.isNotEmpty) {
          // Check if Game Services username is available in our system
          if (await _isValidAndAvailable(playerName)) {
            await setUsername(playerName);
            return playerName;
          }
          
          // If not available, try to create a unique variant
          final uniqueUsername = await _createUniqueVariant(playerName);
          if (uniqueUsername != null) {
            await setUsername(uniqueUsername);
            return uniqueUsername;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting Game Services profile: $e');
      }
    }

    return null;
  }
 // Request username from user with dialog
  static Future<String?> requestUsername(BuildContext context) async {
    final existingUsername = await getUsername();
    if (existingUsername != null) {
      return existingUsername;
    }

    final username = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Username3DDialog();
      },
    );

    if (username != null && username.isNotEmpty) {
      await setUsername(username);
      return username;
    }

    return null;
  }
static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await reserveUsername(username);
  }
    static Future<bool> isUsernameTaken(String username) async {
    final QuerySnapshot result = await _firestore
        .collection('usernames')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }


   static Future<void> reserveUsername(String username) async {
    await _firestore.collection('usernames').add({
      'username': username.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
   static Future<bool> _isValidAndAvailable(String username) async {
    // Check basic validation (3-20 chars, alphanumeric + underscore)
    final RegExp validUsernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    if (!validUsernameRegex.hasMatch(username)) {
      return false;
    }

    // Check availability
    return !(await isUsernameTaken(username));
  }
   static Future<String?> _createUniqueVariant(String baseUsername) async {
    // First try the base username with a random 4-digit number
    for (int i = 0; i < 10; i++) {
      final random = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000))
          .toString();
      final variant = '${baseUsername}_$random';
      
      if (await _isValidAndAvailable(variant)) {
        return variant;
      }
    }

    // If still no success, try with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;
    final finalVariant = '${baseUsername}_$timestamp';
    
    if (await _isValidAndAvailable(finalVariant)) {
      return finalVariant;
    }

    return null;
  }
}
