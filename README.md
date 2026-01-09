# Sota Snake Game 🐍

A modern take on the classic snake game, featuring power-ups, leaderboards, daily challenges, and achievements. Built with Flutter for both Android and iOS platforms.

## Features ✨

- **Classic Snake Gameplay**: Classic snake mechanics with smooth controls and responsive design
- **Power-Up System**: Various power-ups including:
  - Speed Boost
  - Score Multiplier
  - Invincibility
  - Slow Motion
- **Daily Challenges**: New tasks generated daily with rewards
- **Global Leaderboards**: Compete with players worldwide
- **Weekly Rankings**: Special weekly competition board
- **Achievement System**: Multiple achievements to unlock
- **Cloud Save**: Progress saved across devices
- **Sound Effects**: Immersive audio experience
- **Modern UI**: Sleek, responsive interface with animations

## Getting Started 🚀

### Prerequisites

- Flutter SDK (>=3.4.3)
- Dart SDK
- Android Studio / Xcode (for mobile deployment)
- Firebase account (for leaderboard functionality)

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/linTruthy/sota_snake_game.git
   ```

2. Navigate to project directory
   ```bash
   cd sota_snake_game
   ```

3. Install dependencies
   ```bash
   flutter pub get
   ```

4. Run the app
   ```bash
   flutter run
   ```

### Firebase Setup

1. Create a new Firebase project
2. Add Android/iOS apps in Firebase console
3. Download and add configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
4. Enable Cloud Firestore in Firebase console

## Game Controls 🎮

- **Swipe Up**: Move snake upward
- **Swipe Down**: Move snake downward
- **Swipe Left**: Move snake left
- **Swipe Right**: Move snake right
- **Pause Button**: Pause/Resume game

## Technical Details 🔧

### Architecture

- **State Management**: Vanilla Flutter State
- **Database**: Cloud Firestore for leaderboards
- **Local Storage**: SharedPreferences for settings and local data
- **Audio**: audioplayers package for sound effects
- **Animations**: Custom animations and Confetti effects

### Key Components

- `SnakeGame`: Main game widget
- `LeaderboardScreen`: Global and weekly rankings
- `PowerUp`: Power-up system implementation
- `DailyTask`: Daily challenge system
- `Achievement`: Achievement tracking

## Contributing 🤝

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License 📝

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments 🙏

- Flutter team for the amazing framework
- Firebase for backend services
- All contributors who have helped improve the game

## Support 💪

If you like this project, please give it a ⭐️ on GitHub!

## Contact 📫

- Developer: Truthy Systems
- Email: truthysys@gmail.com

---
git remote set-url origin https://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@github.com/linTruthy/Sota-Snake-Game.git
Built with ❤️ by Truthy Systems
