// Put this file at: lib/shared/widgets/gc_ui.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// -----------------------------------------------------------------------------
// Shared palette for manager, admin, and karagar screens.
// -----------------------------------------------------------------------------
class GcUi {
  static const bg = Color(0xFFFBF8F3);
  static const ink = Color(0xFF0F2A1D);
  static const muted = Color(0xFF6B7280);
  static const hint = Color(0xFF9CA3AF);
  static const greenDark = Color(0xFF0B4D32);
  static const green = Color(0xFF117A4D);
  static const greenTint = Color(0xFFE6F2EA);
  static const gold = Color(0xFFE7B53A);
  static const goldDark = Color(0xFFB7791F);
  static const goldTint = Color(0xFFFBF0D9);
  static const ivory = Color(0xFFFFF8EA);
  static const track = Color(0xFFE7ECE8);
  static const border = Color(0xFFEDE8DF);

  // NEW: semantic colors for errors / info (replace GoldCraftColors.soft*)
  static const red = Color(0xFFB42318);
  static const redTint = Color(0xFFFDECEA);
  static const blue = Color(0xFF1D5FA8);
  static const blueTint = Color(0xFFE7F0FA);

  static Color bgFor(bool _) => bg;
  static Color primary(bool _) => greenDark;
  static Color accent(bool _) => green;

  static List<Color> heroGradient(bool _) =>
      const [Color(0xFF0E6B43), Color(0xFF083D28)];

  static BoxDecoration card({double radius = 20, Color color = Colors.white}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      );

  /// NEW: one input style for every form in the app.
  static InputDecoration input({
    String? label,
    String? hint,
    IconData? icon,
    Widget? suffix,
    String? prefixText,
  }) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixIcon: icon != null ? Icon(icon, color: muted) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: muted),
      hintStyle: const TextStyle(color: GcUi.hint),
      border: b(border),
      enabledBorder: b(border),
      focusedBorder: b(green, 1.6),
      errorBorder: b(red),
      focusedErrorBorder: b(red, 1.6),
    );
  }
}

// -----------------------------------------------------------------------------
// NEW: themed snackbar. Use instead of ScaffoldMessenger...showSnackBar.
// -----------------------------------------------------------------------------
void gcSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? GcUi.red : GcUi.greenDark,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
}

// -----------------------------------------------------------------------------
// NEW: cream background with soft gold waves (also used by Login)
// -----------------------------------------------------------------------------
class GcWaveBackground extends StatelessWidget {
  final Widget child;
  const GcWaveBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _WavePainter()),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Page shell: cream background + soft gold waves + header + body + bottom nav
// -----------------------------------------------------------------------------
class GcScaffold extends StatelessWidget {
  final bool isAdmin;
  final Widget header;
  final Widget body;
  final Widget? bottomNav;
  final Widget? floatingActionButton;

  const GcScaffold({
    super.key,
    required this.isAdmin,
    required this.header,
    required this.body,
    this.bottomNav,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GcUi.bgFor(isAdmin),
      bottomNavigationBar: bottomNav,
      floatingActionButton: floatingActionButton,
      body: GcWaveBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: header,
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // bottom waves
    for (int i = 0; i < 6; i++) {
      final y = size.height * 0.84 + i * 6.0;
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(size.width * 0.3, y - 60 + i * 4, size.width * 0.6,
            y + 50 - i * 3, size.width, y - 30);
      p.color = GcUi.gold.withValues(alpha: 0.26 - i * 0.035);
      canvas.drawPath(path, p);
    }
    // top-right waves
    for (int i = 0; i < 4; i++) {
      final y = 20.0 + i * 7;
      final path = Path()
        ..moveTo(size.width * 0.45, y)
        ..cubicTo(size.width * 0.65, y + 50, size.width * 0.85, y - 20,
            size.width, y + 40);
      p.color = GcUi.gold.withValues(alpha: 0.2 - i * 0.04);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// Header: back arrow, title with gold underline, optional actions, bell
// -----------------------------------------------------------------------------
class GcPageHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool showBell;
  final String? subtitle;

  const GcPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.showBell = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: GcUi.ink),
            tooltip: 'Back',
            onPressed: onBack ?? () => context.pop(),
          ),
        if (showBack) const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: GcUi.ink,
                  height: 1.15,
                ),
              ),
              if (subtitle != null)
                Text(subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: GcUi.muted)),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: GcUi.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        for (final a in actions) ...[a, const SizedBox(width: 8)],
        if (showBell)
          GcCircleButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
      ],
    );
  }
}

class GcCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const GcCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 46,
            child: Icon(icon, color: color ?? GcUi.ink, size: 24),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Bottom navigation: identical to the dashboard. Use currentIndex = -1 for a
// page that is not one of the five tabs.
// -----------------------------------------------------------------------------
class GcBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isAdmin;
  const GcBottomNav({super.key, required this.currentIndex, this.isAdmin = false});

  static const _routes = [
    '/dashboard',
    '/karagars',
    '/jobs',
    '/treasury',
    '/reports',
  ];

  static const _items = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    (Icons.people_outline, Icons.people_rounded, 'Karagars'),
    (Icons.work_outline_rounded, Icons.work_rounded, 'Jobs'),
    (Icons.account_balance_outlined, Icons.account_balance_rounded, 'Treasury'),
    (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Reports'),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = GcUi.primary(isAdmin);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: GcUi.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            for (int i = 0; i < _items.length; i++)
              i == currentIndex
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_items[i].$2, color: Colors.white, size: 24),
                          const SizedBox(height: 2),
                          Text(_items[i].$3,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Container(
                            width: 24,
                            height: 2,
                            decoration: BoxDecoration(
                              color: GcUi.gold,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () => context.go(_routes[i]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_items[i].$1, color: GcUi.muted, size: 24),
                              const SizedBox(height: 2),
                              Text(_items[i].$3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: GcUi.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Two/three-way pill toggle (e.g. "Issued to Me" | "Returned")
// -----------------------------------------------------------------------------
class GcSegmentToggle extends StatelessWidget {
  final List<String> labels;
  final List<IconData> icons;
  final int index;
  final ValueChanged<int> onChanged;
  final bool isAdmin;

  const GcSegmentToggle({
    super.key,
    required this.labels,
    required this.icons,
    required this.index,
    required this.onChanged,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = GcUi.primary(isAdmin);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(5),
      decoration: GcUi.card(radius: 30, color: GcUi.ivory),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: i == index ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: i == index
                        ? const [
                            BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 8,
                                offset: Offset(0, 3))
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[i],
                          size: 20,
                          color: i == index ? Colors.white : GcUi.ink),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: i == index ? Colors.white : GcUi.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// NEW shared building blocks used by the form / list / detail screens
// =============================================================================

/// Section label above a field group.
class GcSectionLabel extends StatelessWidget {
  final String text;
  const GcSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: GcUi.ink)),
      );
}

/// Full-width green pill button with built-in loading state.
class GcPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const GcPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: GcUi.greenDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: GcUi.greenDark.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Small rounded status/role pill.
class GcPill extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  const GcPill({super.key, required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: fg)),
      );
}

/// Rounded square icon tile (avatars, list leading icons).
class GcIconTile extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final Color fg;
  final Color bg;
  final double size;
  const GcIconTile({
    super.key,
    this.icon,
    this.text,
    required this.fg,
    required this.bg,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(size * 0.3)),
        child: Center(
          child: icon != null
              ? Icon(icon, color: fg, size: size * 0.5)
              : Text(text ?? '',
                  style: TextStyle(
                      fontSize: size * 0.42,
                      fontWeight: FontWeight.w800,
                      color: fg)),
        ),
      );
}

/// Inline info / warning banner.
class GcBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color fg;
  final Color bg;
  const GcBanner({
    super.key,
    required this.icon,
    required this.text,
    this.fg = GcUi.blue,
    this.bg = GcUi.blueTint,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: fg)),
          ),
        ]),
      );
}

/// Selectable pill (payment mode, melting group...).
class GcChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const GcChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? GcUi.greenDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? GcUi.greenDark : GcUi.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : GcUi.ink)),
        ),
      );
}