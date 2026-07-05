import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/system_post.dart';

class SystemPostService {
  SystemPostService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('system_posts');

  Stream<List<SystemPost>> watchPublishedPosts({int limit = 10}) {
    return _posts.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map(SystemPost.fromDoc)
          .where((post) => post.isPublished)
          .toList();

      items.sort((a, b) {
        final pinnedCompare = (b.pinned ? 1 : 0).compareTo(a.pinned ? 1 : 0);
        if (pinnedCompare != 0) return pinnedCompare;

        final featuredCompare =
            (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0);
        if (featuredCompare != 0) return featuredCompare;

        final timeA =
            a.updatedAt?.millisecondsSinceEpoch ??
            a.createdAt?.millisecondsSinceEpoch ??
            0;
        final timeB =
            b.updatedAt?.millisecondsSinceEpoch ??
            b.createdAt?.millisecondsSinceEpoch ??
            0;
        return timeB.compareTo(timeA);
      });

      if (items.length <= limit) return items;
      return items.take(limit).toList();
    });
  }

  Stream<SystemPost?> watchPost(String id) {
    return _posts.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      final post = SystemPost.fromDoc(doc);
      if (!post.isPublished) return null;
      return post;
    });
  }
}
