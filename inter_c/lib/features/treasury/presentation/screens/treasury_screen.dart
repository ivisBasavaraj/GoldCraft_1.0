import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../data/treasury_provider.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';
import '../../../../core/network/dio_client.dart';

// -----------------------------------------------------------------------------
// API call: POST treasury/adjustment  (unchanged)
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

// -----------------------------------------------------------------------------
// Transaction filter
// -----------------------------------------------------------------------------
enum TxFilter { all, added, removed }

class TreasuryScreen extends ConsumerStatefulWidget {
  const TreasuryScreen({super.key});

  @override
  ConsumerState<TreasuryScreen> createState() => _TreasuryScreenState();
}

class _TreasuryScreenState extends ConsumerState<TreasuryScreen> {
  TxFilter _filter = TxFilter.all;
  DateTime? _from;
  DateTime? _to;

  bool get _hasFilters =>
      _filter != TxFilter.all || _from != null || _to != null;

  void _clearFilters() => setState(() {
        _filter = TxFilter.all;
        _from = null;
        _to = null;
      });

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = (isFrom ? _from : _to) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      helpText: isFrom ? 'From date' : 'To date',
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        // keep the range valid
        if (_to != null && _to!.isBefore(picked)) _to = picked;
      } else {
        _to = picked;
        if (_from != null && _from!.isAfter(picked)) _from = picked;
      }
    });
  }

  /// Client-side filtering of the already loaded transactions.
  List<Map<String, dynamic>> _applyFilters(List<dynamic> items) {
    final fromStart =
        _from == null ? null : DateTime(_from!.year, _from!.month, _from!.day);
    final toEnd = _to == null
        ? null
        : DateTime(_to!.year, _to!.month, _to!.day, 23, 59, 59, 999);

    return items.map((e) => e as Map<String, dynamic>).where((t) {
      final amountMg = (t['amountMg'] as num).toDouble();
      final isDebit = amountMg < 0;

      if (_filter == TxFilter.added && isDebit) return false;
      if (_filter == TxFilter.removed && !isDebit) return false;

      final date = DateTime.parse(t['createdAt'] as String).toLocal();
      if (fromStart != null && date.isBefore(fromStart)) return false;
      if (toEnd != null && date.isAfter(toEnd)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(treasurySummaryProvider);
    final txAsync = ref.watch(treasuryTransactionsProvider(1));
    final isAdmin = ref.watch(authUserProvider).valueOrNull?.isAdmin == true;
    final accent = GcUi.accent(isAdmin);

    return GcScaffold(
      isAdmin: isAdmin,
      bottomNav: GcBottomNav(currentIndex: 3, isAdmin: isAdmin),
      header: GcPageHeader(
        title: 'Treasury Vault',
        onBack: () => context.go('/dashboard'),
      ),
      body: summaryAsync.when(
        loading: () => const GcLoadingIndicator(message: 'Loading treasury...'),
        error: (e, _) => GcErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(treasurySummaryProvider),
        ),
        data: (summary) => RefreshIndicator(
          color: accent,
          onRefresh: () async {
            ref.invalidate(treasurySummaryProvider);
            ref.invalidate(treasuryTransactionsProvider(1));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Summary hero card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: GcUi.heroGradient(isAdmin),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: GcUi.primary(isAdmin).withValues(alpha: 0.25),
                      blurRadius: 18,
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
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(color: GcUi.gold, width: 1.5),
                          ),
                          child: const Icon(Icons.layers_rounded,
                              color: GcUi.gold, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Available Gold',
                                  style: TextStyle(
                                      fontSize: 15, color: Colors.white70)),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${summary.availableGoldGrams.toStringAsFixed(3)} g',
                                  style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (summary.reserveRemainingPercent / 100)
                            .clamp(0.0, 1.0),
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(GcUi.gold),
                        minHeight: 8,
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
                      color: GcUi.primary(isAdmin),
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
                      color: GcUi.goldDark,
                      onTap: () => _openAdjustSheet(
                        context,
                        isAdd: false,
                        availableGrams: summary.availableGoldGrams,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // Section title + clear filters
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      color: GcUi.primary(isAdmin), size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Recent Transactions',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: GcUi.ink)),
                  ),
                  if (_hasFilters)
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                      label: const Text('Clear'),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Filter bar: All / Added / Removed + From / To dates
              _TxFilterBar(
                filter: _filter,
                from: _from,
                to: _to,
                color: GcUi.primary(isAdmin),
                onFilterChanged: (f) => setState(() => _filter = f),
                onPickFrom: () => _pickDate(isFrom: true),
                onPickTo: () => _pickDate(isFrom: false),
                onClearFrom: () => setState(() => _from = null),
                onClearTo: () => setState(() => _to = null),
              ),
              const SizedBox(height: 12),

              txAsync.when(
                loading: () => const GcLoadingIndicator(),
                error: (e, _) => GcErrorState(message: e.toString()),
                data: (data) {
                  final all = data['items'] as List<dynamic>? ?? [];
                  if (all.isEmpty) {
                    return const GcEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Transactions',
                      subtitle: 'Treasury transactions will appear here.',
                    );
                  }
                  final items = _applyFilters(all);
                  if (items.isEmpty) {
                    return const GcEmptyState(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'No Matching Transactions',
                      subtitle: 'Try changing or clearing the filters.',
                    );
                  }
                  return Column(
                    children: items.map((t) => _TxTile(tx: t)).toList(),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );
}

// -----------------------------------------------------------------------------
// Filter bar (All / Added / Removed chips + From / To date pickers)
// -----------------------------------------------------------------------------
class _TxFilterBar extends StatelessWidget {
  final TxFilter filter;
  final DateTime? from;
  final DateTime? to;
  final Color color;
  final ValueChanged<TxFilter> onFilterChanged;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onClearFrom;
  final VoidCallback onClearTo;

  const _TxFilterBar({
    required this.filter,
    required this.from,
    required this.to,
    required this.color,
    required this.onFilterChanged,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onClearFrom,
    required this.onClearTo,
  });

  Widget _chip(String label, TxFilter value) {
    final selected = filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onFilterChanged(value),
      selectedColor: color,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : GcUi.ink,
      ),
      side: BorderSide(color: selected ? color : GcUi.border),
      shape: const StadiumBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('All', TxFilter.all),
            _chip('Added', TxFilter.added),
            _chip('Removed', TxFilter.removed),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'From',
                date: from,
                color: color,
                onTap: onPickFrom,
                onClear: onClearFrom,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateField(
                label: 'To',
                date: to,
                color: color,
                onTap: onPickTo,
                onClear: onClearTo,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateField({
    required this.label,
    required this.date,
    required this.color,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasDate ? color : GcUi.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 16, color: hasDate ? color : GcUi.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          const TextStyle(fontSize: 11, color: GcUi.muted)),
                  Text(
                    hasDate ? DateFormat('d MMM yyyy').format(date!) : 'Select',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasDate ? GcUi.ink : GcUi.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.close_rounded, size: 18, color: GcUi.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
    final shape = const StadiumBorder();
    const size = Size(0, 54);
    const textStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);

    if (filled) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: size,
          shape: shape,
          textStyle: textStyle,
          elevation: 3,
          shadowColor: Colors.black26,
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: Colors.white,
        minimumSize: size,
        shape: shape,
        textStyle: textStyle,
        side: BorderSide(color: color, width: 1.5),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Bottom sheet form (logic unchanged)
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _accentBg,
                      shape: BoxShape.circle,
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
                            fontWeight: FontWeight.w800,
                            color: GcUi.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Available: ${widget.availableGrams.toStringAsFixed(3)} g',
                          style: const TextStyle(
                            fontSize: 13,
                            color: GcUi.muted,
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
                  color: GcUi.ink,
                ),
                decoration: InputDecoration(
                  labelText: 'Weight',
                  hintText: '0.000',
                  suffixText: 'g',
                  suffixStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: GcUi.muted,
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
                    borderRadius: BorderRadius.circular(12),
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
                        shape: const StadiumBorder(),
                        foregroundColor: GcUi.muted,
                        side: const BorderSide(color: GcUi.border),
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
                        shape: const StadiumBorder(),
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
    final tone =
        isDebit ? GoldCraftColors.softAmberText : GoldCraftColors.softGreenText;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: GcUi.card(radius: 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDebit
                  ? GoldCraftColors.softAmber
                  : GoldCraftColors.softGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDebit
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: tone,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['description'] as String? ?? type,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: GcUi.ink)),
                Text(DateFormat('d MMM, HH:mm').format(date),
                    style: const TextStyle(fontSize: 12, color: GcUi.muted)),
                if (note.isNotEmpty)
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: GcUi.muted),
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
                    fontSize: 15, fontWeight: FontWeight.w800, color: tone),
              ),
              Text(
                'Bal: ${(balanceMg / 1000).toStringAsFixed(3)} g',
                style: const TextStyle(fontSize: 12, color: GcUi.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}