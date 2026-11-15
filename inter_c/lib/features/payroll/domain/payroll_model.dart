class Payroll {
  final String id;
  final String karagarId;
  final String karagarName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int jobsDone;
  final double grossLaborRupees;
  final double approvedIncentiveRupees;
  final double approvedPenaltyRupees;
  final double advanceDeductionRupees;
  final double netPayableRupees;
  final double paidRupees;
  final String status;
  final String wastageStatus;
  final double actualWastageGrams;
  final double allowedWastageGrams;
  final String? notes;
  final DateTime createdAt;

  const Payroll({
    required this.id,
    required this.karagarId,
    required this.karagarName,
    required this.periodStart,
    required this.periodEnd,
    required this.jobsDone,
    required this.grossLaborRupees,
    required this.approvedIncentiveRupees,
    required this.approvedPenaltyRupees,
    required this.advanceDeductionRupees,
    required this.netPayableRupees,
    required this.paidRupees,
    required this.status,
    required this.wastageStatus,
    required this.actualWastageGrams,
    required this.allowedWastageGrams,
    this.notes,
    required this.createdAt,
  });

  double get remainingRupees => netPayableRupees - paidRupees;

  factory Payroll.fromJson(Map<String, dynamic> json) {
    // ObjectId can come as plain string or as { "$oid": "..." } from .lean()
    String toStr(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is Map) return (v['\$oid'] ?? v['oid'] ?? '').toString();
      return v.toString();
    }

    // Safely read rupees: prefer the pre-converted *Rupees key, fall back to *Paise/100
    double toRupees(String key, String paiseKey) {
      final r = json[key];
      if (r != null && r is num) return r.toDouble();
      final p = json[paiseKey];
      if (p != null && p is num) return p.toDouble() / 100;
      return 0.0;
    }

    double toGrams(String key, String mgKey) {
      final g = json[key];
      if (g != null && g is num) return g.toDouble();
      final m = json[mgKey];
      if (m != null && m is num) return m.toDouble() / 1000;
      return 0.0;
    }

    return Payroll(
      id: toStr(json['_id']),
      karagarId: toStr(json['karagarId']),
      karagarName: json['karagarName'] as String? ?? '',
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      jobsDone: json['jobsDone'] as int? ?? 0,
      grossLaborRupees: toRupees('grossLaborRupees', 'grossLaborPaise'),
      approvedIncentiveRupees: toRupees('approvedIncentiveRupees', 'approvedIncentivePaise'),
      approvedPenaltyRupees: toRupees('approvedPenaltyRupees', 'approvedPenaltyPaise'),
      advanceDeductionRupees: toRupees('advanceDeductionRupees', 'advanceDeductionPaise'),
      netPayableRupees: toRupees('netPayableRupees', 'netPayablePaise'),
      paidRupees: toRupees('paidRupees', 'paidPaise'),
      status: json['status'] as String? ?? 'draft',
      wastageStatus: json['wastageStatus'] as String? ?? 'withinAllowance',
      actualWastageGrams: toGrams('actualWastageGrams', 'actualWastageMg'),
      allowedWastageGrams: toGrams('allowedWastageGrams', 'allowedWastageMg'),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
