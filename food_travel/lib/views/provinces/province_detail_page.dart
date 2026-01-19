import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/dish_model.dart';
import '../../models/province_model.dart';
import '../../services/food_service.dart';

class ProvinceDetailPage extends StatefulWidget {
  const ProvinceDetailPage({super.key, required this.provinceId});
  final String provinceId;
  @override
  State<ProvinceDetailPage> createState() => _ProvinceDetailPageState();
}
class _ProvinceDetailPageState extends State<ProvinceDetailPage>{
  final _service = FoodService(); // goi du lieu firebase
  final _pageController = PageController(); // dieu khien slide anh
  final ValueNotifier<int> _imageIndex = ValueNotifier<int>(0);

  Timer? _autoSlideTimer; 
  int _imageCount = 0;
  bool _expanded = false;

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    _imageIndex.dispose();
    super.dispose();
  }
  // ham chuc nang cua slide anh
  void _startAutoSlide(int count){
    if(_imageCount == count) return;
    _imageCount = count;
    _imageIndex.value = 0;
    _autoSlideTimer?.cancel();
    if(_imageCount < 2) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_){
      if(!_pageController.hasClients) return;
      final current = _pageController.page?.round() ?? _imageIndex.value;
      final next = (current + 1) % _imageCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }
  // tạo koas nhận diện tỉnh
  List<String> _provinceQueryKeys(ProvinceModel province){
    return [
      province.code,
      province.name,
      province.id,
    ]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }
  // hien thi recode tinh bo qua nhung ki tu
  String _formatRegion(String raw){
    return raw.replaceAll('_', ' ').replaceAll(('-'), ' ');
  }
  @override
  Widget build(BuildContext context){
    final theme = Theme.of(context);
    return StreamBuilder<ProvinceModel?>(
      stream: _service.watchProvinceById(widget.provinceId), // goi du lieu
      builder: (context, snapshot){
        // hien loading khi du lieu chua load
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError){
          return const Scaffold(
            body: Center(child: Text('Khong the tai tinh thanh.')),
          );
        }
        final province = snapshot.data;
        if(province == null){
          return const Scaffold(
            body: Center(child: Text('Khong tim thay tinh.')),
          );
        }
        final images = province.imageUrls.isNotEmpty
            ? province.imageUrls
            : (province.imageUrl.isNotEmpty
                ? [province.imageUrl]
                :const <String>[]);
        _startAutoSlide(images.length);
        final desc = province.description ?? '';
        final region = (province.regionCode ?? '').trim();

        return Scaffold(
          appBar: AppBar(title: Text(province.name)),
          body: ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildHero(images, province.name),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildInfoCard(
                  theme,
                  code: province.code,
                  region: region,
                  lat: province.centerLat,
                  lng: province.centerLng,
                  slug: province.slug,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Gioi thieu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        desc.isEmpty ? 'Chua co mo ta.' : desc,
                        maxLines: _expanded ? null : 4,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (desc.length > 160)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _expanded = !_expanded),
                            child: Text(_expanded ? 'Thu gon' : 'Xem them'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Dac san tieu bieu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<DishModel>>(
                stream: _service.watchDishesByProvinceKeys(
                  _provinceQueryKeys(province),
                ),
                builder: (context, dishSnap) {
                  if (dishSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: LinearProgressIndicator(),
                    );
                  }
                  if (dishSnap.hasError) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Khong the tai mon an.'),
                    );
                  }
                  final dishes = dishSnap.data ?? [];
                  if (dishes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Chua co mon an cho tinh nay.'),
                    );
                  }
                  return SizedBox(
                    height: 220,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: dishes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _buildDishCard(dishes[index], theme);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
    
  }
  // hien thi anh mon an, neu khong co anh
  Widget _buildHero(List<String> images, String name) {
    final theme = Theme.of(context);
    if (images.isEmpty){
      return Container(
        height: 210,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.image, size: 40),
      );
    }
    return SizedBox(
      height: 210,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) => _imageIndex.value = index,
              itemBuilder: (context, index) {
                return Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceVariant,
                    child: const Icon(Icons.image, size: 40),
                  ),
                );
              },
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (images.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: ValueListenableBuilder<int>(
                  valueListenable: _imageIndex,
                  builder: (context, value, _) {
                    return Center(child: _buildDots(images.length, value));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildInfoCard(
    ThemeData theme, {
    required String code,
    required String region,
    required double? lat,
    required double? lng,
    required String? slug,
  }) {
    final chips = <String>[
      if (region.isNotEmpty) 'Vung: ${_formatRegion(region)}',
      if (code.isNotEmpty) 'Ma tinh: $code',
      if (slug != null && slug.trim().isNotEmpty) 'Slug: ${slug!.trim()}',
      if (lat != null && lng != null)
        'Toa do: ${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips
            .map(
              (label) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
  Widget _buildDishCard(DishModel dish, ThemeData theme) {
    final imageUrl = dish.imageUrl;
    return SizedBox(
      width: 170,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceVariant,
                          child: const Icon(Icons.image, size: 28),
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: const Icon(Icons.image, size: 28),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                child: Text(
                  dish.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (dish.tag.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    dish.tag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dish.spicyLevel}/5',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDots(int count, int activeIndex) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.primary : theme.dividerColor,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
