import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/journey/journey_province_progress.dart';
import '../../../models/journey/journey_schema.dart';
import '../pages/journey_province_detail_page.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171D25) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF303844) : const Color(0xFFF4E5D6),
        ),
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
                            (item) => _openProvinceDetail(context, item),
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

    final canonicalCollection = root.collection(
      '${JourneyCollections.provinces}_v2',
    );
    final legacyCollection = root.collection(JourneyCollections.provinces);

    return canonicalCollection.snapshots().asyncMap((snapshot) async {
      final effectiveSnapshot =
          snapshot.docs.isNotEmpty ? snapshot : await legacyCollection.get();
      final progressByKey = <String, JourneyProvinceProgress>{};

      for (final doc in effectiveSnapshot.docs) {
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

  void _openProvinceDetail(BuildContext context, _ProvinceMapItem item) {
    final userId = widget.userId;
    if (userId == null || userId.trim().isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => JourneyProvinceDetailPage(
              userId: userId,
              provinceCode:
                  item.progress.provinceCode.trim().isNotEmpty
                      ? item.progress.provinceCode
                      : item.feature.key,
              provinceName:
                  item.progress.provinceName.trim().isNotEmpty
                      ? item.progress.provinceName
                      : item.displayName,
            ),
      ),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171D25) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                Text(
                  AppLocalizations.of(context)!.journeyProvinceListTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.journeyDiscoveredProvinceCount(
                    data.discoveredCount,
                    data.items.length,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
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
                          _openProvinceDetail(context, item);
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        trailing: Text(
                          item.isDiscovered
                              ? AppLocalizations.of(
                                context,
                              )!.journeyCheckinCount(item.progress.checkinCount)
                              : AppLocalizations.of(
                                context,
                              )!.journeyNotDiscovered,
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
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(),
        const SizedBox(height: 12),
        _MapCardMessage(
          icon: Icons.person_outline_rounded,
          title: t.journeySignedOutTitle,
          message: t.journeySignedOutMessage,
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
        Row(
          children: [
            _MapLegendItem(
              color: const Color(0xFFFF8A00),
              label: AppLocalizations.of(context)!.journeyDiscovered,
            ),
            const SizedBox(width: 20),
            _MapLegendItem(
              color: const Color(0xFFD7DDE5),
              label: AppLocalizations.of(context)!.journeyNotDiscovered,
            ),
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
                      '${item.displayName} • ${item.progress.checkinCount}',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final systemScale = MediaQuery.textScalerOf(context).scale(1);
    final headerTextScaler = TextScaler.linear(
      systemScale.clamp(1, 1.15).toDouble(),
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.journeyMapTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textScaler: headerTextScaler,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        ),
        if (onShowAll != null)
          TextButton(
            onPressed: onShowAll,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.commonViewAll,
              textScaler: headerTextScaler,
            ),
          ),
      ],
    );
  }
}

class _JourneyMapPanel extends StatefulWidget {
  const _JourneyMapPanel({required this.data, required this.onProvinceTap});

  static const double _mapPanelHeight = 300;

  final _JourneyProvinceSnapshot data;
  final ValueChanged<_ProvinceMapItem> onProvinceTap;

  @override
  State<_JourneyMapPanel> createState() => _JourneyMapPanelState();
}

class _JourneyMapPanelState extends State<_JourneyMapPanel> {
  static const double _minScale = 1;
  static const double _maxScale = 4.5;

  // TransformationController giữ ma trận phóng to và vị trí kéo hiện tại.
  // Nhờ có controller, nút đặt lại có thể đưa bản đồ về trạng thái ban đầu.
  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;
  bool _isInteractionActive = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleInteractionUpdate(ScaleUpdateDetails _) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final isZoomed = scale > _minScale + 0.01;
    // Chỉ rebuild khi đi qua ngưỡng zoom, không rebuild theo từng chuyển động
    // của ngón tay; nhờ đó CustomPainter vẫn hoạt động mượt.
    if (isZoomed == _isZoomed) return;
    setState(() => _isZoomed = isZoomed);
  }

  void _resetMap() {
    _transformationController.value = Matrix4.identity();
    setState(() => _isZoomed = false);
  }

  void _activateMap() {
    if (_isInteractionActive) return;
    setState(() => _isInteractionActive = true);
  }

  void _zoomBy(Size viewportSize, double amount) {
    _activateMap();
    final currentScale =
        _transformationController.value.getMaxScaleOnAxis();
    final targetScale =
        (currentScale + amount).clamp(_minScale, _maxScale).toDouble();
    if ((targetScale - currentScale).abs() < 0.001) return;

    if (targetScale <= _minScale + 0.001) {
      _resetMap();
      return;
    }

    // Giữ nguyên điểm đang nằm giữa khung nhìn khi bấm +/-. Nếu chỉ scale
    // quanh góc trên trái, bản đồ sẽ bị nhảy khỏi khu vực người dùng đang xem.
    final viewportCenter = viewportSize.center(Offset.zero);
    final sceneCenter = _transformationController.toScene(viewportCenter);
    final matrix = Matrix4.identity();
    matrix.storage[0] = targetScale;
    matrix.storage[5] = targetScale;
    matrix.storage[12] = viewportCenter.dx - sceneCenter.dx * targetScale;
    matrix.storage[13] = viewportCenter.dy - sceneCenter.dy * targetScale;
    _transformationController.value = matrix;

    if (!_isZoomed) setState(() => _isZoomed = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: _JourneyMapPanel._mapPanelHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final geometry = _GeoMapLayout.build(
            items: widget.data.items,
            size: Size(
              constraints.maxWidth,
              _JourneyMapPanel._mapPanelHeight,
            ),
          );

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222A34) : const Color(0xFFFFFBF7),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color:
                    _isInteractionActive
                        ? const Color(0xFFFF7A00)
                        : isDark
                        ? const Color(0xFF3B4654)
                        : const Color(0xFFF6E7D8),
                width: _isInteractionActive ? 2.2 : 1,
              ),
              boxShadow:
                  _isInteractionActive
                      ? [
                        BoxShadow(
                          color: const Color(
                            0xFFFF7A00,
                          ).withValues(alpha: 0.24),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                      : const [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: _minScale,
                      maxScale: _maxScale,
                      // Luôn nhận pan để bộ nhận diện của bản đồ giữ được cử
                      // chỉ ngay từ ngón tay đầu tiên; nhờ đó thao tác chụm hai
                      // ngón không bị danh sách bên ngoài giành mất.
                      panEnabled: true,
                      scaleEnabled: true,
                      boundaryMargin: const EdgeInsets.all(100),
                      clipBehavior: Clip.hardEdge,
                      onInteractionUpdate: _handleInteractionUpdate,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: _JourneyMapPanel._mapPanelHeight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          // GestureDetector nằm trong vùng được transform nên
                          // localPosition đã được Flutter đổi về tọa độ bản đồ.
                          onTapUp: (details) {
                            final tapped = geometry.hitTest(
                              details.localPosition,
                            );
                            if (tapped != null) {
                              widget.onProvinceTap(tapped);
                            }
                          },
                          child: RepaintBoundary(
                            child: CustomPaint(
                              size: Size(
                                constraints.maxWidth,
                                _JourneyMapPanel._mapPanelHeight,
                              ),
                              painter: _VietnamGeoJsonPainter(
                                geometry: geometry,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!_isInteractionActive)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        // Lần chạm đầu chỉ kích hoạt vùng bản đồ. Từ lần thao
                        // tác tiếp theo, lớp này biến mất để map nhận gesture.
                        onTap: _activateMap,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  Positioned(
                    left: 12,
                    top: 70,
                    child: IgnorePointer(
                      child: _DiscoverySummaryCard(
                        discoveredCount: widget.data.discoveredCount,
                        totalCount: widget.data.items.length,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _MapZoomControls(
                      isDark: isDark,
                      canReset: _isZoomed,
                      onZoomIn:
                          () => _zoomBy(
                            Size(
                              constraints.maxWidth,
                              _JourneyMapPanel._mapPanelHeight,
                            ),
                            0.75,
                          ),
                      onZoomOut:
                          () => _zoomBy(
                            Size(
                              constraints.maxWidth,
                              _JourneyMapPanel._mapPanelHeight,
                            ),
                            -0.75,
                          ),
                      onReset: _resetMap,
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 12,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _isZoomed ? 0 : 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? const Color(0xCC2A3440)
                                    : const Color(0xEFFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pinch_rounded, size: 15),
                              SizedBox(width: 5),
                              Text(
                                'Chụm hai ngón tay để phóng to',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({
    required this.isDark,
    required this.canReset,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final bool isDark;
  final bool canReset;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        isDark ? const Color(0x33FFFFFF) : const Color(0x14000000);
    return Material(
      color: isDark ? const Color(0xE62A3440) : const Color(0xF2FFFFFF),
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(
            icon: Icons.add_rounded,
            tooltip: 'Phóng to bản đồ',
            onPressed: onZoomIn,
          ),
          SizedBox(width: 30, child: Divider(height: 1, color: dividerColor)),
          _ZoomButton(
            icon: Icons.remove_rounded,
            tooltip: 'Thu nhỏ bản đồ',
            onPressed: onZoomOut,
          ),
          if (canReset) ...[
            SizedBox(width: 30, child: Divider(height: 1, color: dividerColor)),
            _ZoomButton(
              icon: Icons.center_focus_strong_rounded,
              tooltip: 'Đặt lại bản đồ',
              onPressed: onReset,
            ),
          ],
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      color: const Color(0xFFFF7A00),
      icon: Icon(icon, size: 22),
    );
  }
}

class _VietnamGeoJsonPainter extends CustomPainter {
  const _VietnamGeoJsonPainter({required this.geometry});

  final _GeoMapLayout geometry;
  // váº½ báº£n Ä‘á»“
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
      width: 80,
      padding: const EdgeInsets.fromLTRB(9, 10, 9, 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.journeyDiscovered,
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$discoveredCount',
                  style: const TextStyle(
                    fontSize: 25,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF8A00),
                  ),
                ),
                TextSpan(
                  text: '/$totalCount',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            AppLocalizations.of(context)!.journeyProvinceUnit,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w800,
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
      height: _JourneyMapPanel._mapPanelHeight,
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
      title: AppLocalizations.of(context)!.journeyMapLoadErrorTitle,
      message:
          details == null || details.isEmpty
              ? AppLocalizations.of(context)!.journeyMapAssetLoadError
              : AppLocalizations.of(
                context,
              )!.journeyMapGeoJsonLoadError(details),
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
    final polygons = (json['polygons'] as List<dynamic>? ?? const [])
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
  static const double _mapScaleBoost = 1.16;

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
    // váº½ báº£n Ä‘á»“
    final geoBounds = Rect.fromLTRB(minX, minY, maxX, maxY);
    const leftPanelWidth = 92.0;
    const horizontalPadding = 8.0;
    const verticalPadding = 6.0;
    final availableWidth = size.width - leftPanelWidth - horizontalPadding * 2;
    final availableHeight = size.height - verticalPadding * 2;
    final baseScale =
        availableWidth / geoBounds.width < availableHeight / geoBounds.height
            ? availableWidth / geoBounds.width
            : availableHeight / geoBounds.height;
    final scale = baseScale * _mapScaleBoost;
    final drawnWidth = geoBounds.width * scale;
    final drawnHeight = geoBounds.height * scale;
    final offsetX =
        leftPanelWidth +
        horizontalPadding +
        (availableWidth - drawnWidth) / 2 +
        8;
    final offsetY = verticalPadding + (availableHeight - drawnHeight) / 2 - 6;

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
    'Ã ': 'a',
    'Ã¡': 'a',
    'áº¡': 'a',
    'áº£': 'a',
    'Ã£': 'a',
    'Äƒ': 'a',
    'áº±': 'a',
    'áº¯': 'a',
    'áº·': 'a',
    'áº³': 'a',
    'áºµ': 'a',
    'Ã¢': 'a',
    'áº§': 'a',
    'áº¥': 'a',
    'áº­': 'a',
    'áº©': 'a',
    'áº«': 'a',
    'Ä‘': 'd',
    'Ã¨': 'e',
    'Ã©': 'e',
    'áº¹': 'e',
    'áº»': 'e',
    'áº½': 'e',
    'Ãª': 'e',
    'á»': 'e',
    'áº¿': 'e',
    'á»‡': 'e',
    'á»ƒ': 'e',
    'á»…': 'e',
    'Ã¬': 'i',
    'Ã­': 'i',
    'á»‹': 'i',
    'á»‰': 'i',
    'Ä©': 'i',
    'Ã²': 'o',
    'Ã³': 'o',
    'á»': 'o',
    'á»': 'o',
    'Ãµ': 'o',
    'Ã´': 'o',
    'á»“': 'o',
    'á»‘': 'o',
    'á»™': 'o',
    'á»•': 'o',
    'á»—': 'o',
    'Æ¡': 'o',
    'á»': 'o',
    'á»›': 'o',
    'á»£': 'o',
    'á»Ÿ': 'o',
    'á»¡': 'o',
    'Ã¹': 'u',
    'Ãº': 'u',
    'á»¥': 'u',
    'á»§': 'u',
    'Å©': 'u',
    'Æ°': 'u',
    'á»«': 'u',
    'á»©': 'u',
    'á»±': 'u',
    'á»­': 'u',
    'á»¯': 'u',
    'á»³': 'y',
    'Ã½': 'y',
    'á»µ': 'y',
    'á»·': 'y',
    'á»¹': 'y',
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
  'thanh_pho_ho_chi_minh': 'tp_ho_chi_minh',
  'tp_ho_chi_minh': 'ho_chi_minh_city',
  'ho_chi_minh_city': 'ho_chi_minh_city',
  'tp_hcm': 'ho_chi_minh_city',
  'tphcm': 'ho_chi_minh_city',
  'sai_gon': 'ho_chi_minh_city',
  'thua_thien_hue': 'hue',
};
