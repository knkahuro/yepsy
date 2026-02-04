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

### Meal Tracking

- **Nutrition Log**: Track what you eat with descriptions and ratings.
- **Image Compression**: Automatically compresses high-resolution meal photos to save storage space without losing quality.
- **Categorization**: Categorize meals by Breakfast, Lunch, Dinner, or Snack.

### Sleep Insights

- **Sleep Log**: Track bedtime, wake time, and sleep quality.
- **Analytical Graphs**: Visualize your sleep patterns over time to improve your rest.

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
