import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/community/community_comment.dart';

class PostCommentService {
  PostCommentService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Collection comments cua 1 bai viet: posts/{postId}/comments
  CollectionReference<Map<String, dynamic>> _commentsRef(String postId) {
    return _db.collection('posts').doc(postId).collection('comments');
  }

  // Stream danh sach comment moi nhat
  Stream<List<CommunityComment>> watchComments(String postId,
      {int limit = 30}) {
    return _commentsRef(postId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(CommunityComment.fromDoc).toList());
  }

  // Them comment + tang commentCount trong 1 transaction
  Future<void> addComment({
    required String postId,
    required String uid,
    required String authorName,
    required String authorPhoto,
    required String text,
  }) async {
    final postRef = _db.collection('posts').doc(postId);
    final commentRef = _commentsRef(postId).doc();

    await _db.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) return;

      final current =
          (postSnap.data()?['commentCount'] as num?)?.toInt() ?? 0;
      final next = current + 1;

      tx.set(commentRef, {
        'authorId': uid,
        'authorName': authorName,
        'authorPhoto': authorPhoto,
        'text': text.trim(),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(postRef, {'commentCount': next});
    });
  }

  // Xoa comment (chi dung cho comment cua chinh user)
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final postRef = _db.collection('posts').doc(postId);
    final commentRef = _commentsRef(postId).doc(commentId);

    await _db.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      final commentSnap = await tx.get(commentRef);
      if (!postSnap.exists || !commentSnap.exists) return;

      final current =
          (postSnap.data()?['commentCount'] as num?)?.toInt() ?? 0;
      final next = current > 0 ? current - 1 : 0;

      tx.delete(commentRef);
      tx.update(postRef, {'commentCount': next});
    });
  }
}
