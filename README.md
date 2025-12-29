# Better & Bliss - Wellness App

A comprehensive wellness and meditation Flutter app with Clean Architecture and BLoC state management.

## Features

- 🧘 **Meditation & Audio** - Guided meditations, sleep sounds, focus music
- 🎬 **Wellness Videos** - Yoga, breathing exercises, mindfulness
- 🎯 **Wellness Goals** - Track daily wellness habits
- 😊 **Mood Tracking** - Check-in and get personalized content
- ⭐ **Premium** - Subscription-based premium features
- 📚 **Library** - Save favorites for offline access

## Architecture

```
lib/
├── core/                    # Shared infrastructure
│   ├── config/              # App & environment configuration
│   ├── navigation/          # GoRouter setup
│   ├── network/             # HTTP client, certificate pinning
│   └── theme/               # App theming
│
└── features/                # Feature modules
    ├── meditation/          # Audio player, categories
    ├── videos/              # Video player, library
    ├── wellness_goals/      # Goals tracking, mood
    ├── library/             # Saved content
    ├── premium/             # Subscription
    └── profile/             # User settings
```

**Pattern:** Clean Architecture + BLoC

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+

### Installation

```bash
# Clone the repository
git clone https://github.com/Ifthikar20/project-gf-mb.git
cd project-gf-mb

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on iOS
cd ios && pod install && cd ..
flutter run
```

### Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit with your values
nano .env
```

## Build

```bash
# Development
flutter run

# Production with obfuscation
./scripts/build_release.sh android
./scripts/build_release.sh ios
```

## Security

- ✅ Environment variables (flutter_dotenv)
- ✅ Secure storage (flutter_secure_storage)
- ✅ Certificate pinning
- ✅ Code obfuscation

## License

MIT License
