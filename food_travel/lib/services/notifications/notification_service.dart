import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../config/app_scaffold_messenger.dart';
import '../../models/user_notification.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final _db = FirebaseFirestore.instance;
  final _messaging = FirebaseMessaging.instance;

  String? _boundUid;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  // Bind user de luu token, tranh goi lap lai
  Future<void> bindUser(String? uid) async {
    if (uid == _boundUid) return;
    _boundUid = uid;
    await _tokenSub?.cancel();
    await _foregroundSub?.cancel();

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

    // Hien thong bao khi app dang mo (foreground)
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'Thong bao moi';
      final body = message.notification?.body ?? '';
      final messenger = appScaffoldMessengerKey.currentState;
      if (messenger == null) return;
      messenger.showSnackBar(
        SnackBar(content: Text(body.isEmpty ? title : '$title: $body')),
      );
    });
  }

  Future<void> _saveToken(String uid, String token) async {
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

  // Stream danh sach thong bao
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
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
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
}
