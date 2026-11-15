enum JobStatus { assigned, inProgress, qualityCheck, completed, cancelled }

class Job {
  final String id;
  final String jobNumber;
  final String title;
  final double requiredWeightGrams;
  final DateTime dueDate;
  final JobStatus status;
  final String karagarId;
  final String karagarName;
  final double issuedWeightGrams;
  final double returnedWeightGrams;
  final String? notes;
  final DateTime createdAt;
  final double? managerOcrGrams;
  final double? karagarOcrGrams;
  final bool ocrVerified;

  const Job({
    required this.id,
    required this.jobNumber,
    required this.title,
    required this.requiredWeightGrams,
    required this.dueDate,
    required this.status,
    required this.karagarId,
    required this.karagarName,
    required this.issuedWeightGrams,
    required this.returnedWeightGrams,
    this.notes,
    required this.createdAt,
    this.managerOcrGrams,
    this.karagarOcrGrams,
    this.ocrVerified = false,
  });

  double get outstandingGrams => issuedWeightGrams - returnedWeightGrams;

  String get statusLabel => switch (status) {
        JobStatus.assigned => 'Assigned',
        JobStatus.inProgress => 'Work in Progress',
        JobStatus.qualityCheck => 'Waiting for Checking',
        JobStatus.completed => 'Completed',
        JobStatus.cancelled => 'Cancelled',
      };

  factory Job.fromJson(Map<String, dynamic> json) {
    // ObjectId fields from .lean() can come as { "$oid": "..." } or plain string
    String toStr(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is Map) return (v[r'$oid'] ?? v['oid'] ?? '').toString();
      return v.toString();
    }

    return Job(
      id: toStr(json['_id']),
      jobNumber: json['jobNumber'] as String,
      title: json['title'] as String,
      requiredWeightGrams: (json['requiredWeightGrams'] as num? ?? 0).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: JobStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String),
        orElse: () => JobStatus.assigned,
      ),
      karagarId: toStr(json['karagarId']),
      karagarName: json['karagarName'] as String,
      issuedWeightGrams: (json['issuedWeightGrams'] as num? ?? 0).toDouble(),
      returnedWeightGrams: (json['returnedWeightGrams'] as num? ?? 0).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      managerOcrGrams: (json['managerOcrGrams'] as num?)?.toDouble(),
      karagarOcrGrams: (json['karagarOcrGrams'] as num?)?.toDouble(),
      ocrVerified: json['ocrVerified'] as bool? ?? false,
    );
  }
}
