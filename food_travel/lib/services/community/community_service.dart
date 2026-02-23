import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/community/community_post.dart';

class CommunityService {
  CommunityService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  // Latest feed stream
  Stream<List<CommunityPost>> watchLatestPosts({int limit = 20}) {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => CommunityPost.fromDoc(d)).toList();
          // Loc bai da bi xoa mem (status = deleted)
          return list.where((p) => p.status != 'deleted').toList();
        });
  }

  // Stream bai viet cua chinh user
  Stream<List<CommunityPost>> watchMyPosts(String uid, {int limit = 200}) {
    return _posts
        .where('authorId', isEqualTo: uid)
        // Khong orderBy de tranh loi thieu index (se sort o client)
        .limit(limit)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => CommunityPost.fromDoc(d)).toList();
          // An bai da xoa mem
          final visible = list.where((p) => p.status != 'deleted').toList();
          // Sap xep moi nhat o client (createdAt co the null)
          visible.sort((a, b) {
            final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return tb.compareTo(ta);
          });
          return visible;
        });
  }

  // Stream 1 bai viet theo postId (null neu khong ton tai / bi xoa mem)
  Stream<CommunityPost?> watchPost(String postId) {
    return _posts.doc(postId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final post = CommunityPost.fromDoc(doc);
      if (post.status == 'deleted') return null;
      return post;
    });
  }

  // Create a new post
  Future<String> createPost({
    required String text,
    List<PostMedia> media = const [],
    PlaceSnapshot? place,
    String? placeId,
    String? placeSource,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }

    final trimmed = text.trim();
    final isEmptyPost = trimmed.isEmpty && media.isEmpty && place == null;
    if (isEmptyPost) {
      throw Exception('Empty post');
    }

    final authorName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (user.email?.trim().isNotEmpty ?? false)
            ? user.email!.trim()
            : 'FoodG User';

    final payload = <String, dynamic>{
      'authorId': user.uid,
      'authorName': authorName,
      'authorPhoto': user.photoURL ?? '',
      'text': trimmed,
      'media': media.map((e) => e.toMap()).toList(),
      'placeId': placeId,
      'placeSnapshot': place?.toMap(),
      'placeSource': placeSource,
      'likeCount': 0,
      'commentCount': 0,
      'status': 'active', // Tao moi luon active
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final doc = await _posts.add(payload);
    return doc.id;
  }

  // Sua bai viet: text + dia diem (giu nguyen media)
  Future<void> updatePost({
    required String postId,
    required String text,
    PlaceSnapshot? place,
    String? placeId,
    String? placeSource,
    List<PostMedia>? media,
  }) async {
    final trimmed = text.trim();
    final data = <String, dynamic>{
      'text': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (media != null) {
      // Cap nhat danh sach media moi (sau khi sua)
      data['media'] = media.map((e) => e.toMap()).toList();
    }

    if (place == null) {
      // User bo chon dia diem -> xoa fields lien quan
      data['placeId'] = FieldValue.delete();
      data['placeSnapshot'] = FieldValue.delete();
      data['placeSource'] = FieldValue.delete();
    } else {
      // Cap nhat dia diem moi
      data['placeId'] = placeId;
      data['placeSnapshot'] = place.toMap();
      data['placeSource'] = placeSource;
    }

    await _posts.doc(postId).set(data, SetOptions(merge: true));
  }

  // Xoa mem: doi status, khong xoa du lieu that
  Future<void> softDeletePost(String postId) async {
    await _posts.doc(postId).set({
      'status': 'deleted',
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
