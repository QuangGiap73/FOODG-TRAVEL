import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../cloudinary_config.dart';
import '../../models/community/community_post.dart';
import '../../models/places_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/community/community_service.dart';
import '../../services/location_service.dart';
import '../../services/map/serpapi_places_service.dart';

class CommunityCreatePostPage extends StatefulWidget {
  const CommunityCreatePostPage({super.key, this.post, this.initialText});

  static const String resultCreated = 'created';
  static const String resultUpdated = 'updated';

  final CommunityPost? post; // Neu co post -> che do sua
  final String? initialText;

  @override
  State<CommunityCreatePostPage> createState() =>
      _CommunityCreatePostPageState();
}

class _CommunityCreatePostPageState extends State<CommunityCreatePostPage> {
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _service = CommunityService();
  final _locationService = LocationService();

  bool _isPosting = false;
  bool _isUploading = false;
  bool _locLoading = false;
  double? _userLat;
  double? _userLng;
  int _selectedMode = 0;

  // Anh cu (da co tren Firestore)
  final List<PostMedia> _existingMedia = [];
  final List<_LocalMedia> _media = [];

  PlaceSnapshot? _place;
  String? _placeId;
  String? _placeSource;

  static const int _maxPhotos = 4;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
    if (widget.post != null) {
      // Prefill du lieu khi sua bai viet
      _textController.text = widget.post!.text;
      _place = widget.post!.place;
      _placeId = widget.post!.placeId;
      _placeSource = widget.post!.placeSource;
      _existingMedia.addAll(widget.post!.media);
    } else if (widget.initialText?.trim().isNotEmpty == true) {
      _textController.text = widget.initialText!.trim();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    if (_locLoading) return;
    setState(() => _locLoading = true);
    final result = await _locationService.getCurrentLocation(
      useLastKnown: true,
      timeLimit: const Duration(seconds: 8),
    );
    if (!mounted) return;
    final pos = result.position;
    if (result.isSuccess && pos != null) {
      _userLat = pos.latitude;
      _userLng = pos.longitude;
    }
    setState(() => _locLoading = false);
  }

  int _currentMediaCount() {
    // Tong so anh (cu + moi)
    return _existingMedia.length + _media.length;
  }

  Future<void> _pickFromGallery() async {
    if (_currentMediaCount() >= _maxPhotos) return;
    final remaining = _maxPhotos - _currentMediaCount();

    final picks = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picks.isEmpty) return;

    final take = picks.take(remaining);
    setState(() {
      for (final p in take) {
        _media.add(_LocalMedia(file: File(p.path)));
      }
    });
  }

  Future<void> _pickFromCamera() async {
    if (_currentMediaCount() >= _maxPhotos) return;

    final pick = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (pick == null) return;

    setState(() {
      _media.add(_LocalMedia(file: File(pick.path)));
    });
  }

  Future<void> _openMediaPicker() async {
    final t = AppLocalizations.of(context)!;
    // Bottom sheet chon nguon anh
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(t.postPickFromGallery),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(t.postPickFromCamera),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPlaceSearch() async {
    // Mo sheet tim dia diem (Goong + fallback SerpAPI)
    final result = await showModalBottomSheet<_PlacePickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F1115)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _PlaceSearchSheet(),
    );
    if (result == null) return;

    setState(() {
      _place = result.place;
      _placeId = result.placeId;
      _placeSource = result.source;
    });
  }

  Future<void> _submit() async {
    if (_isPosting) return;
    setState(() => _isPosting = true);

    try {
      final text = _textController.text;
      final isEdit = widget.post != null;

      if (isEdit) {
        // Neu co anh moi -> upload len Cloudinary
        final newMedia = <PostMedia>[];
        if (_media.isNotEmpty) {
          setState(() => _isUploading = true);
          final cloud = CloudinaryService(
            cloudName: cloudinaryCloudName,
            uploadPreset: cloudinaryUploadPreset,
            folder: cloudinaryFolder,
          );
          for (final item in _media) {
            final url = await cloud.uploadImage(item.file);
            newMedia.add(PostMedia(url: url, type: 'image'));
          }
        }

        // Media moi = anh cu con lai + anh vua upload
        final mergedMedia = <PostMedia>[
          ..._existingMedia,
          ...newMedia,
        ];

        // Sua bai viet: update text + dia diem + media
        await _service.updatePost(
          postId: widget.post!.id,
          text: text,
          place: _place,
          placeId: _placeId,
          placeSource: _placeSource,
          media: mergedMedia,
        );

        if (!mounted) return;
        Navigator.pop(context, CommunityCreatePostPage.resultUpdated);
        return;
      }

      // Upload anh len Cloudinary neu co
      final media = <PostMedia>[];
      if (_media.isNotEmpty) {
        setState(() => _isUploading = true);
        final cloud = CloudinaryService(
          cloudName: cloudinaryCloudName,
          uploadPreset: cloudinaryUploadPreset,
          folder: cloudinaryFolder,
        );

        for (final item in _media) {
          final url = await cloud.uploadImage(item.file);
          media.add(PostMedia(url: url, type: 'image'));
        }
      }

      // Tao bai viet Firestore
      await _service.createPost(
        text: text,
        media: media,
        place: _place,
        placeId: _placeId,
        placeSource: _placeSource,
      );

      if (!mounted) return;
      Navigator.pop(context, CommunityCreatePostPage.resultCreated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.postSubmitFailed(e.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFFFFBF7);
    final cardBg = isDark ? const Color(0xFF171B22) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryText = isDark ? Colors.white70 : const Color(0xFF64748B);
    final hintText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF);
    final accent = const Color(0xFFF97316);
    final isEdit = widget.post != null; // Co post => che do sua

    final user = FirebaseAuth.instance.currentUser;
    final userName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email?.trim().isNotEmpty ?? false)
            ? user!.email!
            : t.commonUserFallback;
    final avatarUrl = user?.photoURL ?? '';

    final canPost = !_isPosting &&
        (_textController.text.trim().isNotEmpty ||
            _currentMediaCount() > 0 ||
            _place != null);
    final textCount = _textController.text.trim().length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: primaryText,
        centerTitle: true,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _RoundIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          isEdit ? t.postEditTitle : 'Tạo bài viết',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: primaryText,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: canPost ? _submit : null,
              style: TextButton.styleFrom(
                backgroundColor: canPost
                    ? accent
                    : (isDark ? const Color(0xFF2A303A) : const Color(0xFFFFCBA9)),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withOpacity(0.85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                elevation: 0,
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Đăng',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModeSelector(
                selectedMode: _selectedMode,
                accent: accent,
                onChanged: (i) => setState(() => _selectedMode = i),
              ),
              const SizedBox(height: 14),

              _ComposerInputCard(
                cardBg: cardBg,
                isDark: isDark,
                primaryText: primaryText,
                secondaryText: secondaryText,
                hintText: hintText,
                avatarUrl: avatarUrl,
                userName: userName,
                textController: _textController,
                textCount: textCount,
                onChanged: () => setState(() {}),
              ),

              if (_isUploading) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(minHeight: 5),
                ),
                const SizedBox(height: 6),
                Text(t.postUploading, style: TextStyle(color: secondaryText)),
              ],

              const SizedBox(height: 22),
              _SectionTitle(
                icon: Icons.image_outlined,
                title: 'Thêm hình ảnh',
                color: primaryText,
                accent: accent,
              ),
              const SizedBox(height: 12),
              _MediaGrid(
                existing: _existingMedia,
                local: _media,
                maxCount: _maxPhotos,
                onRemoveExisting: (i) => setState(() => _existingMedia.removeAt(i)),
                onRemoveLocal: (i) => setState(() => _media.removeAt(i)),
                onAdd: _openMediaPicker,
              ),

              const SizedBox(height: 22),
              _SectionTitle(
                icon: Icons.place_rounded,
                title: 'Gắn địa điểm',
                color: primaryText,
                accent: accent,
              ),
              const SizedBox(height: 12),
              _PlaceSelector(
                place: _place,
                distanceLabel: _distanceLabelForPlace(_place),
                onPick: _openPlaceSearch,
                onClear: () => setState(() {
                  _place = null;
                  _placeId = null;
                  _placeSource = null;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _distanceLabelForPlace(PlaceSnapshot? place) {
    if (place == null || _userLat == null || _userLng == null) return '';
    final d = _distanceKm(_userLat!, _userLng!, place.lat, place.lng);
    if (d < 0.1) {
      return 'Gần bạn (${(d * 1000).round()}m)';
    }
    if (d < 1) {
      return 'Gần bạn (${(d * 1000).round()}m)';
    }
    return 'Gần bạn (${d.toStringAsFixed(1)}km)';
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371.0;
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLng = (lng2 - lng1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
}

class _LocalMedia {
  const _LocalMedia({required this.file});

  final File file;
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF171B22) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isDark ? 0 : 8,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.selectedMode,
    required this.accent,
    required this.onChanged,
  });

  final int selectedMode;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171B22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: _ComposerModeTab(
              icon: Icons.image_outlined,
              label: 'Đăng ảnh',
              selected: selectedMode == 0,
              accent: accent,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ComposerModeTab(
              icon: Icons.location_on_outlined,
              label: 'Check-in',
              selected: selectedMode == 1,
              accent: accent,
              onTap: () => onChanged(1),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ComposerModeTab(
              icon: Icons.star_border_rounded,
              label: 'Review',
              selected: selectedMode == 2,
              accent: accent,
              onTap: () => onChanged(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerModeTab extends StatelessWidget {
  const _ComposerModeTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveText = isDark ? Colors.white70 : const Color(0xFF0F172A);

    return Material(
      color: selected ? accent : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: double.infinity,
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : inactiveText),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : inactiveText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerInputCard extends StatelessWidget {
  const _ComposerInputCard({
    required this.cardBg,
    required this.isDark,
    required this.primaryText,
    required this.secondaryText,
    required this.hintText,
    required this.avatarUrl,
    required this.userName,
    required this.textController,
    required this.textCount,
    required this.onChanged,
  });

  final Color cardBg;
  final bool isDark;
  final Color primaryText;
  final Color secondaryText;
  final Color hintText;
  final String avatarUrl;
  final String userName;
  final TextEditingController textController;
  final int textCount;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF171B22), Color(0xFF171B22)],
              )
            : const LinearGradient(
                colors: [Color(0xFFFFF4E8), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Stack(
        children: [
          Positioned(
            right: 2,
            top: -8,
            child: Image.asset(
              'assets/community/community_post1.png',
              width: 122,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isDark
                            ? const Color(0xFF1F2630)
                            : const Color(0xFFE2E8F0),
                        backgroundImage:
                            avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? const Icon(Icons.person, size: 20)
                            : null,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316),
                            shape: BoxShape.circle,
                            border: Border.all(color: cardBg, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 82, top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A303A)
                                  : const Color(0xFFFFECD8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '🏅 Explorer Lv.5',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2A303A) : const Color(0xFFFFE7D3),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                child: Stack(
                  children: [
                    TextField(
                      controller: textController,
                      minLines: 5,
                      maxLines: 5,
                      maxLength: 500,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 14,
                        height: 1.38,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Bạn vừa ăn món gì ngon?',
                        hintStyle: TextStyle(color: hintText),
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Text(
                        '$textCount/500',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({
    required this.existing,
    required this.local,
    required this.maxCount,
    required this.onRemoveExisting,
    required this.onRemoveLocal,
    required this.onAdd,
  });

  final List<PostMedia> existing;
  final List<_LocalMedia> local;
  final int maxCount;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveLocal;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final totalMedia = existing.length + local.length;
    final canAdd = totalMedia < maxCount;
    final thumbnails = <Widget>[];

    for (var i = 0; i < existing.length; i++) {
      final item = existing[i];
      thumbnails.add(_MediaThumb.network(
        url: item.url,
        onRemove: () => onRemoveExisting(i),
      ));
    }

    for (var i = 0; i < local.length; i++) {
      final item = local[i];
      thumbnails.add(_MediaThumb.file(
        file: item.file,
        onRemove: () => onRemoveLocal(i),
      ));
    }

    if (thumbnails.isEmpty) {
      return _AddPhotoTile(
        onTap: canAdd ? onAdd : null,
        current: totalMedia,
        max: maxCount,
        fullWidth: true,
      );
    }

    return SizedBox(
      height: 166,
      child: Row(
        children: [
          SizedBox(
            width: 154,
            child: _AddPhotoTile(
              onTap: canAdd ? onAdd : null,
              current: totalMedia,
              max: maxCount,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: thumbnails.take(4).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    required this.onTap,
    required this.current,
    required this.max,
    this.fullWidth = false,
  });

  final VoidCallback? onTap;
  final int current;
  final int max;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFFF97316).withOpacity(0.65),
          radius: 20,
        ),
        child: Container(
          width: double.infinity,
          height: fullWidth ? 150 : double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF1A1F27) : const Color(0xFFFFFBF7),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 44,
                    color: isDark ? Colors.white54 : const Color(0xFFCBD5E1),
                  ),
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF97316),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Thêm ảnh món ăn\nhoặc quán',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$current/$max',
                style: TextStyle(
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb._({
    this.url,
    this.file,
    required this.onRemove,
  });

  factory _MediaThumb.network({
    required String url,
    required VoidCallback onRemove,
  }) {
    return _MediaThumb._(url: url, onRemove: onRemove);
  }

  factory _MediaThumb.file({
    required File file,
    required VoidCallback onRemove,
  }) {
    return _MediaThumb._(file: file, onRemove: onRemove);
  }

  final String? url;
  final File? file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final image = file != null
        ? Image.file(file!, fit: BoxFit.cover)
        : Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFE2E8F0),
              child: const Icon(Icons.image_outlined),
            ),
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: image,
          ),
        ),
        Positioned(
          top: -5,
          right: -5,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF0F172A)),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceSelector extends StatelessWidget {
  const _PlaceSelector({
    required this.place,
    required this.distanceLabel,
    required this.onPick,
    required this.onClear,
  });

  final PlaceSnapshot? place;
  final String distanceLabel;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171B22) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A303A) : const Color(0xFFFFE7D3);
    final iconBg = isDark ? const Color(0xFF2A1D12) : const Color(0xFFFFEDD5);
    final iconColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFEA580C);
    final chipBg = isDark ? const Color(0xFF2A303A) : const Color(0xFFFFF1E2);
    final chipText = isDark ? const Color(0xFFFBBF24) : const Color(0xFFEA580C);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subText = isDark ? Colors.white70 : const Color(0xFF64748B);

    if (place == null) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: cardBg,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.20 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.place_rounded, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn quán ăn hoặc địa điểm',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t.postAddPlace,
                      style: TextStyle(color: subText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: subText, size: 28),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: cardBg,
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.20 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 62,
                height: 62,
                color: iconBg,
                child: place!.photoUrl.trim().isNotEmpty
                    ? Image.network(
                        place!.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.storefront_rounded,
                          color: iconColor,
                          size: 30,
                        ),
                      )
                    : Icon(Icons.storefront_rounded, color: iconColor, size: 30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place!.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: subText, fontSize: 12),
                  ),
                  if (distanceLabel.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        distanceLabel,
                        style: TextStyle(
                          color: chipText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subText, size: 28),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    final metric = path.computeMetrics().first;
    const dash = 7.0;
    const gap = 5.0;
    var distance = 0.0;
    while (distance < metric.length) {
      final next = distance + dash;
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance = next + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _PlacePickResult {
  const _PlacePickResult({
    required this.place,
    required this.placeId,
    required this.source,
  });

  final PlaceSnapshot place;
  final String placeId;
  final String source; // serpapi
}

class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet();

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final _textController = TextEditingController();
  final _serpService = SerpApiPlacesService();
  final _locationService = LocationService();

  Timer? _debounce;
  String _query = '';
  List<GoongNearbyPlace> _results = [];
  bool _loading = false;
  double? _userLat;
  double? _userLng;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    final result = await _locationService.getCurrentLocation(
      useLastKnown: true,
      timeLimit: const Duration(seconds: 8),
    );
    if (!mounted) return;
    final pos = result.position;
    if (result.isSuccess && pos != null) {
      _userLat = pos.latitude;
      _userLng = pos.longitude;
    }
  }

  void _onQueryChanged(String value) {
    _query = value.trim();
    _error = null;
    if (_query.length < 2) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
    setState(() {});
  }

  Future<void> _search() async {
    final q = _query.trim();
    if (q.length < 2) return;
    setState(() => _loading = true);
    try {
      List<GoongNearbyPlace> results;
      if (_userLat != null && _userLng != null) {
        results = await _serpService.searchNearby(
          lat: _userLat!,
          lng: _userLng!,
          query: q,
          radius: 5000,
          limit: 12,
        );
      } else {
        results = await _serpService.searchText(
          query: q,
          limit: 12,
        );
      }

      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.postPlaceSearchError;
      });
    }
  }

  void _selectPlace(GoongNearbyPlace place) {
    final placeId = _buildPlaceIdFromSerp(place);
    final snap = PlaceSnapshot(
      name: place.name,
      address: place.address,
      lat: place.lat,
      lng: place.lng,
      photoUrl: place.photoUrl,
    );
    Navigator.pop(
      context,
      _PlacePickResult(place: snap, placeId: placeId, source: 'serpapi'),
    );
  }

  String _buildPlaceIdFromSerp(GoongNearbyPlace place) {
    final serp = place.serpDataId.trim();
    if (serp.isNotEmpty) return serp;
    final id = place.id.trim();
    if (id.isNotEmpty) return id;
    return '${place.name.trim()}_${place.lat}_${place.lng}'.replaceAll(' ', '_');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : Colors.white;
    final fieldBg = isDark ? const Color(0xFF15181E) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF2A303A) : const Color(0xFFF1F5F9);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subText = isDark ? Colors.white70 : const Color(0xFF64748B);

    final height = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: height,
      color: bg,
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Drag handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _textController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: t.postPlaceSearchHint,
                hintStyle: TextStyle(color: subText),
                prefixIcon: Icon(Icons.search, color: subText),
                filled: true,
                fillColor: fieldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onQueryChanged,
            ),
          ),

          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),

          Expanded(
            child: Builder(
              builder: (context) {
                if (_loading) {
                  return const _PlaceSkeleton();
                }
                if (_results.isNotEmpty) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final place = _results[index];
                      final title = place.name.trim().isEmpty
                          ? t.postPlaceFallbackTitle
                          : place.name.trim();
                      final subtitle = place.address.trim();
                      return InkWell(
                        onTap: () => _selectPlace(place),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: fieldBg,
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1F2630)
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.storefront, color: subText),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle.isNotEmpty
                                          ? subtitle
                                          : t.postPlaceFallbackAddress,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: subText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                if (_query.length < 2) {
                  return Center(child: Text(t.postPlaceSearchPrompt));
                }

                return Center(child: Text(t.postPlaceSearchEmpty));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceSkeleton extends StatelessWidget {
  const _PlaceSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeleton = isDark ? const Color(0xFF1F2630) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF15181E) : const Color(0xFFF8FAFC);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: cardBg,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: skeleton,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: 140,
                      decoration: BoxDecoration(
                        color: skeleton,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 8,
                      width: 180,
                      decoration: BoxDecoration(
                        color: skeleton,
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
    );
  }
}
