# Finance Wrapped 💸

A personal finance mobile app that transforms your spending data into a personalized, Spotify Wrapped-style recap. Built with Flutter and Firebase.

## Features

- Animated splash screen with custom-drawn logo
- Firebase authentication with persistent sessions
- CSV upload and parsing into structured transaction data
- Spending categorization and analysis engine
- Personalized home dashboard with total spending and category breakdown
- Interactive pie chart overview with spending insights
- Tap-through "Wrapped" experience with 5 slides:
  - Total spending summary
  - Top spending category
  - Earned badges based on spending habits
  - Biggest spending day with vendors
- Mint-themed UI with animated gradient transitions

## Tech Stack

- **Frontend:** Flutter / Dart
- **Backend:** Firebase Authentication
- **State Management:** Lifted state via NavTabManager
- **Data:** CSV parsing, custom DataAnalysis engine

## Screenshots

*coming soon*

## Getting Started

1. Clone the repo
2. Run `flutter pub get`
3. Add your own `firebase_options.dart` to `lib/user_handling/`
4. Run `flutter run`

## Summer Roadmap

- [ ] Firestore persistence for transaction history
- [ ] Multi-month support and trend analysis
- [ ] Real bank CSV format support (Chase, BofA, Capital One)
- [ ] Android APK deployment
- [ ] More Wrapped slides
