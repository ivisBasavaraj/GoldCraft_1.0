import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

enum GoldCraftBadgeType { success, warning, error, info, neutral }

class GoldCraftBadge extends StatelessWidget {
  final String label;
  final GoldCraftBadgeType type;
  final IconData? icon;

  const GoldCraftBadge({
    super.key,
    required this.label,
    this.type = GoldCraftBadgeType.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      GoldCraftBadgeType.success => (GoldCraftColors.softGreen, GoldCraftColors.softGreenText),
      GoldCraftBadgeType.warning => (GoldCraftColors.softAmber, GoldCraftColors.softAmberText),
      GoldCraftBadgeType.error => (GoldCraftColors.softRed, GoldCraftColors.softRedText),
      GoldCraftBadgeType.info => (GoldCraftColors.softBlue, GoldCraftColors.softBlueText),
      GoldCraftBadgeType.neutral => (GoldCraftColors.warmIvory, GoldCraftColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
