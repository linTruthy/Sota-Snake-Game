import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class FeedbackManager {
  // Singleton pattern
  static final FeedbackManager _instance = FeedbackManager._internal();
  factory FeedbackManager() => _instance;
  FeedbackManager._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  
  // Settings (bind these to your UserPreferences/SharedPreferences later)
  bool isHapticsEnabled = true;
  bool isSoundEnabled = true;

  Future<void> initialize() async {
    // Preload critical sounds to reduce latency (lag) on first play
    if (isSoundEnabled) {
      // AudioPlayers usually caches by default, but specific preloading 
      // ensures the buffer is ready.
      await _sfxPlayer.setSource(AssetSource('sounds/click.wav'));
      await _sfxPlayer.setSource(AssetSource('sounds/eat.wav'));
      await _sfxPlayer.setSource(AssetSource('sounds/game_over.wav'));
    }
  }

  void move() {
    if (isHapticsEnabled) {
      // Very light vibration on turns
      HapticFeedback.selectionClick();
    }
    // We usually don't play sound on move to avoid annoyance, 
    // but you could add a very quiet 'tick' here.
  }

  void eat() {
    if (isHapticsEnabled) HapticFeedback.mediumImpact();
    if (isSoundEnabled) _playSound('eat.wav');
  }

  void gameOver() {
    if (isHapticsEnabled) HapticFeedback.heavyImpact();
    if (isSoundEnabled) _playSound('game_over.wav');
  }

  void buttonClick() {
    if (isHapticsEnabled) HapticFeedback.lightImpact();
    if (isSoundEnabled) _playSound('click.wav');
  }

  void powerUp() {
    if (isHapticsEnabled) HapticFeedback.vibrate();
    if (isSoundEnabled) _playSound('power_up.wav');
  }

  Future<void> _playSound(String fileName) async {
    // Stop previous sound to ensure punchy overlap if needed
    // or create a pool of players for overlapping sounds
    await _sfxPlayer.stop(); 
    await _sfxPlayer.setSource(AssetSource('sounds/$fileName'));
    await _sfxPlayer.resume();
  }
}