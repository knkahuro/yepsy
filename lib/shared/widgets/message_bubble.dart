import 'package:flutter/material.dart';

import '../../theme/typography.dart';

class MessageBubble extends StatelessWidget {
  final String message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          bottomLeft: Radius.circular(2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(-2, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        message,
        style: AppTypography.textTheme.bodyMedium?.copyWith(
          color: Colors.black87,
        ),
      ),
    );
  }
}
