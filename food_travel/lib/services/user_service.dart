import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_travel/models/user_model.dart';

class UserService {
  UserService._internal();
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;

  final _db = FirebaseFirestore.instance;
  final String _collection = 'users';

  Future<void> createUser(UserModel user) async {
    await _db.collection(_collection).doc(user.id).set({
      ...user.toMap(),
      'role': user.role.isNotEmpty ? user.role : 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ensureUserRole({required String uid, String role = 'user'}) async {
    await _db
        .collection(_collection)
        .doc(uid)
        .set({'role': role}, SetOptions(merge: true));
  }

  Future<void> updateUserPhotoUrl({
    required String uid,
    required String photoUrl,
  }) async {
    await _db
        .collection(_collection)
        .doc(uid)
        .set({'photoUrl': photoUrl}, SetOptions(merge: true));
  }

  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    await _db.collection(_collection).doc(uid).set({
      'fullName': fullName,
      'phone': phone,
      'gender': gender,
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth) : null,
    }, SetOptions(merge: true));
  }
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection(_collection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.id, doc.data()!);
  }
}
