import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../controller/favorite/favorite_controller.dart';
import '../../controller/dish/dish_detail_controller.dart';
import '../../models/dish_model.dart';
import 'widgets/dish_detail_bottom_cta.dart';
import 'widgets/dish_detail_content_sheet.dart';
import 'widgets/dish_detail_hero_gallery.dart';
import 'widgets/dish_detail_status_views.dart';

class DishDetailPage extends StatefulWidget {
  const DishDetailPage({super.key, required this.dishId});
  final String dishId;

  @override
  State<DishDetailPage> createState() => _DishDetailPageState();
}

class _DishDetailPageState extends State<DishDetailPage> {
  bool _descExpanded = false;
  int _pageIndex = 0;
  bool _isCollapsed = false;
  late final DishDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DishDetailController()..bind(widget.dishId);
  }

  @override
  void didUpdateWidget(covariant DishDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dishId != widget.dishId) {
      _controller.bind(widget.dishId);
      _pageIndex = 0;
      _descExpanded = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateCollapsed(bool value) {
    if (_isCollapsed == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _isCollapsed = value);
    });
  }

  Future<void> _handleFavoriteTap(
    BuildContext context,
    FavoriteController favoriteController,
    String dishId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save favorites.')),
      );
      return;
    }
    await favoriteController.toggleFavorite(dishId);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Consumer<DishDetailController>(
          builder: (context, c, _) {
            if (c.isLoading) return const DishDetailLoadingView();
            if (c.error != null) return DishDetailErrorView(message: c.error!);
            final dish = c.dish;
            if (dish == null) return const DishDetailNotFoundView();

            final images = _buildImages(dish);
            final favoriteController = context.watch<FavoriteController>();
            final isFavorite = favoriteController.isFavorite(dish.id);
            // đoạn làm ảnh lên và bị đẩy lên khi vuốt 
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 200,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  leadingWidth: 58,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: DishDetailGlassIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _isCollapsed ? 1 : 0,
                    child: Text(
                      dish.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    DishDetailGlassIconButton(
                      icon: Icons.share_outlined,
                      onTap: () {
                        // TODO: share_plus => Share.share(...)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Share (TODO)'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: DishDetailFavoriteButton(
                        isFavorite: isFavorite,
                        onTap: () => _handleFavoriteTap(
                          context,
                          favoriteController,
                          dish.id,
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      final collapsed =
                          constraints.biggest.height <= (kToolbarHeight + 40);
                      _updateCollapsed(collapsed);

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Hero gallery
                          DishDetailHeroGallery(
                            images: images,
                            onPageChanged: (i) => setState(() => _pageIndex = i),
                          ),

                          // Gradient overlay
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black54,
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black54,
                                ],
                              ),
                            ),
                          ),

                          // Pagination dots
                          Positioned(
                            bottom: 70,
                            left: 0,
                            right: 0,
                            child: DishDetailDotsIndicator(
                              count: math.max(1, images.length),
                              index: _pageIndex,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Main content sheet
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: DishDetailContentSheet(
                      dish: dish,
                      descExpanded: _descExpanded,
                      onToggleDesc: () =>
                          setState(() => _descExpanded = !_descExpanded),
                    ),
                  ),
                ),

                // Spacer for bottom CTA overlay
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            );
          },
        ),

        // Sticky Bottom CTA (giống HTML)
        bottomNavigationBar: Consumer<DishDetailController>(
          builder: (context, c, _) {
            final dish = c.dish;
            if (dish == null) return const SizedBox.shrink();
            final favoriteController = context.watch<FavoriteController>();
            final isFavorite = favoriteController.isFavorite(dish.id);
            return DishDetailBottomCtaBar(
              isFavorite: isFavorite,
              onFavTap: () => _handleFavoriteTap(
                context,
                favoriteController,
                dish.id,
              ),
              onFindNearbyTap: () {
                // TODO: maps / nearby restaurants
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tìm quán gần đây (TODO)')),
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<String> _buildImages(DishModel dish) {
    // Model của bạn đang có 1 imageUrl. Nếu sau này có thêm list ảnh thì thay ở đây.
    final url = dish.imageUrl.trim();
    if (url.isEmpty) return const [];
    return [url];
  }
}

