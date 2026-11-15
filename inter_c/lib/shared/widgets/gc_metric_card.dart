import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class GcMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback? onTap;

  const GcMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor = GoldCraftColors.jewelryGold,
    this.iconBg = GoldCraftColors.jewelryGoldLight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: GoldCraftColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GoldCraftColors.divider),
          boxShadow: const [
            BoxShadow(
              color: GoldCraftColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: GoldCraftColors.textHint),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: GoldCraftColors.charcoal,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: GoldCraftColors.textSecondary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 11,
                  color: GoldCraftColors.textHint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
