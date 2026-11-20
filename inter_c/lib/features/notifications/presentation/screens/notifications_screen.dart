import 'package:flutter/material.dart';
import '../../../../shared/widgets/gc_states.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const GcEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'No notifications',
        subtitle: "You're all caught up. New notifications will appear here.",
      ),
    );
  }
}
