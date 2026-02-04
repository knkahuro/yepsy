import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../theme/typography.dart';
import '../models/meal.dart';

class MealTile extends StatelessWidget {
  final Meal meal;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const MealTile({
    super.key,
    required this.meal,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              image: meal.imagePath != null
                  ? DecorationImage(
                      image: meal.imagePath!.startsWith('assets/')
                          ? AssetImage(meal.imagePath!) as ImageProvider
                          : FileImage(File(meal.imagePath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: meal.imagePath == null
                ? const Icon(Icons.fastfood, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(width: 12),
          // Meal Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        meal.title,
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Category Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    meal.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  meal.description,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Rating Stars
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < meal.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 14,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
