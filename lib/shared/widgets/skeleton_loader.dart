import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  factory SkeletonLoader.square({required double size}) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(8),
    );
  }

  factory SkeletonLoader.circle({required double size}) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }

  factory SkeletonLoader.text({
    double width = double.infinity,
    double height = 16,
    BorderRadius? borderRadius,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader.circle(size: 40),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader.text(width: 120),
                  const SizedBox(height: 8),
                  SkeletonLoader.text(width: 80, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SkeletonLoader.text(height: 60),
        ],
      ),
    );
  }
}
