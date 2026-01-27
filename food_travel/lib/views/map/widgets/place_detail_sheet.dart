import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../models/places_model.dart';

Future<void> showPlaceDetailSheet(
  BuildContext context,
  GoongNearbyPlace place, {
  LatLng? userLocation,
  VoidCallback? onDirections,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height * 0.62;
      return SizedBox(
        height: height,
        child: PlaceDetailSheet(
          place: place,
          userLocation: userLocation,
          onDirections: onDirections,
        ),
      );
    },
  );
}

class PlaceDetailSheet extends StatelessWidget {
  const PlaceDetailSheet({
    super.key,
    required this.place,
    this.userLocation,
    this.onDirections,
  });

  final GoongNearbyPlace place;
  final LatLng? userLocation;
  final VoidCallback? onDirections;

  double? _distanceMeters() {
    if (userLocation == null) return null;
    return Geolocator.distanceBetween(
      userLocation!.latitude,
      userLocation!.longitude,
      place.lat,
      place.lng,
    );
  }

  String? _formatDistance(double? meters) {
    if (meters == null) return null;
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _statusLine() {
    final openNow = place.isOpen;
    final status = openNow == null
        ? 'Dang cap nhat gio mo cua'
        : (openNow ? 'Dang mo cua' : 'Dang dong cua');
    final closing = place.closingTime?.trim();
    if (closing == null || closing.isEmpty) return status;
    return '$status - Dong luc $closing';
  }

  List<Widget> _buildStars(double rating) {
    final out = <Widget>[];
    for (var i = 1; i <= 5; i++) {
      if (rating >= i) {
        out.add(Icon(Icons.star, size: 14, color: Colors.amber.shade600));
      } else if (rating >= i - 0.5) {
        out.add(Icon(Icons.star_half, size: 14, color: Colors.amber.shade600));
      } else {
        out.add(Icon(Icons.star_border, size: 14, color: Colors.amber.shade600));
      }
    }
    return out;
  }

  Widget _buildActionIcon(
    BuildContext context,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF12161A) : const Color(0xFFF4F6F8);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);
    final iconColor = isDark
        ? theme.colorScheme.onSurface.withOpacity(0.72)
        : theme.colorScheme.onSurface.withOpacity(0.86);
    return SizedBox(
      width: 46,
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: bgColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Icon(
          icon,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final name = place.name.trim().isEmpty ? 'Quan gan day' : place.name.trim();
    final category = place.category?.trim();
    final subTitle =
        (category == null || category.isEmpty) ? 'Am thuc dia phuong' : category;
    final imageUrl = place.photoUrl.trim();
    final isDark = theme.brightness == Brightness.dark;
    final placeholderColors = isDark
        ? const [Color(0xFF2A2E33), Color(0xFF1C1F23)]
        : const [Color(0xFFF6F7F9), Color(0xFFE9EDF2)];
    final overlayTopOpacity = isDark ? 0.05 : 0.02;
    final overlayBottomOpacity = isDark ? 0.65 : 0.55;

    return SizedBox(
      height: 118,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: imageUrl.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: placeholderColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: placeholderColors.first,
                      ),
                    ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(overlayTopOpacity),
                    Colors.black.withOpacity(overlayBottomOpacity),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 64,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black.withOpacity(0.6) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);
    final iconColor = isDark ? Colors.white : theme.colorScheme.onSurface;
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, right: 10),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.close, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final meters = _distanceMeters();
    final distance = _formatDistance(meters);
    final rating = place.rating;
    final reviews = place.reviewCount;
    final price = place.price?.trim();
    final phone = place.phone?.trim();
    final address =
        place.address.trim().isEmpty ? 'Dang cap nhat dia chi' : place.address;
    final openNow = place.isOpen;
    final hintColor = isDark
        ? theme.hintColor
        : theme.colorScheme.onSurface.withOpacity(0.6);
    final statusColor = openNow == null
        ? hintColor
        : (openNow ? const Color(0xFF16A34A) : const Color(0xFFDC2626));
    final cardColor = isDark ? const Color(0xFF1B1F23) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.35)
        : Colors.black.withOpacity(0.14);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(theme),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (rating != null) ...[
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  ..._buildStars(rating),
                                  if (reviews != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '($reviews)',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: hintColor,
                                      ),
                                    ),
                                  ],
                                ] else
                                  Text(
                                    'Chua co danh gia',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: hintColor,
                                    ),
                                  ),
                                const Spacer(),
                                if (price != null && price.isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        price,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '/nguoi',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: statusColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _statusLine(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 18,
                                  color: hintColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        address,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        distance == null
                                            ? 'Cach day dang cap nhat'
                                            : 'Cach day $distance',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.call_outlined,
                                  size: 18,
                                  color: hintColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  phone == null || phone.isEmpty
                                      ? 'Chua co so dien thoai'
                                      : phone,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 46,
                                    child: ElevatedButton.icon(
                                      onPressed: onDirections,
                                      icon: const Icon(Icons.navigation),
                                      label: const Text(
                                        'Chi duong',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade700,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _buildActionIcon(
                                  context,
                                  Icons.call,
                                ),
                                const SizedBox(width: 10),
                                _buildActionIcon(
                                  context,
                                  Icons.bookmark_border,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCloseButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
