import 'package:equatable/equatable.dart';

enum UserRole { buyer, organizer }

class UserModel extends Equatable {
  final String id;
  final String? phone;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final UserRole role;
  final DateTime createdAt;
  final bool isVerified;

  const UserModel({
    required this.id,
    this.phone,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.role = UserRole.buyer,
    required this.createdAt,
    this.isVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: (json['role'] as String?) == 'organizer'
          ? UserRole.organizer
          : UserRole.buyer,
      createdAt: DateTime.parse(json['created_at'] as String),
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'role': role == UserRole.organizer ? 'organizer' : 'buyer',
        'created_at': createdAt.toIso8601String(),
        'is_verified': isVerified,
      };

  UserModel copyWith({
    String? id,
    String? phone,
    String? email,
    String? fullName,
    String? avatarUrl,
    UserRole? role,
    DateTime? createdAt,
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  String get displayName => fullName ?? phone ?? email ?? 'Utilisateur';

  @override
  List<Object?> get props => [id, phone, email, fullName, role];
}
