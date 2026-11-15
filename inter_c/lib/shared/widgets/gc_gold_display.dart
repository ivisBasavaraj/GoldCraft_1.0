import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class GcGoldWeightDisplay extends StatelessWidget {
  final double weightGrams;
  final String label;
  final bool isLarge;
  final Color? color;

  const GcGoldWeightDisplay({
    super.key,
    required this.weightGrams,
    required this.label,
    this.isLarge = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? GoldCraftColors.jewelryGoldDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: GoldCraftColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: weightGrams.toStringAsFixed(3),
                style: TextStyle(
                  fontSize: isLarge ? 28 : 20,
                  fontWeight: FontWeight.w700,
                  color: displayColor,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: ' g',
                style: TextStyle(
                  fontSize: isLarge ? 16 : 13,
                  fontWeight: FontWeight.w500,
                  color: displayColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GcCurrencyDisplay extends StatelessWidget {
  final double amountPaise;
  final String label;
  final bool isLarge;

  const GcCurrencyDisplay({
    super.key,
    required this.amountPaise,
    required this.label,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final rupees = amountPaise / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: GoldCraftColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '₹',
                style: TextStyle(
                  fontSize: isLarge ? 18 : 14,
                  fontWeight: FontWeight.w600,
                  color: GoldCraftColors.charcoal,
                ),
              ),
              TextSpan(
                text: _formatRupees(rupees),
                style: TextStyle(
                  fontSize: isLarge ? 28 : 20,
                  fontWeight: FontWeight.w700,
                  color: GoldCraftColors.charcoal,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatRupees(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
