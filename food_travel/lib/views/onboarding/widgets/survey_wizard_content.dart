import 'package:flutter/material.dart';
import 'package:food_travel/data/provinces.dart';

import '../../../controller/onboarding/survey_controller.dart';

class SurveyWizardContent extends StatefulWidget {
  const SurveyWizardContent({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.onClose,
    this.loadingProfile = false,
  });

  final SurveyController controller;
  final Future<void> Function() onSubmit;
  final VoidCallback onClose;
  final bool loadingProfile;

  @override
  State<SurveyWizardContent> createState() => _SurveyWizardContentState();
}

class _SurveyWizardContentState extends State<SurveyWizardContent> {
  static const _orange = Color(0xFFF97316);
  final PageController _pages = PageController();
  int _step = 0;

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _back() {
    if (_step == 0) {
      widget.onClose();
      return;
    }
    _goTo(_step - 1);
  }

  void _goTo(int value) {
    setState(() => _step = value);
    _pages.animateToPage(
      value,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _next() async {
    if (_step == 0 &&
        widget.controller.provinceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isVi
                ? 'Vui lòng nhập tỉnh/thành phố của bạn.'
                : 'Please enter your province or city.',
          ),
        ),
      );
      return;
    }
    if (_step < 5) {
      _goTo(_step + 1);
    } else {
      await widget.onSubmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF0E131A) : const Color(0xFFFFFBF5);
    final foreground = dark ? Colors.white : const Color(0xFF2D1B12);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Text(
                      _isVi ? 'Khảo sát sở thích' : 'Preference survey',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: foreground,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _isVi ? 'Để sau' : 'Do later',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            _StepIndicator(current: _step),
            const SizedBox(height: 12),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomeStep(controller: widget.controller, isVi: _isVi),
                  _TasteStep(controller: widget.controller, isVi: _isVi),
                  _DishTypeStep(controller: widget.controller, isVi: _isVi),
                  _IngredientsStep(controller: widget.controller, isVi: _isVi),
                  _RegionStep(controller: widget.controller, isVi: _isVi),
                  _FinalStep(controller: widget.controller, isVi: _isVi),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed:
                      widget.loadingProfile || widget.controller.isLoading
                          ? null
                          : _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      widget.loadingProfile || widget.controller.isLoading
                          ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            _step == 0
                                ? (_isVi ? 'Bắt đầu khảo sát' : 'Start survey')
                                : _step == 5
                                ? (_isVi ? 'Hoàn tất' : 'Finish')
                                : (_isVi ? 'Tiếp tục' : 'Continue'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: Row(
        children: List.generate(6, (index) {
          final active = index <= current;
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color:
                          active
                              ? _SurveyWizardContentState._orange
                              : const Color(0xFFE4D8C9),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: index == current ? 28 : 23,
                  height: index == current ? 28 : 23,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        active
                            ? _SurveyWizardContentState._orange
                            : Colors.transparent,
                    border: Border.all(
                      color:
                          active
                              ? _SurveyWizardContentState._orange
                              : const Color(0xFFD6C6B5),
                    ),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xFF9A8979),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
    children: children,
  );
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.controller, required this.isVi});
  final SurveyController controller;
  final bool isVi;
  @override
  Widget build(BuildContext context) => _PageBody(
    children: [
      Center(
        child: Image.asset(
          'assets/survey/generated/province.png',
          height: 210,
          fit: BoxFit.contain,
        ),
      ),
      Text(
        isVi ? 'Chào mừng bạn đến với FOODS!' : 'Welcome to FOODS!',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 10),
      Text(
        isVi
            ? 'Hãy dành vài phút để chúng tôi hiểu khẩu vị và gợi ý món ăn phù hợp nhất cho bạn.'
            : 'Tell us about your taste so we can suggest food that suits you best.',
        textAlign: TextAlign.center,
        style: const TextStyle(height: 1.5, color: Color(0xFF75675F)),
      ),
      const SizedBox(height: 28),
      _Title(
        isVi
            ? 'Bạn đang ở tỉnh/thành phố nào?'
            : 'Which province/city are you in?',
      ),
      const SizedBox(height: 10),
      Autocomplete<String>(
        initialValue: TextEditingValue(
          text: controller.provinceController.text,
        ),
        optionsBuilder: (value) {
          final query = value.text.trim().toLowerCase();
          if (query.isEmpty) return vietnamProvinces;
          return vietnamProvinces.where(
            (province) => province.toLowerCase().contains(query),
          );
        },
        onSelected: (province) => controller.provinceController.text = province,
        fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
          return TextField(
            controller: fieldController,
            focusNode: focusNode,
            textInputAction: TextInputAction.done,
            onChanged: (value) => controller.provinceController.text = value,
            onSubmitted: (_) => onSubmitted(),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFF97316),
              ),
              suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
              hintText: isVi ? 'Chọn tỉnh/thành phố' : 'Select province/city',
              filled: true,
              fillColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF171E28)
                      : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8D9C8)),
              ),
            ),
          );
        },
      ),
    ],
  );
}

class _TasteStep extends StatelessWidget {
  const _TasteStep({required this.controller, required this.isVi});
  final SurveyController controller;
  final bool isVi;
  @override
  Widget build(BuildContext context) => _PageBody(
    children: [
      _SectionLead(
        asset: 'assets/survey/generated/spice.png',
        title:
            isVi
                ? '1. Bạn thích món ăn cay như thế nào?'
                : '1. How spicy do you like your food?',
      ),
      const SizedBox(height: 14),
      _SingleChoiceGrid(
        values: List.generate(6, (i) => '$i'),
        labels:
            isVi
                ? const [
                  'Không cay',
                  'Rất ít',
                  'Ít cay',
                  'Vừa cay',
                  'Cay',
                  'Rất cay',
                ]
                : const [
                  'None',
                  'Very mild',
                  'Mild',
                  'Medium',
                  'Spicy',
                  'Very spicy',
                ],
        selected: '${controller.spicyLevel}',
        icon: Icons.local_fire_department_rounded,
        onTap: (v) => controller.setSpicyLevel(double.parse(v)),
      ),
      const SizedBox(height: 28),
      _SectionLead(
        asset: 'assets/survey/generated/satiety.png',
        title:
            isVi
                ? '2. Bạn thích mức độ no của món ăn?'
                : '2. How filling should your meal be?',
      ),
      const SizedBox(height: 14),
      _SingleChoiceGrid(
        values: const ['0', '3', '5'],
        labels:
            isVi
                ? const ['Nhẹ nhàng', 'Đủ no', 'Rất no']
                : const ['Light', 'Filling', 'Very filling'],
        selected: '${controller.satietyPreference}',
        icon: Icons.rice_bowl_rounded,
        onTap: (v) => controller.setSatietyPreference(int.parse(v)),
      ),
    ],
  );
}

class _DishTypeStep extends StatelessWidget {
  const _DishTypeStep({required this.controller, required this.isVi});
  final SurveyController controller;
  final bool isVi;
  @override
  Widget build(BuildContext context) => _PageBody(
    children: [
      _SectionLead(
        asset: 'assets/survey/generated/dish_type.png',
        title:
            isVi
                ? '3. Bạn yêu thích kiểu món ăn nào?'
                : '3. What types of food do you enjoy?',
      ),
      const SizedBox(height: 5),
      Text(
        isVi ? 'Có thể chọn nhiều lựa chọn' : 'Choose one or more options',
        style: const TextStyle(color: Color(0xFF75675F)),
      ),
      const SizedBox(height: 16),
      _MultiChoiceGrid(
        selected: controller.preferredDishTypes,
        onTap:
            (v) => controller.toggleSetValue(controller.preferredDishTypes, v),
        options: [
          (
            'mon_chinh',
            isVi ? 'Cơm / Món chính' : 'Rice / Main',
            Icons.rice_bowl_rounded,
          ),
          (
            'mon_nuoc',
            isVi ? 'Phở / Bún' : 'Soup / Noodles',
            Icons.ramen_dining_rounded,
          ),
          (
            'mon_kho',
            isVi ? 'Mì / Miến' : 'Dry noodles',
            Icons.dinner_dining_rounded,
          ),
          ('lau', isVi ? 'Lẩu' : 'Hotpot', Icons.soup_kitchen_rounded),
          ('nuong', isVi ? 'Nướng' : 'Grilled', Icons.outdoor_grill_rounded),
          ('hai_san', isVi ? 'Hải sản' : 'Seafood', Icons.set_meal_rounded),
          ('vegetarian', isVi ? 'Đồ chay' : 'Vegetarian', Icons.eco_rounded),
          (
            'an_vat',
            isVi ? 'Bánh / Ăn vặt' : 'Pastry / Snack',
            Icons.cake_rounded,
          ),
          ('khac', isVi ? 'Khác' : 'Other', Icons.more_horiz_rounded),
        ],
      ),
    ],
  );
}

class _IngredientsStep extends StatelessWidget {
  const _IngredientsStep({required this.controller, required this.isVi});
  final SurveyController controller;
  final bool isVi;
  @override
  Widget build(BuildContext context) => _PageBody(
    children: [
      _SectionLead(
        asset: 'assets/survey/generated/disliked_ingredient.png',
        title:
            isVi
                ? '4. Nguyên liệu bạn không thích'
                : '4. Ingredients you dislike',
      ),
      const SizedBox(height: 12),
      _TextTagField(
        controller: controller.dislikesController,
        hint:
            isVi
                ? 'Ví dụ: hành, rau mùi, mắm tôm...'
                : 'Example: onion, coriander...',
      ),
      const SizedBox(height: 28),
      _SectionLead(
        asset: 'assets/survey/generated/allergy.png',
        title:
            isVi
                ? '5. Bạn có dị ứng nguyên liệu nào không?'
                : '5. Do you have any food allergies?',
      ),
      const SizedBox(height: 12),
      _TextTagField(
        controller: controller.allergiesController,
        hint:
            isVi
                ? 'Ví dụ: hải sản, đậu phộng, sữa...'
                : 'Example: seafood, peanuts, milk...',
      ),
      const SizedBox(height: 12),
      Text(
        isVi
            ? 'Ngăn cách nhiều nguyên liệu bằng dấu phẩy.'
            : 'Separate multiple ingredients with commas.',
        style: const TextStyle(color: Color(0xFF75675F), fontSize: 12),
      ),
    ],
  );
}

class _RegionStep extends StatelessWidget {
  const _RegionStep({required this.controller, required this.isVi});
  final SurveyController controller;
  final bool isVi;
  @override
  Widget build(BuildContext context) => _PageBody(
    children: [
      _SectionLead(
        asset: 'assets/survey/generated/preferred_region.png',
        title:
            isVi
                ? '6. Vùng ẩm thực bạn yêu thích'
                : '6. Your favorite culinary regions',
      ),
      const SizedBox(height: 12),
      _ChipGroup(
        selected: controller.preferredRegions,
        onTap: (v) => controller.toggleSetValue(controller.preferredRegions, v),
        items: {
          'mien_bac': isVi ? 'Miền Bắc' : 'North',
          'mien_trung': isVi ? 'Miền Trung' : 'Central',
          'mien_nam': isVi ? 'Miền Nam' : 'South',
        },
      ),
      const SizedBox(height: 26),
      _SectionLead(
        asset: 'assets/survey/generated/seasonal.png',
        title: isVi ? '7. Gợi ý món ăn theo mùa' : '7. Seasonal suggestions',
      ),
      const SizedBox(height: 8),
      SwitchListTile.adaptive(
        value: controller.followSeasonalSuggestions,
        activeThumbColor: const Color(0xFFF97316),
        contentPadding: EdgeInsets.zero,
        title: Text(
          isVi
              ? 'Ưu tiên món phù hợp theo mùa'
              : 'Prefer food suitable for the season',
        ),
        onChanged: controller.setFollowSeasonalSuggestions,
      ),
      if (controller.followSeasonalSuggestions)
        _ChipGroup(
          selected: controller.preferredSeasons,
          onTap:
              (v) => controller.toggleSetValue(controller.preferredSeasons, v),
          items: {
            'spring': isVi ? 'Mùa xuân' : 'Spring',
            'summer': isVi ? 'Mùa hè' : 'Summer',
            'autumn': isVi ? 'Mùa thu' : 'Autumn',
            'winter': isVi ? 'Mùa đông' : 'Winter',
            'all_season': isVi ? 'Quanh năm' : 'All year',
          },
        ),
    ],
  );
}

class _FinalStep extends StatelessWidget {
  const _FinalStep({required this.controller, required this.isVi});
  final SurveyController controller;
  final bool isVi;
  @override
  Widget build(BuildContext context) => _PageBody(
    children: [
      _SectionLead(
        asset: 'assets/survey/generated/favorite_keyword.png',
        title:
            isVi ? '8. Từ khóa món ăn yêu thích' : '8. Favorite food keywords',
      ),
      const SizedBox(height: 12),
      _TextTagField(
        controller: controller.favoritesController,
        hint:
            isVi
                ? 'Ví dụ: phở, món nóng, ít dầu...'
                : 'Example: pho, hot food, low oil...',
      ),
      const SizedBox(height: 24),
      _Title(
        isVi
            ? 'Bạn muốn nhận gợi ý như thế nào?'
            : 'What recommendations do you prefer?',
      ),
      const SizedBox(height: 12),
      _ChipGroup(
        selected: controller.recommendationGoals,
        onTap:
            (v) => controller.toggleSetValue(controller.recommendationGoals, v),
        items: {
          'discover_new': isVi ? 'Khám phá món mới' : 'Discover new food',
          'healthy': isVi ? 'Tốt cho sức khỏe' : 'Healthy food',
          'hidden_local': isVi ? 'Món địa phương' : 'Local food',
          'quick': isVi ? 'Nhanh và tiện lợi' : 'Quick & convenient',
        },
      ),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE7C7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/survey/generated/seasonal.png',
              width: 78,
              height: 78,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVi ? 'Cảm ơn bạn!' : 'Thank you!',
                    style: const TextStyle(
                      color: Color(0xFF3B2416),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isVi
                        ? 'Thông tin sẽ được dùng để cá nhân hóa gợi ý món ăn mỗi ngày.'
                        : 'We will use this information to personalize your daily suggestions.',
                    style: const TextStyle(
                      color: Color(0xFF6B4A35),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SectionLead extends StatelessWidget {
  const _SectionLead({required this.asset, required this.title});
  final String asset;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Image.asset(asset, width: 42, height: 42, fit: BoxFit.contain),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
  );
}

class _TextTagField extends StatelessWidget {
  const _TextTagField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    minLines: 2,
    maxLines: 4,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class _SingleChoiceGrid extends StatelessWidget {
  const _SingleChoiceGrid({
    required this.values,
    required this.labels,
    required this.selected,
    required this.icon,
    required this.onTap,
  });
  final List<String> values;
  final List<String> labels;
  final String selected;
  final IconData icon;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: List.generate(values.length, (i) {
      final active = values[i] == selected;
      return InkWell(
        onTap: () => onTap(values[i]),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color:
                active ? const Color(0xFFFFE7C7) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? const Color(0xFFF97316) : const Color(0xFFE5D8C8),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    active ? const Color(0xFFF97316) : const Color(0xFF9A8979),
              ),
              const SizedBox(height: 7),
              Text(
                labels[i],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }),
  );
}

class _MultiChoiceGrid extends StatelessWidget {
  const _MultiChoiceGrid({
    required this.options,
    required this.selected,
    required this.onTap,
  });
  final List<(String, String, IconData)> options;
  final Set<String> selected;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: options.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: .9,
    ),
    itemBuilder: (context, index) {
      final option = options[index];
      final active = selected.contains(option.$1);
      return InkWell(
        onTap: () => onTap(option.$1),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color:
                active ? const Color(0xFFFFE7C7) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: active ? const Color(0xFFF97316) : const Color(0xFFE5D8C8),
              width: active ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(option.$3, size: 34, color: const Color(0xFFF97316)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        option.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (active)
                const Positioned(
                  right: 6,
                  bottom: 6,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: Color(0xFFF97316),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.items,
    required this.selected,
    required this.onTap,
  });
  final Map<String, String> items;
  final Set<String> selected;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children:
        items.entries.map((entry) {
          final active = selected.contains(entry.key);
          return FilterChip(
            label: Text(entry.value),
            selected: active,
            onSelected: (_) => onTap(entry.key),
            selectedColor: const Color(0xFFFFE0B8),
            checkmarkColor: const Color(0xFFF97316),
            side: BorderSide(
              color: active ? const Color(0xFFF97316) : const Color(0xFFE5D8C8),
            ),
          );
        }).toList(),
  );
}
