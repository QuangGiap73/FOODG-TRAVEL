import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../../controller/journey/journey_controller.dart';
import '../../../models/journey/checkin_result.dart';
import '../../../models/places_model.dart';
import '../../../services/restaurants/place_review_service.dart';
import '../../../views/journey/widgets2/checkin_success_dialog.dart';

class PlaceStickyActionBar extends StatefulWidget {
  const PlaceStickyActionBar({super.key, required this.place});

  // Quán đang mở trong trang chi tiết.
  final GoongNearbyPlace place;

  @override
  State<PlaceStickyActionBar> createState() => _PlaceStickyActionBarState();
}

class _PlaceStickyActionBarState extends State<PlaceStickyActionBar> {
  // Controller Journey: tu lay GPS va goi Cloud Function createCheckin.
  late final JourneyController _journeyController;

  // Dung de lay placeId dong nhat voi collection places.
  final _reviewService = PlaceReviewService();

  bool _isCheckingIn = false;

  @override
  void initState() {
    super.initState();
    _journeyController = JourneyController();
  }

  @override
  void dispose() {
    _journeyController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    if (_isCheckingIn) return;

    final messenger = ScaffoldMessenger.of(context);
    final placeId = _reviewService.placeIdOf(widget.place);

    if (placeId.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Khong the xac dinh placeId cua quan nay.'),
        ),
      );
      return;
    }

    setState(() {
      _isCheckingIn = true;
    });

    // Controller se:
    // - tu lay GPS hien tai
    // - goi Cloud Function createCheckin
    // - nhan ve diem + streak + badge
    final ok = await _journeyController.checkInPlace(
      placeId: placeId,
      placeName: widget.place.name,
      placeAddress: widget.place.address,
      placeLat: widget.place.lat,
      placeLng: widget.place.lng,
      verificationType: 'gps',
      source: 'place_detail',
      photoUrl: widget.place.photoUrl.trim().isNotEmpty
          ? widget.place.photoUrl.trim()
          : null,
      districtName: widget.place.district.trim().isNotEmpty
          ? widget.place.district.trim()
          : null,
      placeType: widget.place.category?.trim().isNotEmpty == true
          ? widget.place.category!.trim()
          : null,
    );

    if (!mounted) return;

    setState(() {
      _isCheckingIn = false;
    });

    if (ok && _journeyController.lastCheckinResult != null) {
      final result = _journeyController.lastCheckinResult!;
      await _showSuccessDialog(result);
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        content: Text(_messageForError(
          _journeyController.errorCode,
          _journeyController.errorMessage,
        )),
      ),
    );
  }

  Future<void> _showSuccessDialog(JourneyCheckinResult result) async {
  await showCheckinSuccessDialog(
    context,
    result: result,
  );
}

  String _messageForError(String? code, String? message) {
    switch (code) {
      case 'location_service_disabled':
        return 'Hay bat GPS de check-in.';
      case 'location_permission_denied':
        return 'Can cap quyen vi tri de check-in.';
      case 'location_permission_denied_forever':
        return 'Quyen vi tri dang bi chan vinh vien. Hay mo trong cai dat.';
      case 'location_timeout':
        return 'Khong lay duoc vi tri hien tai. Thu lai sau.';
      case 'unauthenticated':
        return 'Ban can dang nhap de check-in.';
      case 'failed-precondition':
        return message?.trim().isNotEmpty == true
            ? message!.trim()
            : 'Khong the check-in luc nay.';
      case 'resource-exhausted':
        return message?.trim().isNotEmpty == true
            ? message!.trim()
            : 'Ban da dat gioi han check-in trong ngay.';
      case 'invalid-argument':
        return message?.trim().isNotEmpty == true
            ? message!.trim()
            : 'Du lieu check-in khong hop le.';
      default:
        return message?.trim().isNotEmpty == true
            ? message!.trim()
            : 'Check-in that bai. Vui long thu lai.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F131A) : Colors.white;
    final border = isDark ? const Color(0xFF1F2530) : const Color(0xFFE2E8F0);
    final shadow = isDark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.08);
    final outlineColor = isDark ? const Color(0xFF2B3442) : const Color(0xFFE2E8F0);
    final outlineText = isDark ? Colors.white70 : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.bookmark_border, size: 18),
              label: Text(t.save),
              style: OutlinedButton.styleFrom(
                foregroundColor: outlineText,
                side: BorderSide(color: outlineColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              // Neu dang xu ly thi khoa nut.
              onPressed: _isCheckingIn ? null : _handleCheckIn,
              icon: _isCheckingIn
                  ? Container(
                      width: 18,
                      height: 18,
                      padding: const EdgeInsets.all(2),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.location_on_outlined, size: 18),
              label: Text(
                _isCheckingIn ? 'Dang check-in...' : 'Toi da an o day',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
