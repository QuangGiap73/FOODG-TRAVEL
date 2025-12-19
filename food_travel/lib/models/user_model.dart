import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final DateTime? createdAt;
  final String role;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.createdAt,
    this.role = 'user',
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      // createdAt will be set in the service
    };
  }

  /// Parse from Firestore
  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      role: (data['role'] as String?) ?? 'user',
    );
  }

  /// Parse from Map (non-Firestore)
  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      role: (map['role'] as String?) ?? 'user',
    );
  }
}
