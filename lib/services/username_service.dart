import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsernameService {
  static const String _usernameKey = 'username';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
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
}
