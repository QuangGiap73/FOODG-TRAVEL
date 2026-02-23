import 'package:cloud_firestore/cloud_firestore.dart';

class UserNotification {
  const UserNotification({
    required this.id,
    required this.type,
    required this.postId,
    required this.actorId,
    required this.actorName,
    required this.actorPhoto,
    required this.snippet,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type; // like | comment
  final String postId;
  final String actorId;
  final String actorName;
  final String actorPhoto;
  final String snippet;
  final bool read;
  final Timestamp? createdAt;

  factory UserNotification.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});
    return UserNotification(
      id: doc.id,
      type: (data['type'] ?? '').toString(),
      postId: (data['postId'] ?? '').toString(),
      actorId: (data['actorId'] ?? '').toString(),
      actorName: (data['actorName'] ?? '').toString(),
      actorPhoto: (data['actorPhoto'] ?? '').toString(),
      snippet: (data['snippet'] ?? '').toString(),
      read: data['read'] == true,
      createdAt:
          data['createdAt'] is Timestamp ? data['createdAt'] as Timestamp : null,
    );
  }
}
