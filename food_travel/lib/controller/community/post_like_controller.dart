import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../services/community/post_like_service.dart';

class PostLikeController extends ChangeNotifier {
  PostLikeController({PostLikeService? service})
      : _service = service ?? PostLikeService();

  final PostLikeService _service;

  StreamSubscription<Set<String>>? _sub;
  Set<String> _likedIds = {};
  String? _uid;

  Set<String> get likedIds => _likedIds;

  // Bind uid de listen danh sach bai da like
  void bindUser(String? uid) {
    if (_uid == uid) return;

    _uid = uid;
    _sub?.cancel();
    _likedIds = {};

    if (uid == null) {
      notifyListeners();
      return;
    }

    _sub = _service.watchLikedPostIds(uid).listen((ids) {
      _likedIds = ids;
      notifyListeners();
    });
  }

  bool isLiked(String postId) => _likedIds.contains(postId);

  // Toggle like cho 1 bai
  Future<void> toggleLike(String postId) async {
    final uid = _uid;
    if (uid == null) return;
    await _service.toggleLike(uid: uid, postId: postId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
