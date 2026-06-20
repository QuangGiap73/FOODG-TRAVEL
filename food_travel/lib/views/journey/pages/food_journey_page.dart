import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/journey/journey_stats.dart';
import '../../../views/journey/pages/mission_detail_page.dart';
import '../../../views/journey/widgets/daily_mission_section.dart';
import '../../../views/journey/widgets/vietnam_journer_map_card.dart';

class FoodJourneyPage extends StatelessWidget {
  const FoodJourneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF3),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 72,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF111111),
          ),
        ),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hành trình ẩm thực ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Khám phá Việt Nam qua từng món ăn',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Offstage(
                offstage: true,
                child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: SizedBox(
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                          ),
                          color: const Color(0xFF111111),
                        ),
                      ),
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hành trình ẩm thực ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Khám phá Việt Nam qua từng món ăn',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              ),
              _JourneyHeroBanner(userId: user?.uid),
              const SizedBox(height: 20),
              VietnamJourneyMapCard(userId: user?.uid),
              const SizedBox(height: 20),
              DailyMissionSection(
                userId: user?.uid,
                onMissionTap: (mission) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MissionDetailPage(mission: mission),
                    ),
                  );
                },
              ),
              const SizedBox(height: 300),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyHeroBanner extends StatelessWidget {
  const _JourneyHeroBanner({required this.userId});

  final String? userId;

  Stream<JourneyStats> _statsStream() {
    if (userId == null || userId!.trim().isEmpty) {
      return Stream.value(const JourneyStats());
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('journey')
        .doc('summary')
        .snapshots()
        .map((snap) => JourneyStats.fromMap(snap.data()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 2172 / 724,
              child: Image.asset(
                'assets/journey/jourfood_1A.png',
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFFFF7E3).withValues(alpha: 0.10),
                        const Color(0xFFFFF7E3).withValues(alpha: 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: StreamBuilder<JourneyStats>(
                stream: _statsStream(),
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? const JourneyStats();
                  return _JourneyStatsLayout(stats: stats);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyStatsLayout extends StatelessWidget {
  const _JourneyStatsLayout({required this.stats});

  final JourneyStats stats;

  @override
  Widget build(BuildContext context) {
    final level = stats.level <= 0 ? 1 : stats.level;
    final totalPoints = stats.totalPoints < 0 ? 0 : stats.totalPoints;
    final nextLevelTarget = level * 100;
    final pointsToNextLevel = (nextLevelTarget - totalPoints).clamp(0, 999999);
    final progress = ((totalPoints % 100) / 100).clamp(0.0, 1.0);

    return SizedBox(
      height: 130,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 130,
            top: 20,
            child: _JourneyBadgeChip(
              icon: Icons.emoji_events_rounded,
              label: 'Explorer',
            ),
          ),
          Positioned(
            left: 140,
            top: 50,
            child: _JourneyLevelBlock(level: level),
          ),
          Positioned(
            right: 35,
            top: 40,
            child: _JourneyPointsBlock(points: totalPoints),
          ),
          Positioned(
            right: 8,
            top: 60,
            child: _JourneyStreakBlock(days: stats.currentStreak),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _JourneyProgressBlock(
              pointsToNextLevel: pointsToNextLevel,
              totalPoints: totalPoints,
              nextLevelTarget: nextLevelTarget,
              progress: progress,
              level: level,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyBadgeChip extends StatelessWidget {
  const _JourneyBadgeChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFF2D7A5).withValues(alpha: 0.85),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFB75C00)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8A4300),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyLevelBlock extends StatelessWidget {
  const _JourneyLevelBlock({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Lv.$level',
      style: const TextStyle(
        color: Color(0xFF7A3E00),
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 1,
        shadows: [
          Shadow(color: Colors.white, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}

class _JourneyPointsBlock extends StatelessWidget {
  const _JourneyPointsBlock({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          size: 18,
          color: Color(0xFF9B4D00),
        ),
        const SizedBox(width: 4),
        RichText(
          textAlign: TextAlign.right,
          text: TextSpan(
            children: [
              TextSpan(
                text: '$points ',
                style: const TextStyle(
                  color: Color(0xFF7A3E00),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const TextSpan(
                text: 'Điểm',
                style: TextStyle(
                  color: Color(0xFF8A4300),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JourneyStreakBlock extends StatelessWidget {
  const _JourneyStreakBlock({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          size: 18,
          color: Color(0xFF9B4D00),
        ),
        const SizedBox(width: 4),
        RichText(
          textAlign: TextAlign.right,
          text: TextSpan(
            children: [
              TextSpan(
                text: '$days ',
                style: const TextStyle(
                  color: Color(0xFF7A3E00),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const TextSpan(
                text: 'ngày liên tiếp',
                style: TextStyle(
                  color: Color(0xFF8A4300),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JourneyProgressBlock extends StatelessWidget {
  const _JourneyProgressBlock({
    required this.pointsToNextLevel,
    required this.totalPoints,
    required this.nextLevelTarget,
    required this.progress,
    required this.level,
  });

  final int pointsToNextLevel;
  final int totalPoints;
  final int nextLevelTarget;
  final double progress;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(140, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cần $pointsToNextLevel điểm để lên Lv.${level + 1}.',
            style: const TextStyle(
              color: Color(0xFF6C3B00),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.white,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.62,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(
                    0xFFE7C98F,
                  ).withValues(alpha: 0.5),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFEB8A00),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          FractionallySizedBox(
            widthFactor: 0.62,
            alignment: Alignment.centerLeft,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$totalPoints / $nextLevelTarget',
                style: const TextStyle(
                  color: Color(0xFF6C3B00),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
