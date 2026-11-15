class MaterialReceipt {
  final String id;
  final String transactionId;
  final String jobId;
  final String karagarId;
  final String karagarName;
  final String receiptType;
  final double physicalWeightGrams;
  final bool reversed;
  final String? notes;
  final DateTime createdAt;

  const MaterialReceipt({
    required this.id,
    required this.transactionId,
    required this.jobId,
    required this.karagarId,
    required this.karagarName,
    required this.receiptType,
    required this.physicalWeightGrams,
    required this.reversed,
    this.notes,
    required this.createdAt,
  });

  factory MaterialReceipt.fromJson(Map<String, dynamic> json) {
    return MaterialReceipt(
      id: json['_id'] as String,
      transactionId: json['transactionId'] as String,
      jobId: json['jobId'] as String,
      karagarId: json['karagarId'] as String,
      karagarName: json['karagarName'] as String,
      receiptType: json['receiptType'] as String,
      physicalWeightGrams: (json['physicalWeightGrams'] as num? ??
              (json['physicalWeightMg'] as num? ?? 0) / 1000)
          .toDouble(),
      reversed: json['reversed'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
