import 'package:flutter/material.dart';

import '../../../theme/typography.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTypography.textTheme.titleMedium?.copyWith(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
