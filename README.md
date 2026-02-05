# Yepsy - Your Personal Wellness & Cycle Tracker

Yepsy is a premium, privacy-focused wellness application designed to help you track your cycle, symptoms, moods, meals, and sleep. With a sleek dark-mode aesthetic and secure, encrypted storage, Yepsy provides deep insights into your physical and mental well-being.

## Key Features

### Cycle Tracking & Predictions

- **Adaptive Learning**: Uses `CycleLearningService` to predict future periods and fertile windows based on your history.
- **Interactive Calendar**: Visualize your cycle with color-coded dates and interactive legends.
- **Symptom Logging**: Track specific symptoms (cramps, acne, mood swings) to find patterns.

### Notes & Moods

- **Daily Reflection**: Log your thoughts and attach moods.
- **Persistent Storage**: All notes are saved securely via `NotesDataService`.
- **Pinning**: Keep important notes at the top of your list.

### Habit Tracking

- **Habit Builder**: Create custom habits with scheduled days and daily reminders.
- **Smart Notifications**: Interactive notifications let you snooze or complete habits instantly.
- **Categorization**: Organize by Work, Wellness, Productivity, and more.

### Analytics Dashboard

- **Unified Scoring**: Track Habits, Mood, and Health on a standardized 0-100% scale.
- **Trend Analysis**: Visualize your consistency and find correlations between your lifestyle and well-being.
- **Health & Mood**: Monitor symptom intensity and emotional trends over time.

### Privacy & Security

- **Biometric Lock**: Protect your data with Fingerprint or FaceID.
- **Encrypted Database**: Uses Hive with AES-256 encryption via `DatabaseService`.
- **Secure Deletion**: Implements multi-pass overwrite for sensitive data disposal via `SecureDeleteService`.

## Architecture

Yepsy follows a feature-driven project structure:

- `lib/core/`: Essential services like encryption, database management, and platform-specific logic.
- `lib/features/`: Modular components (Calendar, Notes, Meals, Sleep) with their own models, widgets, and services.
- `lib/shared/`: Reusable UI components and theme definitions.
- `lib/theme/`: Centralized typography and color palettes.

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / VS Code with Flutter extension

### Installation

1. Clone the repository.
2. Run `flutter pub get` to fetch dependencies.
3. Run `flutter run` on your preferred device.

## 🛠️ Built With

- **Flutter**: UI Framework.
- **Hive**: Blazing fast, local NO-SQL database.
- **GoRouter**: Declarative routing system.
- **TutorialCoachMark**: Interactive onboarding and tutorials.

---
