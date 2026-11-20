import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inter_c/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:inter_c/features/treasury/domain/treasury_model.dart';

void main() {
  test('maps dashboard API job, payroll, and reserve fields', () {
    final summary = DashboardSummary.fromApiJson(
      {
        'activeKaragars': 8,
        'pendingPayrolls': 3,
        'jobs': {
          'total': 12,
          'byStatus': {
            'assigned': 2,
            'inProgress': 3,
            'qualityCheck': 1,
            'completed': 5,
            'cancelled': 1,
          },
        },
        'advances': {'totalPaidRupees': 5000},
        'payroll': {'totalPaidRupees': 45000},
      },
      {
        'availableGoldGrams': 750,
        'inCirculationGrams': 200,
        'reserveRemainingPercent': 75,
      },
    );

    expect(summary.totalKaragars, 8);
    expect(summary.pendingPayrolls, 3);
    expect(summary.activeJobs, 6);
    expect(summary.assignedJobs, 2);
    expect(summary.inProgressJobs, 3);
    expect(summary.qualityCheckJobs, 1);
    expect(summary.completedJobs, 5);
    expect(summary.totalJobs, 12);
    expect(summary.totalExpensesRupees, 50000);
    expect(summary.treasury.reserveRemainingPercent, 75);
  });

  testWidgets('notifications remain accessible in the empty state',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationsScreen()),
    );

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('No notifications'), findsOneWidget);
  });
}
