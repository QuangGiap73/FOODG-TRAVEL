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
        final sections = _buildSections(filteredItems);

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
                  child: const Text('\u0110\u00e1nh d\u1ea5u \u0111\u00e3 \u0111\u1ecdc'),
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
                            : '\u0110ang kh\u00f4ng c\u00f3 th\u00f4ng b\u00e1o ph\u00f9 h\u1ee3p b\u1ed9 l\u1ecdc n\u00e0y.',
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

List<_NotificationSection> _buildSections(List<UserNotification> items) {
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
    sections.add(const _NotificationSection(
      title: 'H\u00f4m nay',
      items: [],
    ).copyWith(items: todayItems));
  }
  if (yesterdayItems.isNotEmpty) {
    sections.add(const _NotificationSection(
      title: 'H\u00f4m qua',
      items: [],
    ).copyWith(items: yesterdayItems));
  }
  if (olderItems.isNotEmpty) {
    sections.add(const _NotificationSection(
      title: 'Tr\u01b0\u1edbc \u0111\u00f3',
      items: [],
    ).copyWith(items: olderItems));
  }
  return sections;
}

extension on _NotificationSection {
  _NotificationSection copyWith({
    String? title,
    List<UserNotification>? items,
  }) {
    return _NotificationSection(
      title: title ?? this.title,
      items: items ?? this.items,
    );
  }
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
                      ? 'Kh\u00f4ng c\u00f3 th\u00f4ng b\u00e1o m\u1edbi'
                      : 'B\u1ea1n c\u00f3 $unreadCount th\u00f4ng b\u00e1o m\u1edbi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalCount == 0
                      ? 'Th\u00f4ng b\u00e1o s\u1ebd hi\u1ec7n t\u1ea1i \u0111\u00e2y khi c\u00f3 t\u01b0\u01a1ng t\u00e1c m\u1edbi.'
                      : 'C\u1eadp nh\u1eadt ho\u1ea1t \u0111\u1ed9ng m\u1edbi nh\u1ea5t t\u1eeb c\u1ed9ng \u0111\u1ed3ng v\u00e0 h\u00e0nh tr\u00ecnh c\u1ee7a b\u1ea1n.',
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
      (_NotificationFilter.all, 'T\u1ea5t c\u1ea3'),
      (_NotificationFilter.interaction, 'T\u01b0\u01a1ng t\u00e1c'),
      (_NotificationFilter.journey, 'H\u00e0nh tr\u00ecnh'),
      (_NotificationFilter.system, 'H\u1ec7 th\u1ed1ng'),
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
    final tone = _toneFor(item);
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
                      _titleFor(item),
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    if (item.snippet.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        item.snippet,
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

_NotificationTone _toneFor(UserNotification item) {
  switch (item.type) {
    case 'comment':
      return const _NotificationTone(
        color: Color(0xFF2563EB),
        softColor: Color(0xFFDBEAFE),
        icon: Icons.chat_bubble_rounded,
        label: 'T\u01b0\u01a1ng t\u00e1c',
      );
    case 'journey_checkin':
      return const _NotificationTone(
        color: Color(0xFF16A34A),
        softColor: Color(0xFFDCFCE7),
        icon: Icons.check_circle_rounded,
        label: 'H\u00e0nh tr\u00ecnh',
      );
    case 'journey_checkin_failed':
      return const _NotificationTone(
        color: Color(0xFFDC2626),
        softColor: Color(0xFFFEE2E2),
        icon: Icons.location_off_rounded,
        label: 'H\u00e0nh tr\u00ecnh',
      );
    case 'journey_badge':
      return const _NotificationTone(
        color: Color(0xFFF59E0B),
        softColor: Color(0xFFFEF3C7),
        icon: Icons.emoji_events_rounded,
        label: 'Huy hi\u1ec7u',
      );
    default:
      return const _NotificationTone(
        color: Color(0xFFF97316),
        softColor: Color(0xFFFFEDD5),
        icon: Icons.favorite_rounded,
        label: 'T\u01b0\u01a1ng t\u00e1c',
      );
  }
}

String _titleFor(UserNotification item) {
  switch (item.type) {
    case 'comment':
      final name = item.actorName.trim().isEmpty ? 'Ai \u0111\u00f3' : item.actorName;
      return '$name \u0111\u00e3 b\u00ecnh lu\u1eadn';
    case 'journey_checkin':
      return 'Check-in th\u00e0nh c\u00f4ng';
    case 'journey_checkin_failed':
      return item.actorName.trim().isEmpty
          ? 'Check-in thất bại'
          : item.actorName;
    case 'journey_badge':
      return item.actorName.trim().isEmpty
          ? 'Mở khóa huy hiệu mới'
          : item.actorName;
    case 'like':
      final name = item.actorName.trim().isEmpty ? 'Ai \u0111\u00f3' : item.actorName;
      return '$name \u0111\u00e3 th\u00edch b\u00e0i vi\u1ebft c\u1ee7a b\u1ea1n';
    default:
      return item.actorName.trim().isEmpty
          ? 'Th\u00f4ng b\u00e1o m\u1edbi'
          : item.actorName;
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kh\u00f4ng b\u1ecf l\u1ee1 th\u00f4ng b\u00e1o quan tr\u1ecdng',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'B\u1eadt th\u00f4ng b\u00e1o \u0111\u1ec3 nh\u1eadn c\u1eadp nh\u1eadt m\u1edbi nh\u1ea5t t\u1eeb Foods.',
                  style: TextStyle(
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
            child: const Text('C\u00e0i \u0111\u1eb7t'),
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
              'Ch\u01b0a c\u00f3 th\u00f4ng b\u00e1o',
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
