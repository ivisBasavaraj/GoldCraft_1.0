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
      openingReserveGrams: (json['openingReserveGrams'] as num? ?? 0).toDouble(),
      availableGoldGrams: (json['availableGoldGrams'] as num? ?? 0).toDouble(),
      issuedGoldGrams: (json['issuedGoldGrams'] as num? ?? 0).toDouble(),
      returnedGoldGrams: (json['returnedGoldGrams'] as num? ?? 0).toDouble(),
      inCirculationGrams: (json['inCirculationGrams'] as num? ?? 0).toDouble(),
      reserveRemainingPercent: (json['reserveRemainingPercent'] as num? ?? 0).toDouble(),
    );
  }
}

class DashboardSummary {
  final int totalKaragars;
  final int totalJobs;
  final Map<String, int> jobsByStatus;
  final double totalGoldIssuedGrams;
  final double totalGoldReturnedGrams;
  final double inCirculationGrams;
  final double totalAdvancePaidRupees;
  final double outstandingAdvanceRupees;
  final double totalSalaryRupees;
  final int pendingPayrollCount;
  final TreasurySummary treasury;

  const DashboardSummary({
    required this.totalKaragars,
    required this.totalJobs,
    required this.jobsByStatus,
    required this.totalGoldIssuedGrams,
    required this.totalGoldReturnedGrams,
    required this.inCirculationGrams,
    required this.totalAdvancePaidRupees,
    required this.outstandingAdvanceRupees,
    required this.totalSalaryRupees,
    required this.pendingPayrollCount,
    required this.treasury,
  });

  static DashboardSummary fromApiJson(
    Map<String, dynamic> dashboard,
    Map<String, dynamic> treasuryJson,
  ) {
    final gold = dashboard['gold'] as Map<String, dynamic>? ?? {};
    final jobs = dashboard['jobs'] as Map<String, dynamic>? ?? {};
    final rawStatuses = jobs['byStatus'] as Map<String, dynamic>? ?? {};
    final advances = dashboard['advances'] as Map<String, dynamic>? ?? {};
    final payroll = dashboard['payroll'] as Map<String, dynamic>? ?? {};

    return DashboardSummary(
      totalKaragars: dashboard['activeKaragars'] as int? ?? 0,
      totalJobs: (jobs['total'] as num? ?? 0).toInt(),
      jobsByStatus: rawStatuses.map(
        (key, value) => MapEntry(key, (value as num? ?? 0).toInt()),
      ),
      totalGoldIssuedGrams: (gold['totalIssuedGrams'] as num? ?? 0).toDouble(),
      totalGoldReturnedGrams:
          (gold['totalReturnedGrams'] as num? ?? 0).toDouble(),
      inCirculationGrams:
          (gold['inCirculationGrams'] as num? ?? 0).toDouble(),
      totalAdvancePaidRupees: (advances['totalPaidRupees'] as num?
              ?? advances['totalOutstandingRupees'] as num?
              ?? 0)
          .toDouble(),
      outstandingAdvanceRupees:
          (advances['totalOutstandingRupees'] as num? ?? 0).toDouble(),
      totalSalaryRupees: (payroll['totalPaidRupees'] as num?
              ?? payroll['totalNetPayableRupees'] as num?
              ?? dashboard['totalSalaryRupees'] as num?
              ?? 0)
          .toDouble(),
      pendingPayrollCount: (payroll['pendingCount'] as num? ??
              dashboard['pendingPayrolls'] as num? ??
              0)
          .toInt(),
      treasury: TreasurySummary.fromJson(treasuryJson),
    );
  }
}
