import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../cloudinary_config.dart';
import '../../models/community/community_post.dart';
import '../../models/places_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/community/community_service.dart';
import '../../services/location_service.dart';
import '../../services/map/serpapi_places_service.dart';

class CommunityCreatePostPage extends StatefulWidget {
  const CommunityCreatePostPage({super.key, this.post});

  final CommunityPost? post; // Neu co post -> che do sua

  @override
  State<CommunityCreatePostPage> createState() =>
      _CommunityCreatePostPageState();
}

class _CommunityCreatePostPageState extends State<CommunityCreatePostPage> {
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _service = CommunityService();

  bool _isPosting = false;
  bool _isUploading = false;

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
    if (widget.post != null) {
      // Prefill du lieu khi sua bai viet
      _textController.text = widget.post!.text;
      _place = widget.post!.place;
      _placeId = widget.post!.placeId;
      _placeSource = widget.post!.placeSource;
      _existingMedia.addAll(widget.post!.media);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
                title: const Text('Chon tu thu vien'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Chup anh'),
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
        Navigator.pop(context, true);
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
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dang bai that bai: $e')),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final hintText = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final isEdit = widget.post != null; // Co post => che do sua

    final user = FirebaseAuth.instance.currentUser;
    final userName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email?.trim().isNotEmpty ?? false)
            ? user!.email!
            : 'FoodG User';
    final avatarUrl = user?.photoURL ?? '';

    final canPost = !_isPosting &&
        (_textController.text.trim().isNotEmpty ||
            _currentMediaCount() > 0 ||
            _place != null);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: primaryText,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Sua bai viet' : 'Tao bai viet',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: canPost ? _submit : null,
              style: TextButton.styleFrom(
                backgroundColor: canPost
                    ? const Color(0xFFF97316)
                    : (isDark
                        ? const Color(0xFF2A303A)
                        : Colors.grey.shade300),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Luu' : 'Dang'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        isDark ? const Color(0xFF1F2630) : const Color(0xFFE2E8F0),
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    userName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Text area
              TextField(
                controller: _textController,
                minLines: 4,
                maxLines: null,
                style: TextStyle(color: primaryText),
                decoration: InputDecoration(
                  hintText: 'Ban dang cam thay the nao ve mon an hom nay?',
                  hintStyle: TextStyle(color: hintText),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Media grid + add button (cho ca tao moi & sua)
              _MediaGrid(
                existing: _existingMedia,
                local: _media,
                maxCount: _maxPhotos,
                onRemoveExisting: (i) =>
                    setState(() => _existingMedia.removeAt(i)),
                onRemoveLocal: (i) => setState(() => _media.removeAt(i)),
                onAdd: _openMediaPicker,
              ),

              if (_isUploading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const SizedBox(height: 6),
                const Text('Dang tai anh...'),
              ],

              const SizedBox(height: 18),

              // Place section
              _PlaceSelector(
                place: _place,
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
}

class _LocalMedia {
  const _LocalMedia({required this.file});

  final File file;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBg = isDark ? const Color(0xFF1A1F27) : const Color(0xFFF8FAFC);
    final borderColor =
        isDark ? const Color(0xFF2A303A) : const Color(0xFFE2E8F0);
    final iconColor = const Color(0xFF94A3B8);

    final totalMedia = existing.length + local.length;
    final canAdd = totalMedia < maxCount;
    final total = totalMedia + (canAdd ? 1 : 0);

    return GridView.builder(
      itemCount: total,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        if (index < existing.length) {
          final item = existing[index];
          // Anh cu (da upload)
          return Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(item.url, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  // Xoa anh cu khoi bai viet (khong xoa tren Cloudinary)
                  onTap: () => onRemoveExisting(index),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        }

        if (index < existing.length + local.length) {
          final localIndex = index - existing.length;
          final item = local[localIndex];
          // Anh moi (local)
          return Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(item.file, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  // Xoa anh vua chon (local)
                  onTap: () => onRemoveLocal(localIndex),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        }

        // Add tile
        return InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
              color: tileBg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, color: iconColor),
                const SizedBox(height: 6),
                Text(
                  '$totalMedia/$maxCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
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

class _PlaceSelector extends StatelessWidget {
  const _PlaceSelector({
    required this.place,
    required this.onPick,
    required this.onClear,
  });

  final PlaceSnapshot? place;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1F27) : const Color(0xFFF8FAFC);
    final borderColor =
        isDark ? const Color(0xFF2A303A) : const Color(0xFFE2E8F0);
    final iconBg = isDark ? const Color(0xFF2A1D12) : const Color(0xFFFFEDD5);
    final iconColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFEA580C);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subText = isDark ? Colors.white70 : const Color(0xFF64748B);

    if (place == null) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: cardBg,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.place, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Them dia diem',
                  style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                ),
              ),
              Icon(Icons.chevron_right, color: subText),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cardBg,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.place, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place!.name,
                  style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  place!.address,
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
          IconButton(
            onPressed: onClear,
            icon: Icon(Icons.close, color: subText),
          ),
        ],
      ),
    );
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
        _error = 'Khong tim duoc dia diem.';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : Colors.white;
    final fieldBg = isDark ? const Color(0xFF15181E) : const Color(0xFFF8FAFC);
    final borderColor =
        isDark ? const Color(0xFF2A303A) : const Color(0xFFF1F5F9);
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
              color:
                  isDark ? const Color(0xFF2A303A) : const Color(0xFFE2E8F0),
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
                hintText: 'Tim quan an, cafe...',
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
                          ? 'Quan an'
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
                                          : 'Dang cap nhat dia chi',
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
                  return const Center(child: Text('Nhap ten quan de tim.'));
                }

                return const Center(child: Text('Khong co ket qua.'));
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



