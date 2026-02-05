import 'package:flutter/material.dart';
import '../../../theme/typography.dart';

class HowItWorksPage extends StatelessWidget {
  const HowItWorksPage({super.key});

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
          'How It Works',
          style: AppTypography.displayTextTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCycleLogicSection(context),
            const SizedBox(height: 24),
            _buildMagicSection(context),
            const SizedBox(height: 24),
            _buildDisclaimerSection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Important Disclaimers',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '• Not Medical Advice: This application is designed for tracking and informational purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment.',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '• Prediction Accuracy: Cycle and ovulation predictions are estimates based on your logged history. Stress, diet, and health changes can affect accuracy. Do not use for contraception.',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '• Data Security: While we use industrial-grade encryption, you are responsible for keeping your device password and biometric access secure.',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleLogicSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'How Predictions Work',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            context,
            icon: Icons.psychology,
            title: 'Adaptive Learning',
            description:
                'The app learns from your logged data. As you track more cycles, the prediction algorithm automatically adjusts to your unique rhythm for better accuracy.',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            context,
            icon: Icons.security,
            title: 'Local & Private',
            description:
                'All calculations happen right on your phone. Your health data never leaves your device and is encrypted for your eyes only.',
          ),
        ],
      ),
    );
  }

  Widget _buildMagicSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Under the Hood Magic',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            context,
            icon: Icons.delete_forever,
            title: 'Digital Shredder',
            description:
                'When you delete data, we don\'t just hide it. Our Secure Delete Service performs a 3-pass overwrite (DoD standard) to mathematically destroy the information forever.',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            context,
            icon: Icons.monitor_heart,
            title: 'Smart Health Score',
            description:
                'Your health score isn\'t a guess. We calculate a precise weighted inverse score based on your symptom intensity, giving you an accurate 0-100% wellness metric.',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            context,
            icon: Icons.enhanced_encryption,
            title: 'Zero-Knowledge Notes',
            description:
                'Your diary is encrypted with a unique key that stays on your device. Even if someone exported your database, they would only see unreadable gibberish.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context,
      {required IconData icon,
      required String title,
      required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
