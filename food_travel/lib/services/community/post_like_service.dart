import 'package:cloud_firestore/cloud_firestore.dart';

class PostLikeService {
  PostLikeService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Collection likes cua 1 bai viet: posts/{postId}/likes
  CollectionReference<Map<String, dynamic>> _postLikes(String postId) {
    return _db.collection('posts').doc(postId).collection('likes');
  }

  // Collection like theo user: users/{uid}/liked_posts
  CollectionReference<Map<String, dynamic>> _userLikes(String uid) {
    return _db.collection('users').doc(uid).collection('liked_posts');
  }

  // Stream danh sach postId da like (de UI check nhanh)
  Stream<Set<String>> watchLikedPostIds(String uid) {
    return _userLikes(uid).snapshots().map((snap) {
      return snap.docs.map((d) => d.id).toSet();
    });
  }

  // Toggle like/unlike + cap nhat likeCount trong 1 transaction
  Future<void> toggleLike({
    required String uid,
    required String postId,
  }) async {
    final postRef = _db.collection('posts').doc(postId);
    final likeRef = _postLikes(postId).doc(uid);
    final userLikeRef = _userLikes(uid).doc(postId);

    await _db.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) return;

      final likeSnap = await tx.get(likeRef);
      final current =
          (postSnap.data()?['likeCount'] as num?)?.toInt() ?? 0;

      if (likeSnap.exists) {
        // Neu da like -> bo like
        final next = current > 0 ? current - 1 : 0;
        tx.delete(likeRef);
        tx.delete(userLikeRef);
        tx.update(postRef, {'likeCount': next});
      } else {
        // Neu chua like -> them like
        final next = current + 1;
        tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        tx.set(userLikeRef, {'createdAt': FieldValue.serverTimestamp()});
        tx.update(postRef, {'likeCount': next});
      }
    });
  }
}
