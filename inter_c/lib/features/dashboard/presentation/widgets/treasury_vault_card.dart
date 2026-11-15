import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../features/treasury/domain/treasury_model.dart';

class TreasuryVaultCard extends StatelessWidget {
  final TreasurySummary treasury;

  const TreasuryVaultCard({super.key, required this.treasury});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1F0A), Color(0xFF4A3218)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C1F0A).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GoldCraftColors.jewelryGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: GoldCraftColors.jewelryGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Treasury Vault',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: GoldCraftColors.pureWhite,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GoldCraftColors.jewelryGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: GoldCraftColors.jewelryGold.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  '${treasury.reserveRemainingPercent.toStringAsFixed(1)}% remaining',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GoldCraftColors.jewelryGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Available gold — hero number
          Text(
            '${treasury.availableGoldGrams.toStringAsFixed(3)} g',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: GoldCraftColors.pureWhite,
              letterSpacing: -1,
            ),
          ),
          const Text(
            'Available Gold',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: treasury.reserveRemainingPercent / 100,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(GoldCraftColors.jewelryGold),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: [
              _VaultStat(
                label: 'Opening Reserve',
                value: '${treasury.openingReserveGrams.toStringAsFixed(3)} g',
              ),
              _VaultDivider(),
              _VaultStat(
                label: 'Issued',
                value: '${treasury.issuedGoldGrams.toStringAsFixed(3)} g',
                valueColor: const Color(0xFFFFB74D),
              ),
              _VaultDivider(),
              _VaultStat(
                label: 'In Circulation',
                value: '${treasury.inCirculationGrams.toStringAsFixed(3)} g',
                valueColor: const Color(0xFFEF9A9A),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VaultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _VaultStat({
    required this.label,
    required this.value,
    this.valueColor = GoldCraftColors.pureWhite,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
