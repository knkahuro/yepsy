import 'package:flutter/material.dart';
import '../../../theme/typography.dart';

class VersionFeaturesPage extends StatelessWidget {
  const VersionFeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Version Features',
          style: AppTypography.displayTextTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVersionSection(
              context,
              version: '1.0.0',
              features: {
                'Calendar tracking with period predictions':
                    'Track your menstrual cycle with intelligent predictions based on your history',
                'Symptom logging and analysis':
                    'Log and track symptoms with detailed insights into patterns',
                'Meal tracking with image support':
                    'Document your meals with photos and nutritional information',
                'Sleep tracking and insights':
                    'Monitor your sleep patterns and quality over time',
                'Notes with mood tracking':
                    'Keep personal notes with mood indicators and privacy controls',
                'Cycle insights and predictions':
                    'Get personalized insights about your cycle patterns',
                'Streak tracking and milestones':
                    'Stay motivated with daily logging streaks and achievements',
                'Notification reminders':
                    'Never miss important dates with smart reminders',
                'Biometric lock for privacy':
                    'Secure your data with fingerprint or face recognition',
                'End-to-end encryption':
                    'Your data is encrypted and protected at all times',
                'Data export and import':
                    'Backup and restore your data anytime',
                'Customizable themes':
                    'Choose from multiple color themes to personalize your experience',
                'Offline-first architecture':
                    'All features work seamlessly without internet connection',
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionSection(
    BuildContext context, {
    required String version,
    required Map<String, String> features,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Version $version',
                      style: AppTypography.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Features',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...features.entries
            .map((entry) => _buildFeatureItem(context, entry.key, entry.value)),
      ],
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
