import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../cloudinary_config.dart';
import '../../controller/map/map_search_controller.dart';
import '../../models/community/community_post.dart';
import '../../services/cloudinary_service.dart';
import '../../services/community/community_service.dart';
import '../../services/map/places_service.dart';

class CommunityCreatePostPage extends StatefulWidget {
  const CommunityCreatePostPage({super.key});

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

  final List<_LocalMedia> _media = [];

  PlaceSnapshot? _place;
  String? _placeId;
  String? _placeSource;

  static const int _maxPhotos = 4;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    if (_media.length >= _maxPhotos) return;
    final remaining = _maxPhotos - _media.length;

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
    if (_media.length >= _maxPhotos) return;

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
    final detail = await showModalBottomSheet<GoongPlaceDetail>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _PlaceSearchSheet(),
    );
    if (detail == null) return;

    setState(() {
      _place = PlaceSnapshot(
        name: detail.name,
        address: detail.address,
        lat: detail.lat,
        lng: detail.lng,
        photoUrl: detail.photoUrl,
      );
      _placeId = detail.placeId;
      _placeSource = 'goong';
    });
  }

  Future<void> _submit() async {
    if (_isPosting) return;
    setState(() => _isPosting = true);

    try {
      final text = _textController.text;

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
    final canPost = !_isPosting &&
        (_textController.text.trim().isNotEmpty ||
            _media.isNotEmpty ||
            _place != null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tao bai viet'),
        actions: [
          TextButton(
            onPressed: canPost ? _submit : null,
            child: _isPosting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Dang'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _textController,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Ban dang cam thay the nao?',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          if (_media.isNotEmpty)
            _MediaGrid(
              items: _media,
              onRemove: (i) => setState(() => _media.removeAt(i)),
            ),
          if (_media.isNotEmpty) const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _openMediaPicker,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              _media.isEmpty
                  ? 'Them anh'
                  : 'Them anh (${_media.length}/$_maxPhotos)',
            ),
          ),
          const SizedBox(height: 20),

          _PlaceSelector(
            place: _place,
            onPick: _openPlaceSearch,
            onClear: () => setState(() {
              _place = null;
              _placeId = null;
              _placeSource = null;
            }),
          ),

          if (_isUploading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 4),
            const Text('Dang tai anh...'),
          ],
        ],
      ),
    );
  }
}

class _LocalMedia {
  const _LocalMedia({required this.file});

  final File file;
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.items, required this.onRemove});

  final List<_LocalMedia> items;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(item.file, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => onRemove(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
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
    if (place == null) {
      return OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.place_outlined),
        label: const Text('Them dia diem'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.place, color: Color(0xFFFF6A00)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place!.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  place!.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet();

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final _controller = MapSearchController();
  final _textController = TextEditingController();

  bool _loadingDetail = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _select(GoongPrediction prediction) async {
    setState(() {
      _loadingDetail = true;
      _error = null;
    });

    final detail = await _controller.fetchDetail(prediction);
    if (!mounted) return;

    if (detail == null) {
      setState(() {
        _loadingDetail = false;
        _error = 'Khong lay duoc thong tin dia diem.';
      });
      return;
    }

    Navigator.pop(context, detail);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.8;

    return SizedBox(
      height: height,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Tim quan an...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _controller.onQueryChanged,
              ),
            ),
            if (_loadingDetail) const LinearProgressIndicator(minHeight: 2),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final items = _controller.suggestions;
                  if (_controller.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (items.isEmpty) {
                    return const Center(child: Text('Khong co ket qua.'));
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(item.description),
                        onTap: () => _select(item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
