enum UserRole { manager, admin, karagar }

class AuthUser {
  final String id;
  final String name;
  final String username;
  final UserRole role;
  final String? employeeCode;
  final String? avatarUrl;

  const AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.employeeCode,
    this.avatarUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['_id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == (json['role'] as String),
        orElse: () => UserRole.karagar,
      ),
      employeeCode: json['employeeCode'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  bool get isManager => role == UserRole.manager;
  bool get isAdmin => role == UserRole.admin;
  bool get isKaragar => role == UserRole.karagar;
  bool get canManageGold => role == UserRole.manager || role == UserRole.admin;
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
