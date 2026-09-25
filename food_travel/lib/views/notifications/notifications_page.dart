import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../models/user_notification.dart';
import '../../services/notifications/notification_service.dart';
import '../community/community_post_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  _NotificationFilter _filter = _NotificationFilter.all;

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
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFFFFBF5);
    final titleColor = isDark ? Colors.white : const Color(0xFF1F2937);

    return StreamBuilder<List<UserNotification>>(
      stream: service.watchNotifications(user.uid),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <UserNotification>[];
        final unread = items.where((e) => e.read == false).length;
        final filteredItems = _applyFilter(items, _filter);
        final sections = _buildSections(context, filteredItems);

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            surfaceTintColor: bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              t.notificationsTitle,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: titleColor,
                fontSize: 22,
              ),
            ),
            actions: [
              if (unread > 0)
                TextButton(
                  onPressed: () => service.markAllRead(user.uid),
                  child: Text(t.notificationsMarkAllRead),
                ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (snapshot.hasError) {
                return _EmptyState(
                  message: t.notificationsLoadError,
                  icon: Icons.error_outline_rounded,
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _NotificationSkeleton();
              }

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _OverviewCard(unreadCount: unread, totalCount: items.length),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _FilterBar(
                        selected: _filter,
                        onSelected: (filter) {
                          setState(() => _filter = filter);
                        },
                      ),
                    ),
                  ),
                  if (filteredItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        message: items.isEmpty
                            ? t.notificationsEmpty
                            : _localized(
                                context,
                                vi: 'Không có thông báo phù hợp với bộ lọc này.',
                                en: 'No notifications match this filter.',
                              ),
                        icon: Icons.notifications_off_outlined,
                      ),
                    )
                  else
                    ...sections.expand(
                      (section) => [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              section.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          sliver: SliverList.separated(
                            itemCount: section.items.length,
                            itemBuilder: (context, index) {
                              final item = section.items[index];
                              return _NotificationTile(
                                item: item,
                                onTap: () {
                                  _openNotification(context, service, user.uid, item);
                                },
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                          ),
                        ),
                      ],
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: const _SettingsHintCard(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

enum _NotificationFilter {
  all,
  interaction,
  journey,
  system,
}

class _NotificationSection {
  const _NotificationSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<UserNotification> items;
}

List<UserNotification> _applyFilter(
  List<UserNotification> items,
  _NotificationFilter filter,
) {
  switch (filter) {
    case _NotificationFilter.all:
      return items;
    case _NotificationFilter.interaction:
      return items.where((item) {
        return item.type == 'like' || item.type == 'comment';
      }).toList();
    case _NotificationFilter.journey:
      return items.where((item) {
        return item.type == 'journey_checkin' ||
            item.type == 'journey_checkin_failed' ||
            item.type == 'journey_badge';
      }).toList();
    case _NotificationFilter.system:
      return items.where((item) {
        return item.type != 'like' &&
            item.type != 'comment' &&
            item.type != 'journey_checkin';
      }).toList();
  }
}

List<_NotificationSection> _buildSections(
  BuildContext context,
  List<UserNotification> items,
) {
  final t = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final todayItems = <UserNotification>[];
  final yesterdayItems = <UserNotification>[];
  final olderItems = <UserNotification>[];

  for (final item in items) {
    final createdAt = item.createdAt?.toDate();
    if (createdAt == null) {
      todayItems.add(item);
      continue;
    }

    final date = DateTime(createdAt.year, createdAt.month, createdAt.day);
    if (date == today) {
      todayItems.add(item);
    } else if (date == yesterday) {
      yesterdayItems.add(item);
    } else {
      olderItems.add(item);
    }
  }

  final sections = <_NotificationSection>[];
  if (todayItems.isNotEmpty) {
    sections.add(_NotificationSection(
      title: t.notificationsTodayLabel,
      items: todayItems,
    ));
  }
  if (yesterdayItems.isNotEmpty) {
    sections.add(_NotificationSection(
      title: _localized(context, vi: 'Hôm qua', en: 'Yesterday'),
      items: yesterdayItems,
    ));
  }
  if (olderItems.isNotEmpty) {
    sections.add(_NotificationSection(
      title: _localized(context, vi: 'Trước đó', en: 'Earlier'),
      items: olderItems,
    ));
  }
  return sections;
}

void _openNotification(
  BuildContext context,
  NotificationService service,
  String uid,
  UserNotification notification,
) {
  service.markRead(uid: uid, notificationId: notification.id);

  if (notification.type == 'journey_checkin' ||
      notification.type == 'journey_checkin_failed' ||
      notification.type == 'journey_badge') {
    return;
  }

  final t = AppLocalizations.of(context)!;
  if (notification.postId.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.notificationMissingPost)),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CommunityPostDetailPage(
        postId: notification.postId,
        openComments: notification.type == 'comment',
      ),
    ),
  );
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.unreadCount,
    required this.totalCount,
  });

  final int unreadCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1F27) : const Color(0xFFFFF2DF);
    final titleColor = isDark ? Colors.white : const Color(0xFFB45309);
    final textColor = isDark ? Colors.white70 : const Color(0xFF7C5A27);
    final numberColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFF97316);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD79D),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: 28,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                Positioned(
                  right: -2,
                  top: -4,
                  child: Container(
                    height: 22,
                    constraints: const BoxConstraints(minWidth: 22),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF97316),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unreadCount == 0
                      ? AppLocalizations.of(context)!.notificationsSummaryNone
                      : AppLocalizations.of(context)!
                          .notificationsSummaryUnread(unreadCount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalCount == 0
                      ? _localized(
                          context,
                          vi: 'Thông báo sẽ xuất hiện tại đây khi có hoạt động mới.',
                          en: 'New activity will appear here.',
                        )
                      : _localized(
                          context,
                          vi: 'Cập nhật mới nhất từ cộng đồng và hành trình của bạn.',
                          en: 'Latest updates from the community and your journey.',
                        ),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$totalCount',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: numberColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onSelected,
  });

  final _NotificationFilter selected;
  final ValueChanged<_NotificationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final chips = <(_NotificationFilter, String)>[
      (_NotificationFilter.all, _localized(context, vi: 'Tất cả', en: 'All')),
      (_NotificationFilter.interaction,
        _localized(context, vi: 'Tương tác', en: 'Interactions')),
      (_NotificationFilter.journey,
        _localized(context, vi: 'Hành trình', en: 'Journey')),
      (_NotificationFilter.system,
        _localized(context, vi: 'Hệ thống', en: 'System')),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final chip in chips) ...[
            _FilterChipButton(
              label: chip.$2,
              selected: chip.$1 == selected,
              onTap: () => onSelected(chip.$1),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFF97316)
                : (isDark ? const Color(0xFF15181E) : Colors.white),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFFF97316)
                  : (isDark
                      ? const Color(0xFF232A33)
                      : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF374151)),
            ),
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = _toneFor(context, item);
    final isUnread = item.read == false;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF15181E) : Colors.white;
    final cardBorder = isUnread
        ? tone.color.withValues(alpha: 0.28)
        : (isDark ? const Color(0xFF232A33) : const Color(0xFFF1F5F9));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationLeading(item: item, tone: tone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleFor(context, item),
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    if (_snippetFor(context, item).isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        _snippetFor(context, item),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: subColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tone.softColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tone.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: tone.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatTime(item.createdAt, AppLocalizations.of(context)!),
                            style: TextStyle(fontSize: 12, color: subColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.circle,
                  size: 9,
                  color: isUnread
                      ? tone.color
                      : const Color(0xFFD1D5DB),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationLeading extends StatelessWidget {
  const _NotificationLeading({
    required this.item,
    required this.tone,
  });

  final UserNotification item;
  final _NotificationTone tone;

  @override
  Widget build(BuildContext context) {
    final photo = item.actorPhoto.trim();
    final isInteraction = item.type == 'like' || item.type == 'comment';

    if (isInteraction) {
      if (photo.isNotEmpty) {
        return CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white,
          backgroundImage: NetworkImage(photo),
        );
      }

      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tone.color.withValues(alpha: 0.9),
              tone.color.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          _initialsFor(item.actorName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tone.color.withValues(alpha: 0.18),
            tone.color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(tone.icon, color: tone.color, size: 24),
    );
  }
}

String _initialsFor(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  final first = parts.first.substring(0, 1).toUpperCase();
  final last = parts.last.substring(0, 1).toUpperCase();
  return '$first$last';
}

class _NotificationTone {
  const _NotificationTone({
    required this.color,
    required this.softColor,
    required this.icon,
    required this.label,
  });

  final Color color;
  final Color softColor;
  final IconData icon;
  final String label;
}

_NotificationTone _toneFor(BuildContext context, UserNotification item) {
  late final Color color;
  late final Color softColor;
  late final IconData icon;
  late final String label;

  switch (item.type) {
    case 'comment':
      color = const Color(0xFF2563EB);
      softColor = const Color(0xFFDBEAFE);
      icon = Icons.chat_bubble_rounded;
      label = _localized(context, vi: 'Tương tác', en: 'Interaction');
      break;
    case 'post_pending_review':
      color = const Color(0xFFF59E0B);
      softColor = const Color(0xFFFEF3C7);
      icon = Icons.schedule_rounded;
      label = _localized(context, vi: 'Kiểm duyệt', en: 'Moderation');
      break;
    case 'post_moderation_update':
      color = const Color(0xFF16A34A);
      softColor = const Color(0xFFDCFCE7);
      icon = Icons.verified_rounded;
      label = _localized(context, vi: 'Kiểm duyệt', en: 'Moderation');
      break;
    case 'journey_checkin':
      color = const Color(0xFF16A34A);
      softColor = const Color(0xFFDCFCE7);
      icon = Icons.check_circle_rounded;
      label = _localized(context, vi: 'Hành trình', en: 'Journey');
      break;
    case 'journey_checkin_failed':
      color = const Color(0xFFDC2626);
      softColor = const Color(0xFFFEE2E2);
      icon = Icons.location_off_rounded;
      label = _localized(context, vi: 'Hành trình', en: 'Journey');
      break;
    case 'journey_badge':
      color = const Color(0xFFF59E0B);
      softColor = const Color(0xFFFEF3C7);
      icon = Icons.emoji_events_rounded;
      label = _localized(context, vi: 'Huy hiệu', en: 'Badge');
      break;
    default:
      color = const Color(0xFFF97316);
      softColor = const Color(0xFFFFEDD5);
      icon = Icons.favorite_rounded;
      label = _localized(context, vi: 'Tương tác', en: 'Interaction');
      break;
  }

  return _NotificationTone(
    color: color,
    softColor: softColor,
    icon: icon,
    label: label,
  );
}

String _titleFor(BuildContext context, UserNotification item) {
  final t = AppLocalizations.of(context)!;
  final fallbackName = _localized(context, vi: 'Ai đó', en: 'Someone');
  final actorName = item.actorName.trim().isEmpty
      ? fallbackName
      : item.actorName.trim();

  switch (item.type) {
    case 'comment':
      return t.notificationCommentTitle(actorName);
    case 'post_pending_review':
      return _localized(
        context,
        vi: 'Bài viết đang chờ duyệt',
        en: 'Post awaiting review',
      );
    case 'post_moderation_update':
      final source = '${item.actorName} ${item.snippet}'.toLowerCase();
      if (source.contains('duyệt') || source.contains('approved')) {
        return _localized(
          context,
          vi: 'Bài viết đã được duyệt',
          en: 'Post approved',
        );
      }
      if (source.contains('bị ẩn') || source.contains('hidden')) {
        return _localized(
          context,
          vi: 'Bài viết đã bị ẩn',
          en: 'Post hidden',
        );
      }
      return _localized(
        context,
        vi: 'Trạng thái bài viết đã thay đổi',
        en: 'Post status updated',
      );
    case 'journey_checkin':
      return _localized(
        context,
        vi: 'Check-in thành công',
        en: 'Check-in successful',
      );
    case 'journey_checkin_failed':
      return _localized(
        context,
        vi: 'Check-in thất bại',
        en: 'Check-in failed',
      );
    case 'journey_badge':
      return _localized(
        context,
        vi: 'Mở khóa huy hiệu mới',
        en: 'New badge unlocked',
      );
    case 'like':
      return t.notificationLikeTitle(actorName);
    default:
      return item.actorName.trim().isEmpty
          ? _localized(context, vi: 'Thông báo mới', en: 'New notification')
          : item.actorName;
  }
}

String _snippetFor(BuildContext context, UserNotification item) {
  switch (item.type) {
    case 'post_pending_review':
      return _localized(
        context,
        vi: 'Bài viết đã được gửi và đang chờ duyệt.',
        en: 'Your post was submitted and is awaiting review.',
      );
    case 'post_moderation_update':
      return _localized(
        context,
        vi: 'Trạng thái kiểm duyệt bài viết của bạn vừa được cập nhật.',
        en: 'Your post moderation status has been updated.',
      );
    case 'journey_checkin':
      return _localized(
        context,
        vi: 'Địa điểm đã được ghi nhận vào hành trình của bạn.',
        en: 'The place was added to your journey.',
      );
    case 'journey_checkin_failed':
      return _localized(
        context,
        vi: 'Bạn đang ở quá xa quán để check-in.',
        en: 'You are too far from the place to check in.',
      );
    default:
      return item.snippet.trim();
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

class _SettingsHintCard extends StatelessWidget {
  const _SettingsHintCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F27) : const Color(0xFFFFF4E6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFED7AA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFFF97316),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localized(
                    context,
                    vi: 'Không bỏ lỡ thông báo quan trọng',
                    en: 'Never miss an important notification',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _localized(
                    context,
                    vi: 'Bật thông báo để nhận cập nhật mới nhất từ Foods.',
                    en: 'Enable notifications to receive the latest updates from Foods.',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _localized(context, vi: 'Cài đặt', en: 'Settings'),
            ),
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
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFFFFBF5);
    final block = isDark ? const Color(0xFF1F2630) : const Color(0xFFF1F5F9);

    return Container(
      color: bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            height: 112,
            decoration: BoxDecoration(
              color: block,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              4,
              (index) => Container(
                width: 78,
                height: 38,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: block,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < 4; i++) ...[
            Container(
              height: 108,
              decoration: BoxDecoration(
                color: block,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.icon,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 34,
                color: const Color(0xFFF97316),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _localized(
                context,
                vi: 'Chưa có thông báo',
                en: 'No notifications yet',
              ),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: subColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _localized(
  BuildContext context, {
  required String vi,
  required String en,
}) {
  return Localizations.localeOf(context).languageCode == 'vi' ? vi : en;
}
