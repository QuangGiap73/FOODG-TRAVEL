import 'package:flutter/material.dart';
import 'package:food_travel/data/provinces.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../../controller/onboarding/survey_controller.dart';

class SurveyFormContent extends StatefulWidget {
  const SurveyFormContent({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.compact = false,
    this.onClose,
    this.loadingProfile = false,
  });

  final SurveyController controller;
  final Future<void> Function() onSubmit;
  final bool compact;
  final VoidCallback? onClose;
  final bool loadingProfile;

  @override
  State<SurveyFormContent> createState() => _SurveyFormContentState();
}

class _SurveyFormContentState extends State<SurveyFormContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _favoriteInput = TextEditingController();
  final TextEditingController _dislikeInput = TextEditingController();
  final TextEditingController _allergyInput = TextEditingController();

  static const List<_Choice> _dishTypes = [
    _Choice('mon_nuoc', 'Món nước', 'Soup & noodles'),
    _Choice('mon_kho', 'Món khô', 'Dry dishes'),
    _Choice('an_vat', 'Ăn vặt', 'Snacks'),
    _Choice('mon_chinh', 'Món chính', 'Main dishes'),
    _Choice('trang_mieng', 'Tráng miệng', 'Desserts'),
    _Choice('mon_banh', 'Món bánh', 'Cakes & pastry'),
  ];

  static const List<_Choice> _flavors = [
    _Choice('thanh_nhe', 'Thanh nhẹ', 'Light'),
    _Choice('dam_da', 'Đậm đà', 'Bold'),
    _Choice('chua', 'Chua', 'Sour'),
    _Choice('ngot', 'Ngọt', 'Sweet'),
    _Choice('beo', 'Béo', 'Rich'),
    _Choice('man', 'Mặn', 'Savory'),
    _Choice('thom_gia_vi', 'Thơm gia vị', 'Herbal'),
    _Choice('cay', 'Cay', 'Spicy'),
  ];

  static const List<_Choice> _mealTimes = [
    _Choice('breakfast', 'Bữa sáng', 'Breakfast'),
    _Choice('lunch', 'Bữa trưa', 'Lunch'),
    _Choice('dinner', 'Bữa tối', 'Dinner'),
    _Choice('snack', 'Ăn vặt', 'Snack'),
    _Choice('late_night', 'Ăn khuya', 'Late night'),
  ];

  static const List<_Choice> _seasons = [
    _Choice('spring', 'Mùa xuân', 'Spring'),
    _Choice('summer', 'Mùa hè', 'Summer'),
    _Choice('autumn', 'Mùa thu', 'Autumn'),
    _Choice('winter', 'Mùa đông', 'Winter'),
    _Choice('all_season', 'Quanh năm', 'All season'),
  ];

  static const List<_Choice> _regions = [
    _Choice('mien_bac', 'Miền Bắc', 'North'),
    _Choice('mien_trung', 'Miền Trung', 'Central'),
    _Choice('mien_nam', 'Miền Nam', 'South'),
  ];

  static const List<_Choice> _allergies = [
    _Choice('peanut', 'Đậu phộng', 'Peanuts'),
    _Choice('seafood', 'Hải sản', 'Seafood'),
    _Choice('milk', 'Sữa', 'Milk'),
    _Choice('organ_meat', 'Nội tạng', 'Organ meat'),
    _Choice('fermented', 'Mắm nặng mùi', 'Fermented'),
    _Choice('raw_food', 'Đồ sống', 'Raw food'),
  ];

  static const List<_Choice> _diets = [
    _Choice('normal', 'Ăn bình thường', 'Regular'),
    _Choice('vegetarian', 'Ăn chay', 'Vegetarian'),
    _Choice('healthy', 'Eat clean', 'Healthy'),
    _Choice('low_carb', 'Ít tinh bột', 'Low carb'),
    _Choice('low_oil', 'Ít dầu mỡ', 'Low oil'),
    _Choice('low_sugar', 'Ít đường', 'Low sugar'),
  ];

  static const List<_Choice> _contexts = [
    _Choice('solo', 'Một mình', 'Solo'),
    _Choice('couple', 'Cặp đôi', 'Couple'),
    _Choice('family', 'Gia đình', 'Family'),
    _Choice('friends', 'Nhóm bạn', 'Friends'),
  ];

  static const List<_Choice> _goals = [
    _Choice('eat_full', 'Ăn no', 'Full meal'),
    _Choice('eat_light', 'Ăn nhẹ', 'Light meal'),
    _Choice('famous_specialty', 'Đặc sản nổi tiếng', 'Famous specialty'),
    _Choice('photo_worthy', 'Check-in đẹp', 'Photo worthy'),
    _Choice('hidden_local', 'Món địa phương', 'Local hidden gem'),
  ];

  @override
  void dispose() {
    _favoriteInput.dispose();
    _dislikeInput.dispose();
    _allergyInput.dispose();
    super.dispose();
  }

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';

  String _label(_Choice item) => _isVi ? item.vi : item.en;

  Future<void> _handleSubmit() async {
    _commitPendingTags(_favoriteInput, widget.controller.favoritesController);
    _commitPendingTags(_dislikeInput, widget.controller.dislikesController);
    _commitPendingTags(_allergyInput, widget.controller.allergiesController);
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit();
  }

  void _commitPendingTags(
    TextEditingController input,
    TextEditingController source,
  ) {
    final pending = input.text
        .split(RegExp(r'[\n,]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    if (pending.isEmpty) return;

    final items =
        source.text
            .split(RegExp(r'[\n,]+'))
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList();
    for (final item in pending) {
      if (!items.contains(item)) items.add(item);
    }
    source.text = items.join(', ');
    input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E131A) : const Color(0xFFFFFAF3);
    final surface = isDark ? const Color(0xFF171E28) : Colors.white;
    final border = isDark ? const Color(0xFF3A4658) : const Color(0xFFF1E6D8);
    final text = isDark ? Colors.white : const Color(0xFF1F2937);
    final sub = isDark ? const Color(0xFFC5CEDA) : const Color(0xFF6B7280);
    const accent = Color(0xFFF97316);

    final content = Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          widget.compact ? 16 : 20,
          widget.compact ? 12 : 14,
          widget.compact ? 16 : 20,
          24,
        ),
        children: [
          if (!widget.compact) ...[
            _HeroCard(
              title: _isVi ? 'Khảo sát khẩu vị món ăn' : 'Taste profile survey',
              subtitle:
                  _isVi
                      ? 'Điền nhanh để ứng dụng hiểu khẩu vị, vùng miền, ngân sách và ngữ cảnh ăn uống của bạn.'
                      : 'Complete a short survey so the app understands your taste, region, budget, and dining context.',
              loadingProfile: widget.loadingProfile,
              accent: accent,
              onClose: widget.onClose,
            ),
            const SizedBox(height: 16),
          ],
          _Card(
            surface: surface,
            border: border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.location_city_rounded,
                  imageAsset: 'assets/survey/generated/province.png',
                  title: t.surveyProvinceLabel,
                  subtitle:
                      _isVi
                          ? 'Chọn tỉnh/thành hiện tại để gợi ý món, quán và bài viết gần bạn hơn.'
                          : 'Select your current province to localize dish and place suggestions.',
                  accent: accent,
                  textColor: text,
                  subColor: sub,
                ),
                const SizedBox(height: 16),
                _ProvinceField(
                  controller: widget.controller.provinceController,
                  label: t.surveyProvinceLabel,
                  requiredText: t.surveyProvinceRequired,
                  textColor: text,
                  border: border,
                  surface:
                      isDark
                          ? const Color(0xFF121821)
                          : const Color(0xFFFFFCF8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            surface: surface,
            border: border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.local_fire_department_rounded,
                  imageAsset: 'assets/survey/generated/spice.png',
                  title: _isVi ? 'Mức ăn cay' : 'Spice tolerance',
                  subtitle:
                      _isVi
                          ? 'Dùng để tránh gợi ý món quá cay hoặc quá nhạt.'
                          : 'Used to avoid dishes that are too spicy or too mild.',
                  accent: accent,
                  textColor: text,
                  subColor: sub,
                ),
                const SizedBox(height: 16),
                _InfoPill(
                  left: '${widget.controller.spicyLevel}/5',
                  right: _isVi ? 'Khẩu vị cay' : 'Spice profile',
                  accent: accent,
                  textColor: text,
                  subColor: sub,
                ),
                Slider(
                  min: 0,
                  max: 5,
                  divisions: 5,
                  value: widget.controller.spicyLevel.toDouble(),
                  activeColor: accent,
                  inactiveColor:
                      isDark
                          ? const Color(0xFF566274)
                          : const Color(0xFFD1D5DB),
                  onChanged: widget.controller.setSpicyLevel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            surface: surface,
            border: border,
            child: _ChoiceSection(
              icon: Icons.ramen_dining_rounded,
              imageAsset: 'assets/survey/generated/dish_type.png',
              title: _isVi ? 'Kiểu món bạn thích' : 'Preferred dish styles',
              subtitle:
                  _isVi
                      ? 'Chọn các nhóm món bạn hay ăn nhất.'
                      : 'Pick the dish types you enjoy most.',
              choices: _dishTypes,
              selected: widget.controller.preferredDishTypes,
              onToggle:
                  (value) => widget.controller.toggleSetValue(
                    widget.controller.preferredDishTypes,
                    value,
                  ),
              labelBuilder: _label,
              accent: accent,
              textColor: text,
              subColor: sub,
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            surface: surface,
            border: border,
            child: _ChoiceSection(
              icon: Icons.tungsten_rounded,
              title: _isVi ? 'Hương vị yêu thích' : 'Flavor preferences',
              subtitle:
                  _isVi
                      ? 'Dữ liệu này rất hữu ích để AI đối chiếu với metadata món ăn.'
                      : 'This is useful for matching dish metadata later.',
              choices: _flavors,
              selected: widget.controller.flavorPreferences,
              onToggle:
                  (value) => widget.controller.toggleSetValue(
                    widget.controller.flavorPreferences,
                    value,
                  ),
              labelBuilder: _label,
              accent: accent,
              textColor: text,
              subColor: sub,
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            surface: surface,
            border: border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.lunch_dining_rounded,
                  imageAsset: 'assets/survey/generated/satiety.png',
                  title: _isVi ? 'Mức no mong muốn' : 'Satiety preference',
                  subtitle:
                      _isVi
                          ? 'Giúp ưu tiên món ăn nhẹ hoặc món no bụng.'
                          : 'Helps prioritize lighter or more filling meals.',
                  accent: accent,
                  textColor: text,
                  subColor: sub,
                ),
                const SizedBox(height: 14),
                SegmentedButton<int>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return isDark
                            ? const Color(0xFF7C2D12)
                            : const Color(0xFFFFE8D5);
                      }
                      return isDark ? const Color(0xFF202936) : Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (isDark) return Colors.white;
                      return states.contains(WidgetState.selected)
                          ? const Color(0xFF9A3412)
                          : const Color(0xFF374151);
                    }),
                    side: WidgetStatePropertyAll(BorderSide(color: border)),
                  ),
                  segments: [
                    ButtonSegment(
                      value: 0,
                      label: Text(_isVi ? 'Ăn nhẹ' : 'Light'),
                    ),
                    ButtonSegment(
                      value: 3,
                      label: Text(_isVi ? 'Vừa đủ' : 'Balanced'),
                    ),
                    ButtonSegment(
                      value: 5,
                      label: Text(_isVi ? 'No bụng' : 'Filling'),
                    ),
                  ],
                  selected: {widget.controller.satietyPreference},
                  onSelectionChanged: (value) {
                    widget.controller.setSatietyPreference(value.first);
                  },
                ),
                const SizedBox(height: 18),
                _ChoiceSection(
                  icon: Icons.schedule_rounded,
                  title:
                      _isVi ? 'Thời điểm ăn thường xuyên' : 'Meal time context',
                  subtitle:
                      _isVi
                          ? 'Giúp gợi ý món đúng thời điểm như sáng, trưa, tối hoặc ăn vặt.'
                          : 'Helps recommend dishes for breakfast, lunch, dinner, or snack time.',
                  choices: _mealTimes,
                  selected: widget.controller.preferredMealTimes,
                  onToggle:
                      (value) => widget.controller.toggleSetValue(
                        widget.controller.preferredMealTimes,
                        value,
                      ),
                  labelBuilder: _label,
                  accent: accent,
                  textColor: text,
                  subColor: sub,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            surface: surface,
            border: border,
            child: _ChoiceSection(
              icon: Icons.public_rounded,
              imageAsset: 'assets/survey/generated/preferred_region.png',
              title: _isVi ? 'Vùng miền muốn khám phá' : 'Preferred regions',
              subtitle:
                  _isVi
                      ? 'Chọn vùng miền bạn muốn ứng dụng ưu tiên khi tìm món.'
                      : 'Choose the regions you want the app to prioritize.',
              choices: _regions,
              selected: widget.controller.preferredRegions,
              onToggle:
                  (value) => widget.controller.toggleSetValue(
                    widget.controller.preferredRegions,
                    value,
                  ),
              labelBuilder: _label,
              accent: accent,
              textColor: text,
              subColor: sub,
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            surface: surface,
            border: border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TagEditor(
                  icon: Icons.health_and_safety_rounded,
                  imageAsset: 'assets/survey/generated/allergy.png',
                  title:
                      _isVi
                          ? 'Dị ứng và kiêng kỵ'
                          : 'Allergies and restrictions',
                  subtitle:
                      _isVi
                          ? 'Những thông tin này rất quan trọng để loại trừ món không phù hợp.'
                          : 'This is critical for filtering out unsuitable dishes.',
                  inputController: _allergyInput,
                  sourceController: widget.controller.allergiesController,
                  accent: accent,
                  textColor: text,
                  subColor: sub,
                  chipBg:
                      isDark
                          ? const Color(0xFF332126)
                          : const Color(0xFFFEE2E2),
                  border: border,
                ),
                const SizedBox(height: 16),
                _TagEditor(
                  icon: Icons.block_rounded,
                  imageAsset: 'assets/survey/generated/disliked_ingredient.png',
                  title:
                      _isVi
                          ? 'Nguyên liệu không thích'
                          : 'Disliked ingredients',
                  subtitle:
                      _isVi
                          ? 'Ví dụ: rau mùi, mắm tôm, nội tạng...'
                          : 'Example: coriander, fermented shrimp paste, organ meat...',
                  inputController: _dislikeInput,
                  sourceController: widget.controller.dislikesController,
                  accent: const Color(0xFF64748B),
                  textColor: text,
                  subColor: sub,
                  chipBg:
                      isDark
                          ? const Color(0xFF26303C)
                          : const Color(0xFFF3F4F6),
                  border: border,
                ),
                const SizedBox(height: 16),
                _ChoiceSection(
                  icon: Icons.spa_rounded,
                  title: _isVi ? 'Chế độ ăn hiện tại' : 'Diet preferences',
                  subtitle:
                      _isVi
                          ? 'Cho biết nếu bạn đang ăn chay, low-carb hoặc eat clean.'
                          : 'Tell us if you are vegetarian, low-carb, or eating clean.',
                  choices: _diets,
                  selected: widget.controller.dietPreferences,
                  onToggle:
                      (value) => widget.controller.toggleSetValue(
                        widget.controller.dietPreferences,
                        value,
                      ),
                  labelBuilder: _label,
                  accent: accent,
                  textColor: text,
                  subColor: sub,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            surface: surface,
            border: border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.payments_rounded,
                  title: _isVi ? 'Ngân sách thường chọn' : 'Budget preference',
                  subtitle:
                      _isVi
                          ? 'Dùng để lọc bớt món quá rẻ hoặc quá cao so với thói quen của bạn.'
                          : 'Used to avoid dishes that are too cheap or too expensive for your habits.',
                  accent: accent,
                  textColor: text,
                  subColor: sub,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _BudgetChip(
                      active:
                          widget.controller.budgetMin == 0 &&
                          widget.controller.budgetMax == 30000,
                      label: _isVi ? 'Dưới 30k' : 'Under 30k',
                      onTap: () => widget.controller.setBudgetRange(0, 30000),
                    ),
                    _BudgetChip(
                      active:
                          widget.controller.budgetMin == 30000 &&
                          widget.controller.budgetMax == 60000,
                      label: '30k - 60k',
                      onTap:
                          () => widget.controller.setBudgetRange(30000, 60000),
                    ),
                    _BudgetChip(
                      active:
                          widget.controller.budgetMin == 60000 &&
                          widget.controller.budgetMax == 100000,
                      label: '60k - 100k',
                      onTap:
                          () => widget.controller.setBudgetRange(60000, 100000),
                    ),
                    _BudgetChip(
                      active:
                          widget.controller.budgetMin == 100000 &&
                          widget.controller.budgetMax == 300000,
                      label: _isVi ? 'Trên 100k' : 'Over 100k',
                      onTap:
                          () =>
                              widget.controller.setBudgetRange(100000, 300000),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionHeader(
                  icon: Icons.explore_rounded,
                  title: _isVi ? 'Mức thích thử món mới' : 'Discovery level',
                  subtitle:
                      _isVi
                          ? '1 là rất an toàn, 5 là rất thích thử món lạ.'
                          : '1 means safe choices, 5 means adventurous eater.',
                  accent: accent,
                  textColor: text,
                  subColor: sub,
                ),
                Slider(
                  min: 1,
                  max: 5,
                  divisions: 4,
                  value: widget.controller.discoveryLevel.toDouble(),
                  activeColor: accent,
                  inactiveColor:
                      isDark
                          ? const Color(0xFF566274)
                          : const Color(0xFFD1D5DB),
                  onChanged: widget.controller.setDiscoveryLevel,
                ),
                const SizedBox(height: 18),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: widget.controller.followSeasonalSuggestions,
                  activeColor: accent,
                  onChanged: widget.controller.setFollowSeasonalSuggestions,
                  title: Text(
                    _isVi
                        ? 'Ưu tiên gợi ý món theo mùa hiện tại'
                        : 'Prioritize dishes suitable for the current season',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: text,
                    ),
                  ),
                  subtitle: Text(
                    _isVi
                        ? 'Bật tùy chọn này nếu bạn muốn ứng dụng ưu tiên món hợp thời tiết và mùa vụ.'
                        : 'Turn this on if you want the app to prioritize seasonally suitable dishes.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: sub),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            surface: surface,
            border: border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChoiceSection(
                  icon: Icons.eco_rounded,
                  imageAsset: 'assets/survey/generated/seasonal.png',
                  title: _isVi ? 'Mùa món ăn phù hợp' : 'Preferred seasons',
                  subtitle:
                      _isVi
                          ? 'Chọn mùa để đối chiếu với suitableForSeason của món ăn.'
                          : 'Choose seasons to match dish suitableForSeason metadata.',
                  choices: _seasons,
                  selected: widget.controller.preferredSeasons,
                  onToggle:
                      (value) => widget.controller.toggleSetValue(
                        widget.controller.preferredSeasons,
                        value,
                      ),
                  labelBuilder: _label,
                  accent: accent,
                  textColor: text,
                  subColor: sub,
                ),
                const SizedBox(height: 16),
                _ChoiceSection(
                  icon: Icons.groups_rounded,
                  title: _isVi ? 'Bạn thường đi ăn với ai?' : 'Dining context',
                  subtitle:
                      _isVi
                          ? 'Ngữ cảnh ăn uống giúp gợi ý đúng kiểu món và quán.'
                          : 'Dining context helps tailor dish and place suggestions.',
                  choices: _contexts,
                  selected: widget.controller.diningContexts,
                  onToggle:
                      (value) => widget.controller.toggleSetValue(
                        widget.controller.diningContexts,
                        value,
                      ),
                  labelBuilder: _label,
                  accent: accent,
                  textColor: text,
                  subColor: sub,
                ),
                const SizedBox(height: 16),
                _ChoiceSection(
                  icon: Icons.flag_rounded,
                  title:
                      _isVi ? 'Mục tiêu khi tìm món' : 'Recommendation goals',
                  subtitle:
                      _isVi
                          ? 'Ưu tiên món no bụng, check-in đẹp, hoặc đặc sản nổi bật.'
                          : 'Prioritize filling meals, photo spots, or famous specialties.',
                  choices: _goals,
                  selected: widget.controller.recommendationGoals,
                  onToggle:
                      (value) => widget.controller.toggleSetValue(
                        widget.controller.recommendationGoals,
                        value,
                      ),
                  labelBuilder: _label,
                  accent: accent,
                  textColor: text,
                  subColor: sub,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            surface: surface,
            border: border,
            child: _TagEditor(
              icon: Icons.favorite_rounded,
              imageAsset: 'assets/survey/generated/favorite_keyword.png',
              title: _isVi ? 'Món / từ khóa yêu thích' : 'Favorite food tags',
              subtitle:
                  _isVi
                      ? 'Ví dụ: phở, bún bò, bánh mì, cà phê trứng...'
                      : 'Example: pho, bun bo, banh mi, egg coffee...',
              inputController: _favoriteInput,
              sourceController: widget.controller.favoritesController,
              accent: accent,
              textColor: text,
              subColor: sub,
              chipBg:
                  isDark ? const Color(0xFF2A3342) : const Color(0xFFFFEDD5),
              border: border,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: widget.controller.isLoading ? null : _handleSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child:
                  widget.controller.isLoading
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(
                        _isVi ? 'Lưu khảo sát khẩu vị' : 'Save taste profile',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );

    if (widget.compact) {
      return Material(color: bg, child: content);
    }

    return Scaffold(backgroundColor: bg, body: SafeArea(child: content));
  }
}

class _Choice {
  const _Choice(this.value, this.vi, this.en);

  final String value;
  final String vi;
  final String en;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.loadingProfile,
    required this.accent,
    this.onClose,
  });

  final String title;
  final String subtitle;
  final bool loadingProfile;
  final Color accent;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onClose != null)
              Material(
                color:
                    isDark
                        ? const Color(0xFF202936)
                        : Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(18),
                child: IconButton(
                  onPressed: onClose,
                  tooltip:
                      Localizations.localeOf(context).languageCode == 'vi'
                          ? 'Để sau'
                          : 'Do it later',
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
            const Spacer(),
            if (loadingProfile)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: accent,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Semantics(
          label: '$title. $subtitle',
          image: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 2,
              child: Image.asset(
                'assets/person/banenr-khao-sat.png',
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color:
                          isDark
                              ? const Color(0xFF4A2618)
                              : const Color(0xFFFFE0BD),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.assignment_rounded,
                        size: 48,
                        color: accent,
                      ),
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.surface,
    required this.border,
    required this.child,
  });

  final Color surface;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.textColor,
    required this.subColor,
  });

  final IconData icon;
  final String? imageAsset;
  final String title;
  final String subtitle;
  final Color accent;
  final Color textColor;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child:
              imageAsset == null
                  ? Icon(icon, color: accent)
                  : Padding(
                    padding: const EdgeInsets.all(5),
                    child: Image.asset(
                      imageAsset!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) => Icon(icon, color: accent),
                    ),
                  ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, height: 1.4, color: subColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.icon,
    this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.choices,
    required this.selected,
    required this.onToggle,
    required this.labelBuilder,
    required this.accent,
    required this.textColor,
    required this.subColor,
  });

  final IconData icon;
  final String? imageAsset;
  final String title;
  final String subtitle;
  final List<_Choice> choices;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String Function(_Choice) labelBuilder;
  final Color accent;
  final Color textColor;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: icon,
          imageAsset: imageAsset,
          title: title,
          subtitle: subtitle,
          accent: accent,
          textColor: textColor,
          subColor: subColor,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              choices.map((item) {
                final isSelected = selected.contains(item.value);
                return FilterChip(
                  label: Text(
                    labelBuilder(item),
                    style: TextStyle(
                      color:
                          isDark
                              ? Colors.white
                              : (isSelected
                                  ? const Color(0xFF9A3412)
                                  : textColor),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: isSelected,
                  backgroundColor: isDark ? const Color(0xFF202936) : null,
                  selectedColor:
                      isDark
                          ? const Color(0xFF7C2D12)
                          : const Color(0xFFFFE8D5),
                  checkmarkColor: isDark ? Colors.white : accent,
                  side: BorderSide(
                    color:
                        isSelected
                            ? accent.withValues(alpha: 0.75)
                            : (isDark
                                ? const Color(0xFF465365)
                                : const Color(0xFFE5E7EB)),
                  ),
                  onSelected: (_) => onToggle(item.value),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class _ProvinceField extends StatelessWidget {
  const _ProvinceField({
    required this.controller,
    required this.label,
    required this.requiredText,
    required this.textColor,
    required this.border,
    required this.surface,
  });

  final TextEditingController controller;
  final String label;
  final String requiredText;
  final Color textColor;
  final Color border;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) {
          return const Iterable<String>.empty();
        }

        return vietnamProvinces.where(
          (province) => province.toLowerCase().contains(query),
        );
      },
      onSelected: (selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        if (textController.text.isEmpty && controller.text.isNotEmpty) {
          textController.text = controller.text;
        }

        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            hintText: label,
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              borderSide: BorderSide(color: Color(0xFFF97316), width: 1.4),
            ),
          ),
          style: TextStyle(color: textColor),
          onChanged: (value) => controller.text = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return requiredText;
            }
            return null;
          },
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.left,
    required this.right,
    required this.accent,
    required this.textColor,
    required this.subColor,
  });

  final String left;
  final String right;
  final Color accent;
  final Color textColor;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(
            left,
            style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
          ),
          const Spacer(),
          Text(right, style: TextStyle(fontSize: 12, color: subColor)),
        ],
      ),
    );
  }
}

class _TagEditor extends StatefulWidget {
  const _TagEditor({
    required this.icon,
    this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.inputController,
    required this.sourceController,
    required this.accent,
    required this.textColor,
    required this.subColor,
    required this.chipBg,
    required this.border,
  });

  final IconData icon;
  final String? imageAsset;
  final String title;
  final String subtitle;
  final TextEditingController inputController;
  final TextEditingController sourceController;
  final Color accent;
  final Color textColor;
  final Color subColor;
  final Color chipBg;
  final Color border;

  @override
  State<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<_TagEditor> {
  List<String> get _items =>
      widget.sourceController.text
          .split(RegExp(r'[\n,]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

  void _sync(List<String> items) {
    widget.sourceController.text = items.join(', ');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: widget.icon,
          imageAsset: widget.imageAsset,
          title: widget.title,
          subtitle: widget.subtitle,
          accent: widget.accent,
          textColor: widget.textColor,
          subColor: widget.subColor,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: widget.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...items.map(
                (item) => Chip(
                  label: Text(item),
                  labelStyle: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: widget.chipBg,
                  deleteIconColor: widget.textColor.withValues(alpha: 0.7),
                  onDeleted: () {
                    final next = [...items]..remove(item);
                    _sync(next);
                  },
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  controller: widget.inputController,
                  decoration: InputDecoration(
                    hintText:
                        isVi ? 'Nhập và nhấn Enter' : 'Type and press Enter',
                    hintStyle: TextStyle(color: widget.subColor),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: widget.textColor),
                  onSubmitted: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty || items.contains(trimmed)) return;
                    _sync([...items, trimmed]);
                    widget.inputController.clear();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetChip extends StatelessWidget {
  const _BudgetChip({
    required this.active,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color:
              isDark
                  ? Colors.white
                  : (active
                      ? const Color(0xFF9A3412)
                      : const Color(0xFF374151)),
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: active,
      backgroundColor: isDark ? const Color(0xFF202936) : Colors.white,
      selectedColor: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFE8D5),
      side: BorderSide(
        color:
            active
                ? const Color(0xFFF97316)
                : (isDark ? const Color(0xFF465365) : const Color(0xFFE5E7EB)),
      ),
      checkmarkColor: isDark ? Colors.white : const Color(0xFFF97316),
      onSelected: (_) => onTap(),
    );
  }
}
