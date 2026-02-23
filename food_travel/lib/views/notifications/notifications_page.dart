import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_notification.dart';
import '../../services/notifications/notification_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Vui long dang nhap de xem thong bao.')),
      );
    }

    final service = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thong bao'),
        actions: [
          StreamBuilder<int>(
            stream: service.watchUnreadCount(user.uid),
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
              if (unread == 0) return const SizedBox.shrink();
              return TextButton(
                // Danh dau tat ca la da doc
                onPressed: () => service.markAllRead(user.uid),
                child: const Text('Doc het'),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<UserNotification>>(
        stream: service.watchNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <UserNotification>[];
          if (items.isEmpty) {
            return const Center(child: Text('Chua co thong bao nao.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final n = items[index];
              return _NotificationTile(
                item: n,
                onTap: () {
                  // Danh dau da doc
                  service.markRead(uid: user.uid, notificationId: n.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
  });

  final UserNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = item.read == false;
    final title = item.type == 'comment'
        ? '${item.actorName} da binh luan bai viet cua ban'
        : '${item.actorName} da thich bai viet cua ban';
    final timeText = _formatTime(item.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread
              ? const Color(0xFFFFF7ED)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread ? const Color(0xFFFED7AA) : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage:
                  item.actorPhoto.trim().isNotEmpty ? NetworkImage(item.actorPhoto) : null,
              child: item.actorPhoto.trim().isEmpty
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  if (item.type == 'comment' && item.snippet.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${item.snippet}"',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              const Padding(
                padding: EdgeInsets.only(left: 6, top: 6),
                child: Icon(Icons.circle, size: 8, color: Color(0xFFF97316)),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(Timestamp? ts) {
  if (ts == null) return 'vua xong';
  final now = DateTime.now();
  final dt = ts.toDate();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return 'vua xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phut truoc';
  if (diff.inHours < 24) return '${diff.inHours} gio truoc';
  if (diff.inDays < 7) return '${diff.inDays} ngay truoc';
  return '${dt.day}/${dt.month}/${dt.year}';
}
