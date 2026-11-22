import 'package:flutter/material.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GcScaffold(
      isAdmin: false,
      header: GcPageHeader(
        title: 'Notifications',
        subtitle: 'Alerts and updates',
        showBell: false,
      ),
      body: GcEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'No notifications',
        subtitle: "You're all caught up. New notifications will appear here.",
      ),
    );
  }
}