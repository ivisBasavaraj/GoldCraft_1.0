class MaterialIssuance {
  final String id;
  final String transactionId;
  final String jobId;
  final String? jobTitle;
  final String karagarId;
  final String karagarName;
  final double physicalWeightGrams;
  final bool reversed;
  final String? notes;
  final double? managerOcrGrams;
  final double? ocrConfidence;
  final String? ocrImageUrl;
  final DateTime? ocrCapturedAt;
  final DateTime createdAt;

  const MaterialIssuance({
    required this.id,
    required this.transactionId,
    required this.jobId,
    this.jobTitle,
    required this.karagarId,
    required this.karagarName,
    required this.physicalWeightGrams,
    required this.reversed,
    this.notes,
    this.managerOcrGrams,
    this.ocrConfidence,
    this.ocrImageUrl,
    this.ocrCapturedAt,
    required this.createdAt,
  });

  factory MaterialIssuance.fromJson(Map<String, dynamic> json) {
    String toStr(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is Map) return (v[r'$oid'] ?? v['oid'] ?? '').toString();
      return v.toString();
    }

    return MaterialIssuance(
      id: toStr(json['_id']),
      transactionId: json['transactionId'] as String,
      jobId: toStr(json['jobId']),
      jobTitle: json['jobTitle'] as String?,
      karagarId: toStr(json['karagarId']),
      karagarName: json['karagarName'] as String,
      physicalWeightGrams: (json['physicalWeightGrams'] as num? ??
              (json['physicalWeightMg'] as num? ?? 0) / 1000)
          .toDouble(),
      reversed: json['reversed'] as bool? ?? false,
      notes: json['notes'] as String?,
      managerOcrGrams: (json['managerOcrGrams'] as num?)?.toDouble(),
      ocrConfidence: (json['ocrConfidence'] as num?)?.toDouble(),
      ocrImageUrl: json['ocrImageUrl'] as String?,
      ocrCapturedAt: json['ocrCapturedAt'] == null
          ? null
          : DateTime.tryParse(json['ocrCapturedAt'] as String)?.toLocal(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
