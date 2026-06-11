import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/journey/journey_province_progress.dart';
import '../../../models/journey/journey_schema.dart';

class VietnamJourneyMapCard extends StatefulWidget {
  const VietnamJourneyMapCard({super.key, required this.userId});

  final String? userId;

  @override
  State<VietnamJourneyMapCard> createState() => _VietnamJourneyMapCardState();
}

class _VietnamJourneyMapCardState extends State<VietnamJourneyMapCard> {
  late final Future<List<_GeoProvinceFeature>> _geoJsonFuture = _loadGeoJson();

  @override
  Widget build(BuildContext context) {
    final hasUser = widget.userId != null && widget.userId!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF4E5D6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child:
          hasUser
              ? FutureBuilder<List<_GeoProvinceFeature>>(
                future: _geoJsonFuture,
                builder: (context, geoSnapshot) {
                  if (geoSnapshot.connectionState != ConnectionState.done) {
                    return const _MapLoadingState();
                  }

                  if (geoSnapshot.hasError || !geoSnapshot.hasData) {
                    return _MapErrorState(error: geoSnapshot.error);
                  }

                  final features = geoSnapshot.data!;
                  return StreamBuilder<_JourneyProvinceSnapshot>(
                    stream: _watchProvinceSnapshot(widget.userId!, features),
                    builder: (context, snapshot) {
                      final data =
                          snapshot.data ??
                          _JourneyProvinceSnapshot.empty(features);
                      return _JourneyMapContent(
                        data: data,
                        onShowAll: () => _showProvinceListSheet(context, data),
                        onProvinceTap:
                            (item) => _showProvinceSheet(context, item),
                      );
                    },
                  );
                },
              )
              : const _JourneySignedOutState(),
    );
  }

  Future<List<_GeoProvinceFeature>> _loadGeoJson() async {
    final raw = await rootBundle.loadString(
      'assets/maps/geojson/vietnam_provinces_34_compact.json',
    );
    return compute(_parseCompactProvincePayload, raw);
  }

  Stream<_JourneyProvinceSnapshot> _watchProvinceSnapshot(
    String uid,
    List<_GeoProvinceFeature> features,
  ) {
    final root = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(JourneyCollections.journeyRoot)
        .doc(JourneyDocumentIds.summary);

    return root.collection(JourneyCollections.provinces).snapshots().map((
      snapshot,
    ) {
      final progressByKey = <String, JourneyProvinceProgress>{};

      for (final doc in snapshot.docs) {
        final progress = JourneyProvinceProgress.fromDoc(doc);
        for (final key in _canonicalKeys(
          progress.provinceCode,
          progress.provinceName,
        )) {
          progressByKey[key] = progress;
        }
      }

      final items =
          features
              .map(
                (feature) => _ProvinceMapItem(
                  feature: feature,
                  progress:
                      progressByKey[feature.key] ??
                      progressByKey[_normalizeProvinceKey(feature.displayName)],
                ),
              )
              .toList();

      final discovered =
          items.where((item) => item.isDiscovered).toList()..sort(
            (a, b) =>
                b.progress.checkinCount.compareTo(a.progress.checkinCount),
          );

      return _JourneyProvinceSnapshot(
        items: items,
        discoveredItems: discovered,
        discoveredCount: discovered.length,
      );
    });
  }

  void _showProvinceSheet(BuildContext context, _ProvinceMapItem item) {
    final progress = item.progress;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFCF7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5D7C8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  item.displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.isDiscovered
                      ? 'Ban da mo khoa tinh thanh nay trong hanh trinh am thuc.'
                      : 'Chua co check-in nao tai tinh thanh nay.',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ProvinceMetricCard(
                        label: 'Check-in',
                        value: '${progress.checkinCount}',
                        color: const Color(0xFFFF8A00),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProvinceMetricCard(
                        label: 'Quan khac nhau',
                        value: '${progress.uniquePlacesCount}',
                        color: const Color(0xFFEF6C00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ProvinceMetricCard(
                        label: 'Quan/Huyen',
                        value: '${progress.districtsCount}',
                        color: const Color(0xFFFFB300),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProvinceMetricCard(
                        label: 'Diem nhan duoc',
                        value: '${progress.totalPoints}',
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProvinceListSheet(
    BuildContext context,
    _JourneyProvinceSnapshot data,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Danh sach tinh thanh',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Da kham pha ${data.discoveredCount}/${data.items.length} tinh thanh.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: data.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = data.items[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          Navigator.of(context).pop();
                          _showProvinceSheet(context, item);
                        },
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color:
                                item.isDiscovered
                                    ? const Color(0xFFFF8A00)
                                    : const Color(0xFFD7DDE5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(
                          item.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        trailing: Text(
                          item.isDiscovered
                              ? '${item.progress.checkinCount} check-in'
                              : 'Chua kham pha',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                item.isDiscovered
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF9CA3AF),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JourneySignedOutState extends StatelessWidget {
  const _JourneySignedOutState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(),
        SizedBox(height: 12),
        _MapCardMessage(
          icon: Icons.person_outline_rounded,
          title: 'Chua co nguoi dung',
          message:
              'Dang nhap de theo doi hanh trinh am thuc cua ban tren ban do.',
        ),
      ],
    );
  }
}

class _JourneyMapContent extends StatelessWidget {
  const _JourneyMapContent({
    required this.data,
    required this.onShowAll,
    required this.onProvinceTap,
  });

  final _JourneyProvinceSnapshot data;
  final VoidCallback onShowAll;
  final ValueChanged<_ProvinceMapItem> onProvinceTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(onShowAll: onShowAll),
        const SizedBox(height: 12),
        _JourneyMapPanel(data: data, onProvinceTap: onProvinceTap),
        const SizedBox(height: 14),
        const Row(
          children: [
            _MapLegendItem(color: Color(0xFFFF8A00), label: 'Da kham pha'),
            SizedBox(width: 20),
            _MapLegendItem(color: Color(0xFFD7DDE5), label: 'Chua kham pha'),
          ],
        ),
        if (data.discoveredItems.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                data.discoveredItems.take(8).map((item) {
                  return ActionChip(
                    backgroundColor: const Color(0xFFFFF3E4),
                    side: const BorderSide(color: Color(0xFFFFD3A1)),
                    labelStyle: const TextStyle(
                      color: Color(0xFF9A4D00),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: () => onProvinceTap(item),
                    label: Text(
                      '${item.displayName} · ${item.progress.checkinCount}',
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onShowAll});

  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Ban do kham pha Viet Nam',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        if (onShowAll != null)
          TextButton(
            onPressed: onShowAll,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Xem tat ca'),
          ),
      ],
    );
  }
}

class _JourneyMapPanel extends StatelessWidget {
  const _JourneyMapPanel({required this.data, required this.onProvinceTap});

  final _JourneyProvinceSnapshot data;
  final ValueChanged<_ProvinceMapItem> onProvinceTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final geometry = _GeoMapLayout.build(
            items: data.items,
            size: Size(constraints.maxWidth, 340),
          );
// bấm vào 1 tỉnh 
          return DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF7),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFF6E7D8)),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final tapped = geometry.hitTest(details.localPosition);
                if (tapped != null) {
                  onProvinceTap(tapped);
                }
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _VietnamGeoJsonPainter(geometry: geometry),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 18,
                    child: _DiscoverySummaryCard(
                      discoveredCount: data.discoveredCount,
                      totalCount: data.items.length,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VietnamGeoJsonPainter extends CustomPainter {
  const _VietnamGeoJsonPainter({required this.geometry});

  final _GeoMapLayout geometry;
// vẽ bản đồ 
  @override
  void paint(Canvas canvas, Size size) {
    final undiscoveredPaint =
        Paint()
          ..color = const Color(0xFFE6E1D9)
          ..style = PaintingStyle.fill;
    final discoveredPaint =
        Paint()
          ..color = const Color(0xFFFF8A00)
          ..style = PaintingStyle.fill;
    final strokePaint =
        Paint()
          ..color = const Color(0xFFB8AEA3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9;
    final discoveredStrokePaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1;

    for (final shape in geometry.shapes) {
      for (final path in shape.paths) {
        canvas.drawPath(
          path,
          shape.item.isDiscovered ? discoveredPaint : undiscoveredPaint,
        );
        canvas.drawPath(
          path,
          shape.item.isDiscovered ? discoveredStrokePaint : strokePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VietnamGeoJsonPainter oldDelegate) {
    return oldDelegate.geometry != geometry;
  }
}

class _DiscoverySummaryCard extends StatelessWidget {
  const _DiscoverySummaryCard({
    required this.discoveredCount,
    required this.totalCount,
  });

  final int discoveredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Da kham pha',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$discoveredCount',
                  style: const TextStyle(
                    fontSize: 32,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF8A00),
                  ),
                ),
                TextSpan(
                  text: '/$totalCount',
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'tinh thanh',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvinceMetricCard extends StatelessWidget {
  const _ProvinceMetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2E7DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCardMessage extends StatelessWidget {
  const _MapCardMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF4E5D6)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFF8A00), size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLegendItem extends StatelessWidget {
  const _MapLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MapLoadingState extends StatelessWidget {
  const _MapLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 340,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _MapErrorState extends StatelessWidget {
  const _MapErrorState({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final details = error?.toString().trim();
    return _MapCardMessage(
      icon: Icons.map_outlined,
      title: 'Khong tai duoc ban do',
      message:
          details == null || details.isEmpty
              ? 'Asset GeoJSON hien tai khong doc duoc. Kiem tra lai file ban do.'
              : 'Khong doc duoc GeoJSON: $details',
    );
  }
}

class _JourneyProvinceSnapshot {
  const _JourneyProvinceSnapshot({
    required this.items,
    required this.discoveredItems,
    required this.discoveredCount,
  });

  factory _JourneyProvinceSnapshot.empty(List<_GeoProvinceFeature> features) {
    final items =
        features.map((feature) => _ProvinceMapItem(feature: feature)).toList();
    return _JourneyProvinceSnapshot(
      items: items,
      discoveredItems: const [],
      discoveredCount: 0,
    );
  }

  final List<_ProvinceMapItem> items;
  final List<_ProvinceMapItem> discoveredItems;
  final int discoveredCount;
}

class _ProvinceMapItem {
  const _ProvinceMapItem({
    required this.feature,
    JourneyProvinceProgress? progress,
  }) : progress =
           progress ??
           const JourneyProvinceProgress(provinceCode: '', provinceName: '');

  final _GeoProvinceFeature feature;
  final JourneyProvinceProgress progress;

  String get displayName =>
      progress.provinceName.trim().isNotEmpty
          ? progress.provinceName.trim()
          : feature.displayName;

  bool get isDiscovered => progress.isDiscovered || progress.checkinCount > 0;
}

class _GeoProvinceFeature {
  const _GeoProvinceFeature({
    required this.key,
    required this.displayName,
    required this.polygons,
    required this.bounds,
  });

  factory _GeoProvinceFeature.fromCompactJson(Map<String, dynamic> json) {
    final name = json['name']?.toString().trim() ?? '';
    final polygons =
        (json['polygons'] as List<dynamic>? ?? const [])
            .whereType<List<dynamic>>()
            .map(_parsePolygonRings)
            .where((rings) => rings.isNotEmpty)
            .toList(growable: false);

    final bounds = _computeBounds(polygons);
    return _GeoProvinceFeature(
      key: _normalizeProvinceKey(name),
      displayName: name,
      polygons: polygons,
      bounds: bounds,
    );
  }

  final String key;
  final String displayName;
  final List<List<List<Offset>>> polygons;
  final Rect bounds;

  static List<List<Offset>> _parsePolygonRings(List<dynamic> polygon) {
    final rings = <List<Offset>>[];
    for (final ring in polygon.whereType<List<dynamic>>()) {
      final points = <Offset>[];
      for (final pair in ring.whereType<List<dynamic>>()) {
        if (pair.length < 2) continue;
        final dx = (pair[0] as num?)?.toDouble();
        final dy = (pair[1] as num?)?.toDouble();
        if (dx == null || dy == null) continue;
        points.add(Offset(dx, dy));
      }
      if (points.length >= 3) {
        rings.add(points);
      }
    }
    return rings;
  }

  static Rect _computeBounds(List<List<List<Offset>>> polygons) {
    double? minX;
    double? minY;
    double? maxX;
    double? maxY;

    for (final polygon in polygons) {
      for (final ring in polygon) {
        for (final point in ring) {
          minX = minX == null ? point.dx : (point.dx < minX ? point.dx : minX);
          minY = minY == null ? point.dy : (point.dy < minY ? point.dy : minY);
          maxX = maxX == null ? point.dx : (point.dx > maxX ? point.dx : maxX);
          maxY = maxY == null ? point.dy : (point.dy > maxY ? point.dy : maxY);
        }
      }
    }

    if (minX == null || minY == null || maxX == null || maxY == null) {
      return Rect.zero;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

List<_GeoProvinceFeature> _parseCompactProvincePayload(String raw) {
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return (decoded['provinces'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(_GeoProvinceFeature.fromCompactJson)
      .where((feature) => feature.polygons.isNotEmpty)
      .toList(growable: false);
}

class _ProjectedProvinceShape {
  const _ProjectedProvinceShape({required this.item, required this.paths});

  final _ProvinceMapItem item;
  final List<ui.Path> paths;
}

class _GeoMapLayout {
  const _GeoMapLayout({required this.shapes});

  final List<_ProjectedProvinceShape> shapes;

  factory _GeoMapLayout.build({
    required List<_ProvinceMapItem> items,
    required Size size,
  }) {
    final featureBounds =
        items
            .map((item) => item.feature.bounds)
            .where((rect) => rect != Rect.zero)
            .toList();

    final minX = featureBounds
        .map((e) => e.left)
        .reduce((a, b) => a < b ? a : b);
    final minY = featureBounds
        .map((e) => e.top)
        .reduce((a, b) => a < b ? a : b);
    final maxX = featureBounds
        .map((e) => e.right)
        .reduce((a, b) => a > b ? a : b);
    final maxY = featureBounds
        .map((e) => e.bottom)
        .reduce((a, b) => a > b ? a : b);
// vẽ bản đồ 
    final geoBounds = Rect.fromLTRB(minX, minY, maxX, maxY);
    const leftPanelWidth = 108.0;
    const horizontalPadding = 18.0;
    const verticalPadding = 14.0;
    final availableWidth = size.width - leftPanelWidth - horizontalPadding * 2;
    final availableHeight = size.height - verticalPadding * 2;
    final scale =
        availableWidth / geoBounds.width < availableHeight / geoBounds.height
            ? availableWidth / geoBounds.width
            : availableHeight / geoBounds.height;
    final drawnWidth = geoBounds.width * scale;
    final drawnHeight = geoBounds.height * scale;
    final offsetX =
        leftPanelWidth + horizontalPadding + (availableWidth - drawnWidth) / 2;
    final offsetY = verticalPadding + (availableHeight - drawnHeight) / 2;

    final shapes =
        items.map((item) {
          final paths = <ui.Path>[];
          for (final polygon in item.feature.polygons) {
            final path = ui.Path();
            for (var ringIndex = 0; ringIndex < polygon.length; ringIndex++) {
              final ring = polygon[ringIndex];
              if (ring.isEmpty) continue;
              final transformed =
                  ring
                      .map(
                        (point) => Offset(
                          offsetX + (point.dx - geoBounds.left) * scale,
                          offsetY + (geoBounds.bottom - point.dy) * scale,
                        ),
                      )
                      .toList();
              path.addPolygon(transformed, true);
              if (ringIndex > 0) {
                path.fillType = ui.PathFillType.evenOdd;
              }
            }
            paths.add(path);
          }
          return _ProjectedProvinceShape(item: item, paths: paths);
        }).toList();

    return _GeoMapLayout(shapes: shapes);
  }

  _ProvinceMapItem? hitTest(Offset position) {
    for (final shape in shapes.reversed) {
      for (final path in shape.paths) {
        if (path.contains(position)) {
          return shape.item;
        }
      }
    }
    return null;
  }
}

Set<String> _canonicalKeys(String code, String name) {
  final keys = <String>{};
  for (final value in [code, name]) {
    final normalized = _normalizeProvinceKey(value);
    if (normalized.isNotEmpty) {
      keys.add(normalized);
      final alias = _provinceAliases[normalized];
      if (alias != null) {
        keys.add(alias);
      }
    }
  }
  return keys;
}

String _normalizeProvinceKey(String input) {
  final source = input.trim().toLowerCase();
  if (source.isEmpty) return '';

  const accents = {
    'à': 'a',
    'á': 'a',
    'ạ': 'a',
    'ả': 'a',
    'ã': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ặ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ậ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'đ': 'd',
    'è': 'e',
    'é': 'e',
    'ẹ': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ệ': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ì': 'i',
    'í': 'i',
    'ị': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ò': 'o',
    'ó': 'o',
    'ọ': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ộ': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ợ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ụ': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ự': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỵ': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
  };

  final buffer = StringBuffer();
  for (final rune in source.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(accents[char] ?? char);
  }

  return buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

const Map<String, String> _provinceAliases = {
  'tp_ho_chi_minh': 'ho_chi_minh_city',
  'ho_chi_minh_city': 'ho_chi_minh_city',
  'tp_hcm': 'ho_chi_minh_city',
  'tphcm': 'ho_chi_minh_city',
  'sai_gon': 'ho_chi_minh_city',
  'thua_thien_hue': 'hue',
};
