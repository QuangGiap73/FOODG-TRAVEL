import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../models/user_notification.dart';
import '../../services/notifications/notification_service.dart';
import '../community/community_post_detail_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text(t.notificationsSignInRequired)),
      );
    }

    final service = NotificationService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF8FAFC);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return StreamBuilder<List<UserNotification>>(
      stream: service.watchNotifications(user.uid),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <UserNotification>[];
        final unread = items.where((e) => e.read == false).length;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            surfaceTintColor: bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              t.notificationsTitle,
              style: TextStyle(fontWeight: FontWeight.w700, color: titleColor),
            ),
            actions: [
              if (unread > 0)
                TextButton(
                  onPressed: () => service.markAllRead(user.uid),
                  child: Text(t.notificationsMarkAllRead),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _SummaryBar(unread: unread, t: t),
              ),
            ),
          ),
          body: Builder(
            builder: (context) {
              if (snapshot.hasError) {
                return _EmptyState(message: t.notificationsLoadError);
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _NotificationSkeleton();
              }
              if (items.isEmpty) {
                return _EmptyState(message: t.notificationsEmpty);
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final n = items[index];
                  return _NotificationTile(
                    item: n,
                    onTap: () {
                      _openNotification(context, service, user.uid, n);
                    },
                    t: t,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

void _openNotification(
  BuildContext context,
  NotificationService service,
  String uid,
  UserNotification n,
) {
  final t = AppLocalizations.of(context)!;
  if (n.postId.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.notificationMissingPost)),
    );
    return;
  }

  // Danh dau da doc truoc khi mo bai viet
  service.markRead(uid: uid, notificationId: n.id);

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CommunityPostDetailPage(
        postId: n.postId,
        openComments: n.type == 'comment',
      ),
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
    required this.t,
  });

  final UserNotification item;
  final VoidCallback onTap;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final isUnread = item.read == false;
    final isComment = item.type == 'comment';
    final title = item.type == 'comment'
        ? t.notificationCommentTitle(item.actorName)
        : t.notificationLikeTitle(item.actorName);
    final timeText = _formatTime(item.createdAt, t);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isComment ? const Color(0xFF38BDF8) : const Color(0xFFF97316);
    final cardBg = isUnread
        ? (isDark ? const Color(0xFF1A1F27) : const Color(0xFFFFF7ED))
        : (isDark ? const Color(0xFF15181E) : Colors.white);
    final border = isUnread
        ? accent.withOpacity(0.35)
        : (isDark ? const Color(0xFF232A33) : const Color(0xFFE2E8F0));
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subText = isDark ? Colors.white70 : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    isDark ? const Color(0xFF1F2630) : const Color(0xFFE2E8F0),
                backgroundImage: item.actorPhoto.trim().isNotEmpty
                    ? NetworkImage(item.actorPhoto)
                    : null,
                child: item.actorPhoto.trim().isEmpty
                    ? const Icon(Icons.person, size: 18)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isComment
                                ? t.notificationTypeComment
                                : t.notificationTypeLike,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.type == 'comment' && item.snippet.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '"${item.snippet}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          timeText,
                          style: TextStyle(fontSize: 11, color: subText),
                        ),
                        const Spacer(),
                        Icon(
                          isComment
                              ? Icons.chat_bubble_rounded
                              : Icons.favorite_rounded,
                          size: 16,
                          color: accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatTime(Timestamp? ts, AppLocalizations t) {
  if (ts == null) return t.timeJustNow;
  final now = DateTime.now();
  final dt = ts.toDate();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return t.timeJustNow;
  if (diff.inMinutes < 60) return t.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return t.timeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return t.timeDaysAgo(diff.inDays);
  final dateText = '${dt.day}/${dt.month}/${dt.year}';
  return t.timeOnDate(dateText);
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.unread, required this.t});

  final int unread;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF15181E) : Colors.white;
    final border =
        isDark ? const Color(0xFF232A33) : const Color(0xFFE2E8F0);
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final sub = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_none_rounded,
              size: 18, color: Color(0xFFF97316)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              unread == 0
                  ? t.notificationsSummaryNone
                  : t.notificationsSummaryUnread(unread),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: text,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            t.notificationsTodayLabel,
            style: TextStyle(fontSize: 11, color: sub),
          ),
        ],
      ),
    );
  }
}

class _NotificationSkeleton extends StatelessWidget {
  const _NotificationSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF8FAFC);
    final skeleton = isDark ? const Color(0xFF1F2630) : const Color(0xFFE2E8F0);

    return Container(
      color: bg,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: skeleton,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 8,
                        width: 180,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    return Center(
      child: Text(message, style: TextStyle(color: textColor)),
    );
  }
}
