import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../data/treasury_provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../core/network/dio_client.dart';

// -----------------------------------------------------------------------------
// API call: POST treasury/adjustment
//
// A dedicated endpoint for adding / removing gold. (PATCH treasury/reserve is
// left alone: it is only for changing the opening reserve.)
//
// The backend does all the maths and validation (it checks the balance, saves
// the transaction and returns the new summary), so the app only sends what the
// user entered:
//   isAdd     -> true = add gold, false = remove gold
//   amountMg  -> positive integer, in milligrams
//   note      -> required by the server when removing
// -----------------------------------------------------------------------------
Future<void> submitTreasuryAdjustment({
  required WidgetRef ref,
  required bool isAdd,
  required int amountMg,
  required String note,
}) async {
  final dio = ref.read(dioProvider);
  try {
    await dio.post('treasury/adjustment', data: {
      'isAdd': isAdd,
      'amountMg': amountMg,
      'note': note,
    });
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}

/// Turns any thrown error into readable text for the form.
String _errorText(Object e) {
  try {
    final m = (e as dynamic).message;
    if (m is String && m.isNotEmpty) return m;
  } catch (_) {}
  return e.toString().replaceFirst('Exception: ', '');
}

class TreasuryScreen extends ConsumerWidget {
  const TreasuryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(treasurySummaryProvider);
    final txAsync = ref.watch(treasuryTransactionsProvider(1));

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to dashboard',
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Treasury Vault'),
      ),
      body: summaryAsync.when(
        loading: () => const GcLoadingIndicator(message: 'Loading treasury...'),
        error: (e, _) => GcErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(treasurySummaryProvider),
        ),
        data: (summary) => RefreshIndicator(
          color: GoldCraftColors.workshopGreen,
          onRefresh: () async {
            ref.invalidate(treasurySummaryProvider);
            ref.invalidate(treasuryTransactionsProvider(1));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      GoldCraftColors.workshopGreenDark,
                      GoldCraftColors.workshopGreen,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Gold',
                        style: TextStyle(fontSize: 13, color: Colors.white54)),
                    const SizedBox(height: 6),
                    Text(
                      '${summary.availableGoldGrams.toStringAsFixed(3)} g',
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (summary.reserveRemainingPercent / 100)
                            .clamp(0.0, 1.0),
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            GoldCraftColors.jewelryGold),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _vaultStat('Opening',
                            '${summary.openingReserveGrams.toStringAsFixed(1)} g'),
                        _vaultStat('Issued',
                            '${summary.issuedGoldGrams.toStringAsFixed(1)} g',
                            color: GoldCraftColors.jewelryGoldLight),
                        _vaultStat('In Circulation',
                            '${summary.inCirculationGrams.toStringAsFixed(1)} g',
                            color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Add / Remove buttons
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Add Gold',
                      icon: Icons.add_circle_outline_rounded,
                      filled: true,
                      color: GoldCraftColors.workshopGreen,
                      onTap: () => _openAdjustSheet(
                        context,
                        isAdd: true,
                        availableGrams: summary.availableGoldGrams,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: 'Remove Gold',
                      icon: Icons.remove_circle_outline_rounded,
                      filled: false,
                      color: GoldCraftColors.softAmberText,
                      onTap: () => _openAdjustSheet(
                        context,
                        isAdd: false,
                        availableGrams: summary.availableGoldGrams,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              const Text('Recent Transactions',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: GoldCraftColors.charcoal)),
              const SizedBox(height: 12),
              txAsync.when(
                loading: () => const GcLoadingIndicator(),
                error: (e, _) => GcErrorState(message: e.toString()),
                data: (data) {
                  final items = data['items'] as List<dynamic>? ?? [];
                  if (items.isEmpty) {
                    return const GcEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Transactions',
                      subtitle: 'Treasury transactions will appear here.',
                    );
                  }
                  return Column(
                    children: items
                        .map((t) => _TxTile(tx: t as Map<String, dynamic>))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAdjustSheet(
    BuildContext context, {
    required bool isAdd,
    required double availableGrams,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GoldCraftColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AdjustTreasurySheet(
        isAdd: isAdd,
        availableGrams: availableGrams,
      ),
    );
  }

  Widget _vaultStat(String label, String value, {Color color = Colors.white}) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );
}

// -----------------------------------------------------------------------------
// Action button (Add / Remove)
// -----------------------------------------------------------------------------
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    const size = Size(0, 52);
    const textStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    if (filled) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: size,
          shape: shape,
          textStyle: textStyle,
          elevation: 0,
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: size,
        shape: shape,
        textStyle: textStyle,
        side: BorderSide(color: color, width: 1.5),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Bottom sheet form
// -----------------------------------------------------------------------------
class _AdjustTreasurySheet extends ConsumerStatefulWidget {
  final bool isAdd;
  final double availableGrams;

  const _AdjustTreasurySheet({
    required this.isAdd,
    required this.availableGrams,
  });

  @override
  ConsumerState<_AdjustTreasurySheet> createState() =>
      _AdjustTreasurySheetState();
}

class _AdjustTreasurySheetState extends ConsumerState<_AdjustTreasurySheet> {
  final _formKey = GlobalKey<FormState>();
  final _gramsCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _gramsCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Color get _accent => widget.isAdd
      ? GoldCraftColors.softGreenText
      : GoldCraftColors.softAmberText;

  Color get _accentBg =>
      widget.isAdd ? GoldCraftColors.softGreen : GoldCraftColors.softAmber;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final grams = double.parse(_gramsCtrl.text.trim());
    final amountMg = (grams * 1000).round();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await submitTreasuryAdjustment(
        ref: ref,
        isAdd: widget.isAdd,
        amountMg: amountMg,
        note: _noteCtrl.text.trim(),
      );

      ref.invalidate(treasurySummaryProvider);
      ref.invalidate(treasuryTransactionsProvider(1));

      // Only close the sheet if it is still open. Without this check, a sheet
      // dismissed mid-request would pop the Treasury screen instead.
      if (mounted) navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isAdd
                ? '${grams.toStringAsFixed(3)} g added to treasury'
                : '${grams.toStringAsFixed(3)} g removed from treasury',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _errorText(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: GoldCraftColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _accentBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isAdd ? Icons.add_rounded : Icons.remove_rounded,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isAdd
                              ? 'Add Gold to Treasury'
                              : 'Remove Gold from Treasury',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: GoldCraftColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Available: ${widget.availableGrams.toStringAsFixed(3)} g',
                          style: const TextStyle(
                            fontSize: 13,
                            color: GoldCraftColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Amount
              TextFormField(
                controller: _gramsCtrl,
                autofocus: true,
                enabled: !_saving,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
                ],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: GoldCraftColors.charcoal,
                ),
                decoration: InputDecoration(
                  labelText: 'Weight',
                  hintText: '0.000',
                  suffixText: 'g',
                  suffixStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: GoldCraftColors.textSecondary,
                  ),
                  // "Max" shortcut only when removing
                  suffixIcon: widget.isAdd
                      ? null
                      : TextButton(
                          onPressed: _saving
                              ? null
                              : () => _gramsCtrl.text =
                                  widget.availableGrams.toStringAsFixed(3),
                          child: const Text('MAX'),
                        ),
                ),
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  if (value == null || value <= 0) {
                    return 'Enter a weight greater than 0';
                  }
                  if ((value * 1000).round() <= 0) {
                    return 'Minimum is 0.001 g';
                  }
                  if (!widget.isAdd && value > widget.availableGrams) {
                    return 'Cannot remove more than available gold';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteCtrl,
                enabled: !_saving,
                maxLines: 2,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText:
                      widget.isAdd ? 'Note (optional)' : 'Reason for removal',
                  hintText: widget.isAdd
                      ? 'e.g. Purchased from supplier'
                      : 'e.g. Returned to supplier',
                ),
                validator: (v) {
                  if (!widget.isAdd && (v ?? '').trim().isEmpty) {
                    return 'Please give a reason';
                  }
                  return null;
                },
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GoldCraftColors.softRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: GoldCraftColors.softRedText,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        foregroundColor: GoldCraftColors.textSecondary,
                        side: const BorderSide(color: GoldCraftColors.border),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.isAdd ? 'Add Gold' : 'Remove Gold'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Transaction tile
// -----------------------------------------------------------------------------
class _TxTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final type = tx['type'] as String? ?? 'transaction';
    final amountMg = (tx['amountMg'] as num).toDouble();
    final balanceMg = (tx['balanceAfterMg'] as num).toDouble();
    final isDebit = amountMg < 0;
    final date = DateTime.parse(tx['createdAt'] as String).toLocal();
    final note = (tx['note'] as String?)?.trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GoldCraftColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GoldCraftColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDebit
                  ? GoldCraftColors.softAmber
                  : GoldCraftColors.softGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDebit
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isDebit
                  ? GoldCraftColors.softAmberText
                  : GoldCraftColors.softGreenText,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['description'] as String? ?? type,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: GoldCraftColors.charcoal)),
                Text(DateFormat('d MMM, HH:mm').format(date),
                    style: const TextStyle(
                        fontSize: 11, color: GoldCraftColors.textHint)),
                if (note.isNotEmpty)
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: GoldCraftColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDebit ? '-' : '+'}${(amountMg.abs() / 1000).toStringAsFixed(3)} g',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDebit
                        ? GoldCraftColors.softAmberText
                        : GoldCraftColors.softGreenText),
              ),
              Text(
                'Bal: ${(balanceMg / 1000).toStringAsFixed(3)} g',
                style: const TextStyle(
                    fontSize: 11, color: GoldCraftColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
