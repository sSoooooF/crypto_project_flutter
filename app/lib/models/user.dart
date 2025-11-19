enum Role { guest, user, admin }

class User {
  final String? id;
  final String username;
  final String passwordHash;
  final Role role;
  final DateTime createdAt;

  String? totpSecret;
  bool hasBiometricEnabled;

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.createdAt,
    this.totpSecret,
    this.hasBiometricEnabled = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'passwordHash': passwordHash,
    'role': role.toString().split('.').last,
    'createdAt': createdAt.toIso8601String(),
    'totpSecret': totpSecret,
    'hasBiometricEnabled': hasBiometricEnabled,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    username: json['username'],
    passwordHash: json['passwordHash'],
    role: Role.values.firstWhere(
      (e) => e.toString().split('.').last == json['role'],
    ),
    createdAt: DateTime.parse(json['createdAt']),
    totpSecret: json['totpSecret'],
    hasBiometricEnabled: json['hasBiometricEnabled'] ?? false,
  );

  bool get isGuest => role == Role.guest;
  bool get isUser => role == Role.user;
  bool get isAdmin => role == Role.admin;
}
