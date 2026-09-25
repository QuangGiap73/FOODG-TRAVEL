import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../config/app_scaffold_messenger.dart';
import '../../models/user_notification.dart';
import '../../router/route_names.dart';
import '../../views/notifications/foreground_notification_banner.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  // Firestore de luu token + thong bao
  final _db = FirebaseFirestore.instance;
  // Firebase Messaging de lay token + nhan push
  final _messaging = FirebaseMessaging.instance;

  String? _boundUid;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  OverlayEntry? _foregroundBanner;
  final Map<String, Stream<int>> _unreadCountStreams = {};

  // Bind user de luu token, tranh goi lap lai
  Future<void> bindUser(String? uid) async {
    if (uid == _boundUid) return;
    _boundUid = uid;
    await _tokenSub?.cancel();
    await _foregroundSub?.cancel();
    _removeForegroundBanner();

    if (uid == null) return;

    // Xin quyen thong bao (iOS bat buoc)
    await _messaging.requestPermission();

    // Lay token hien tai
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(uid, token);
    }

    // Khi token thay doi -> cap nhat Firestore
    _tokenSub = _messaging.onTokenRefresh.listen((t) {
      _saveToken(uid, t);
    });

    // Hiển thị banner phía trên khi ứng dụng đang mở (foreground).
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      final payloadTitle = message.notification?.title ?? message.data['title'];
      final payloadBody = message.notification?.body ?? message.data['body'];
      final title = payloadTitle?.toString().trim().isNotEmpty == true
          ? payloadTitle.toString().trim()
          : 'Thông báo mới';
      final body = payloadBody?.toString().trim() ?? '';
      _showForegroundBanner(title: title, body: body);
    });
  }

  void _showForegroundBanner({required String title, required String body}) {
    final overlay = appNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _removeForegroundBanner();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ForegroundNotificationBanner(
        title: title,
        body: body,
        onTap: () {
          appNavigatorKey.currentState?.pushNamed(RouteNames.notifications);
        },
        onDismissed: () {
          if (identical(_foregroundBanner, entry)) {
            _removeForegroundBanner();
          }
        },
      ),
    );
    _foregroundBanner = entry;
    overlay.insert(entry);
  }

  void _removeForegroundBanner() {
    _foregroundBanner?.remove();
    _foregroundBanner = null;
  }

  Future<void> _saveToken(String uid, String token) async {
    // Luu token vao users/{uid}/fcmTokens/{token}
    await _db
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': 'mobile',
    });
  }

  // Stream danh sach thong bao (users/{uid}/notifications)
  Stream<List<UserNotification>> watchNotifications(
    String uid, {
    int limit = 50,
  }) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(UserNotification.fromDoc).toList());
  }

  // Dem thong bao chua doc (badge)
  Stream<int> watchUnreadCount(String uid) {
    return _unreadCountStreams.putIfAbsent(
      uid,
      () => _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .snapshots()
          .map((snap) => snap.docs.length),
    );
  }

  // Danh dau 1 thong bao da doc
  Future<void> markRead({
    required String uid,
    required String notificationId,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .set({'read': true}, SetOptions(merge: true));
  }

  // Danh dau tat ca thong bao da doc
  Future<void> markAllRead(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.set(doc.reference, {'read': true}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> createSystemNotification({
    required String uid,
    required String type,
    required String title,
    required String snippet,
    Map<String, dynamic>? extraData,
  }) async {
    final data = <String, dynamic>{
      'type': type,
      'postId': '',
      'actorId': 'system',
      'actorName': title,
      'actorPhoto': '',
      'snippet': snippet,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    };

    if (extraData != null && extraData.isNotEmpty) {
      data.addAll(extraData);
    }

    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add(data);
  }
}
