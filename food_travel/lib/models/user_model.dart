import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? photoUrl;
  final DateTime? createdAt;
  final String role;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.photoUrl,
    this.createdAt,
    this.role = 'user',
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'gender': gender,
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'photoUrl': photoUrl,
      'role': role,
      // createdAt will be set in the service
    };
  }

  /// Parse from Firestore
  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    final dob = data['dateOfBirth'];
    DateTime? dateOfBirth;
    if (dob is Timestamp) {
      dateOfBirth = dob.toDate();
    } else if (dob is DateTime) {
      dateOfBirth = dob;
    }

    return UserModel(
      id: id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      gender: data['gender'],
      dateOfBirth: dateOfBirth,
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      role: (data['role'] as String?) ?? 'user',
    );
  }

  /// Parse from Map (non-Firestore)
  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    final dob = map['dateOfBirth'];
    DateTime? dateOfBirth;
    if (dob is Timestamp) {
      dateOfBirth = dob.toDate();
    } else if (dob is DateTime) {
      dateOfBirth = dob;
    }

    return UserModel(
      id: id,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      gender: map['gender'],
      dateOfBirth: dateOfBirth,
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      role: (map['role'] as String?) ?? 'user',
    );
  }
}
