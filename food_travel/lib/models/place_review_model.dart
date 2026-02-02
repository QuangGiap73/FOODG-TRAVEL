import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceReviewModel {
  const PlaceReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;

  factory PlaceReviewModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return PlaceReviewModel(
      id: doc.id,
      userId: (d['userId'] ?? '').toString(),
      userName: (d['userName'] ?? '').toString(),
      userAvatar: (d['userAvatar'] ?? '').toString(),
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      comment: (d['comment'] ?? '').toString(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
