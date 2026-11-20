class TreasurySummary {
  final double openingReserveGrams;
  final double availableGoldGrams;
  final double issuedGoldGrams;
  final double returnedGoldGrams;
  final double inCirculationGrams;
  final double reserveRemainingPercent;

  const TreasurySummary({
    required this.openingReserveGrams,
    required this.availableGoldGrams,
    required this.issuedGoldGrams,
    required this.returnedGoldGrams,
    required this.inCirculationGrams,
    required this.reserveRemainingPercent,
  });

  factory TreasurySummary.fromJson(Map<String, dynamic> json) {
    return TreasurySummary(
      openingReserveGrams:
          (json['openingReserveGrams'] as num? ?? 0).toDouble(),
      availableGoldGrams: (json['availableGoldGrams'] as num? ?? 0).toDouble(),
      issuedGoldGrams: (json['issuedGoldGrams'] as num? ?? 0).toDouble(),
      returnedGoldGrams: (json['returnedGoldGrams'] as num? ?? 0).toDouble(),
      inCirculationGrams: (json['inCirculationGrams'] as num? ?? 0).toDouble(),
      reserveRemainingPercent:
          (json['reserveRemainingPercent'] as num? ?? 0).toDouble(),
    );
  }
}

class DashboardSummary {
  final int totalKaragars;
  final int activeJobs;
  final int pendingPayrolls;
  final int assignedJobs;
  final int inProgressJobs;
  final int qualityCheckJobs;
  final int completedJobs;
  final int totalJobs;
  final double totalGoldIssuedGrams;
  final double totalAdvancePaidRupees;
  final double totalSalaryRupees;
  final TreasurySummary treasury;

  const DashboardSummary({
    required this.totalKaragars,
    required this.activeJobs,
    required this.pendingPayrolls,
    required this.assignedJobs,
    required this.inProgressJobs,
    required this.qualityCheckJobs,
    required this.completedJobs,
    required this.totalJobs,
    required this.totalGoldIssuedGrams,
    required this.totalAdvancePaidRupees,
    required this.totalSalaryRupees,
    required this.treasury,
  });

  double get totalExpensesRupees => totalSalaryRupees + totalAdvancePaidRupees;

  static DashboardSummary fromApiJson(
    Map<String, dynamic> dashboard,
    Map<String, dynamic> treasuryJson,
  ) {
    final gold = dashboard['gold'] as Map<String, dynamic>? ?? {};
    final advances = dashboard['advances'] as Map<String, dynamic>? ?? {};
    final payroll = dashboard['payroll'] as Map<String, dynamic>? ?? {};
    final jobs = dashboard['jobs'] as Map<String, dynamic>? ?? {};
    final jobsByStatus = jobs['byStatus'] as Map<String, dynamic>? ?? {};
    final assignedJobs = _readCount(jobsByStatus['assigned']);
    final inProgressJobs = _readCount(jobsByStatus['inProgress']);
    final qualityCheckJobs = _readCount(jobsByStatus['qualityCheck']);

    return DashboardSummary(
      totalKaragars: _readCount(dashboard['activeKaragars']),
      activeJobs: assignedJobs + inProgressJobs + qualityCheckJobs,
      pendingPayrolls: _readCount(
        dashboard['pendingPayrolls'] ?? payroll['pendingCount'],
      ),
      assignedJobs: assignedJobs,
      inProgressJobs: inProgressJobs,
      qualityCheckJobs: qualityCheckJobs,
      completedJobs: _readCount(jobsByStatus['completed']),
      totalJobs: _readCount(jobs['total']),
      totalGoldIssuedGrams: (gold['totalIssuedGrams'] as num? ?? 0).toDouble(),
      totalAdvancePaidRupees: (advances['totalPaidRupees'] as num? ??
              advances['totalOutstandingRupees'] as num? ??
              0)
          .toDouble(),
      totalSalaryRupees: (payroll['totalPaidRupees'] as num? ??
              payroll['totalNetPayableRupees'] as num? ??
              dashboard['totalSalaryRupees'] as num? ??
              0)
          .toDouble(),
      treasury: TreasurySummary.fromJson(treasuryJson),
    );
  }
}

int _readCount(Object? value) => value is num ? value.toInt() : 0;
