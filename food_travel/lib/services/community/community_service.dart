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
        .map((snap) => snap.docs.map((d) => CommunityPost.fromDoc(d)).toList());
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
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final doc = await _posts.add(payload);
    return doc.id;
  }
}
