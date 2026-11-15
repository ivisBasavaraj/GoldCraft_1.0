class Advance {
  final String id;
  final String transactionId;
  final String karagarId;
  final String karagarName;
  final double amountRupees;
  final double repaidRupees;
  final bool fullyRepaid;
  final String paymentMode;
  final String? purpose;
  final DateTime createdAt;

  const Advance({
    required this.id,
    required this.transactionId,
    required this.karagarId,
    required this.karagarName,
    required this.amountRupees,
    required this.repaidRupees,
    required this.fullyRepaid,
    required this.paymentMode,
    this.purpose,
    required this.createdAt,
  });

  double get outstandingRupees => amountRupees - repaidRupees;

  factory Advance.fromJson(Map<String, dynamic> json) {
    return Advance(
      id: json['_id'] as String,
      transactionId: json['transactionId'] as String? ?? '',
      karagarId: json['karagarId'] as String,
      karagarName: json['karagarName'] as String? ?? '',
      amountRupees: (json['amountRupees'] as num? ??
              (json['amountPaise'] as num? ?? 0) / 100)
          .toDouble(),
      repaidRupees: (json['repaidRupees'] as num? ??
              (json['repaidPaise'] as num? ?? 0) / 100)
          .toDouble(),
      fullyRepaid: json['fullyRepaid'] as bool? ?? false,
      paymentMode: json['paymentMode'] as String? ?? 'cash',
      purpose: json['purpose'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
