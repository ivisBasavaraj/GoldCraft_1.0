import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class GcLoadingIndicator extends StatelessWidget {
  final String? message;
  const GcLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: GoldCraftColors.jewelryGold,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: GoldCraftColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GcErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const GcErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: GoldCraftColors.softRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: GoldCraftColors.softRedText,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: GoldCraftColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: GoldCraftColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 160,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GcEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const GcEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: GoldCraftColors.jewelryGoldLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: GoldCraftColors.jewelryGold, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: GoldCraftColors.charcoal,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: GoldCraftColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
