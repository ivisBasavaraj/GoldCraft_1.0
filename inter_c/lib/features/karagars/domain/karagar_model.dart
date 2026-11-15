class Karagar {
  final String id;
  final String name;
  final String employeeCode;
  final String meltingGroup;
  final String specialization;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final double totalIssuedGrams;
  final double totalReturnedGrams;
  final int activeJobCount;
  final DateTime joinedAt;

  const Karagar({
    required this.id,
    required this.name,
    required this.employeeCode,
    required this.meltingGroup,
    required this.specialization,
    this.phone,
    this.avatarUrl,
    required this.isActive,
    required this.totalIssuedGrams,
    required this.totalReturnedGrams,
    required this.activeJobCount,
    required this.joinedAt,
  });

  double get outstandingCustodyGrams => totalIssuedGrams - totalReturnedGrams;

  factory Karagar.fromJson(Map<String, dynamic> json) {
    return Karagar(
      id: json['_id'] as String,
      name: json['name'] as String,
      employeeCode: json['employeeCode'] as String,
      meltingGroup: json['meltingGroup'] as String,
      specialization: json['specialization'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      totalIssuedGrams: (json['totalIssuedGrams'] as num? ?? 0).toDouble(),
      totalReturnedGrams: (json['totalReturnedGrams'] as num? ?? 0).toDouble(),
      activeJobCount: json['activeJobCount'] as int? ?? 0,
      joinedAt: DateTime.parse((json['joinedAt'] ?? json['createdAt']) as String),
    );
  }
}
