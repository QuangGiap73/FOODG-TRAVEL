import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhoto,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorPhoto;
  final String text;
  final Timestamp? createdAt;

  factory CommunityComment.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});
    return CommunityComment(
      id: doc.id,
      authorId: (data['authorId'] ?? '').toString(),
      authorName: (data['authorName'] ?? '').toString(),
      authorPhoto: (data['authorPhoto'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] as Timestamp : null,
    );
  }
}
