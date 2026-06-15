import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../controller/onboarding/survey_controller.dart';
import '../../data/provinces.dart';
import '../../router/route_names.dart';
import '../../services/user_service.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _formKey = GlobalKey<FormState>();
  late final SurveyController _controller;
  final UserService _userService = UserService();
  bool _loadingProfile = true;

  final TextEditingController _favoriteInput = TextEditingController();
  final TextEditingController _dislikeInput = TextEditingController();
  List<String> _favoriteItems = [];
  List<String> _dislikeItems = [];

  @override
  void initState() {
    super.initState();
    _controller = SurveyController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
      return;
    }

    final profile = await _userService.getUserById(user.uid);
    final prefs = profile?.preferences;
    if (prefs != null) {
      _controller.provinceController.text = prefs.provinceName ?? '';
      _controller.favoritesController.text = prefs.favoriteTags.join(', ');
      _controller.dislikesController.text =
          prefs.dislikedIngredients.join(', ');
      _controller.setSpicyLevel(prefs.spicyLevel.toDouble());
      _syncChipsFromControllers();
    }

    if (!mounted) return;
    setState(() => _loadingProfile = false);
  }

  @override
  void dispose() {
    _favoriteInput.dispose();
    _dislikeInput.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncChipsFromControllers() {
    _favoriteItems = _splitList(_controller.favoritesController.text);
    _dislikeItems = _splitList(_controller.dislikesController.text);
  }

  List<String> _splitList(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _updateFavoritesController() {
    _controller.favoritesController.text = _favoriteItems.join(', ');
  }

  void _updateDislikesController() {
    _controller.dislikesController.text = _dislikeItems.join(', ');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _controller.submit();
    if (!mounted) return;

    if (ok) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.home,
          (route) => false,
        );
      }
    } else {
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.surveySaveFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E131A) : const Color(0xFFFFFAF3);
    final surface = isDark ? const Color(0xFF171E28) : Colors.white;
    final border = isDark ? const Color(0xFF283142) : const Color(0xFFF1E6D8);
    final text = isDark ? Colors.white : const Color(0xFF1F2937);
    final sub = isDark ? const Color(0xFFAAB4C3) : const Color(0xFF6B7280);
    final accent = const Color(0xFFF97316);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: _SurveyHero(
                        title: isVi
                            ? 'Phi\u1ebfu kh\u1ea3o s\u00e1t \u1ea9m th\u1ef1c'
                            : 'Food Preference Survey',
                        subtitle: isVi
                            ? 'C\u1eadp nh\u1eadt s\u1edf th\u00edch \u0103n u\u1ed1ng \u0111\u1ec3 h\u1ec7 th\u1ed1ng g\u1ee3i \u00fd m\u00f3n \u0103n, qu\u00e1n g\u1ea7n b\u1ea1n v\u00e0 h\u00e0nh tr\u00ecnh ph\u00f9 h\u1ee3p h\u01a1n.'
                            : 'Update your taste profile so the app can recommend dishes, places, and journeys more accurately.',
                        loadingProfile: _loadingProfile,
                        textColor: text,
                        subColor: sub,
                        accent: accent,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _SectionCard(
                          surface: surface,
                          border: border,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                icon: Icons.location_city_rounded,
                                title: t.surveyProvinceLabel,
                                subtitle: isVi
                                    ? 'Ch\u1ecdn khu v\u1ef1c c\u1ee7a b\u1ea1n \u0111\u1ec3 g\u1ee3i \u00fd m\u00f3n \u0103n v\u00e0 qu\u00e1n ph\u00f9 h\u1ee3p h\u01a1n.'
                                    : 'Select your area so we can personalize nearby food suggestions.',
                                accent: accent,
                                textColor: text,
                                subColor: sub,
                              ),
                              const SizedBox(height: 16),
                              _ProvinceAutocompleteField(
                                controller: _controller.provinceController,
                                label: t.surveyProvinceLabel,
                                requiredText: t.surveyProvinceRequired,
                                textColor: text,
                                border: border,
                                surface: isDark
                                    ? const Color(0xFF121821)
                                    : const Color(0xFFFFFCF8),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          surface: surface,
                          border: border,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                icon: Icons.local_fire_department_rounded,
                                title: t.surveySpicyLevel,
                                subtitle: isVi
                                    ? '\u0110\u1ed9 cay gi\u00fap h\u1ec7 th\u1ed1ng tr\u00e1nh g\u1ee3i \u00fd m\u00f3n qu\u00e1 m\u1ea1nh ho\u1eb7c qu\u00e1 nh\u1ea1t.'
                                    : 'Your spice tolerance helps tailor more accurate dish recommendations.',
                                accent: accent,
                                textColor: text,
                                subColor: sub,
                              ),
                              const SizedBox(height: 18),
                              _SpicyMeter(
                                level: _controller.spicyLevel,
                                accent: accent,
                                textColor: text,
                                subColor: sub,
                              ),
                              const SizedBox(height: 16),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 8,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12,
                                  ),
                                  activeTrackColor: accent,
                                  inactiveTrackColor: border,
                                  thumbColor: Colors.white,
                                  overlayColor:
                                      accent.withValues(alpha: 0.12),
                                ),
                                child: Slider(
                                  min: 0,
                                  max: 5,
                                  divisions: 5,
                                  value: _controller.spicyLevel.toDouble(),
                                  onChanged: _controller.setSpicyLevel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          surface: surface,
                          border: border,
                          child: _ChipEditorSection(
                            icon: Icons.favorite_rounded,
                            title: t.surveyFavoritesLabel,
                            subtitle: isVi
                                ? 'Th\u00eam c\u00e1c m\u00f3n b\u1ea1n th\u00edch \u0111\u1ec3 \u01b0u ti\u00ean khi \u0111\u1ec1 xu\u1ea5t.'
                                : 'Add dishes you love so we can prioritize them in suggestions.',
                            inputController: _favoriteInput,
                            items: _favoriteItems,
                            accent: accent,
                            textColor: text,
                            subColor: sub,
                            chipBg: isDark
                                ? const Color(0xFF2A3342)
                                : const Color(0xFFFFEDD5),
                            border: border,
                            hint: isVi
                                ? 'V\u00ed d\u1ee5: b\u00fan b\u00f2, c\u01a1m t\u1ea5m, b\u00e1nh m\u00ec'
                                : 'Example: pho, bun bo, banh mi',
                            onAdd: (value) {
                              setState(() {
                                _favoriteItems.add(value);
                                _updateFavoritesController();
                              });
                            },
                            onRemove: (value) {
                              setState(() {
                                _favoriteItems.remove(value);
                                _updateFavoritesController();
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          surface: surface,
                          border: border,
                          child: _ChipEditorSection(
                            icon: Icons.do_not_disturb_on_rounded,
                            title: t.surveyDislikesLabel,
                            subtitle: isVi
                                ? 'Ghi l\u1ea1i nguy\u00ean li\u1ec7u b\u1ea1n kh\u00f4ng h\u1ee3p \u0111\u1ec3 tr\u00e1nh g\u1ee3i \u00fd sai.'
                                : 'List ingredients you dislike so recommendations stay relevant.',
                            inputController: _dislikeInput,
                            items: _dislikeItems,
                            accent: const Color(0xFF64748B),
                            textColor: text,
                            subColor: sub,
                            chipBg: isDark
                                ? const Color(0xFF26303C)
                                : const Color(0xFFF3F4F6),
                            border: border,
                            hint: isVi
                                ? 'V\u00ed d\u1ee5: rau m\u00f9i, n\u1ed9i t\u1ea1ng, \u0111\u1eadu ph\u1ed9ng'
                                : 'Example: coriander, peanuts, organ meat',
                            onAdd: (value) {
                              setState(() {
                                _dislikeItems.add(value);
                                _updateDislikesController();
                              });
                            },
                            onRemove: (value) {
                              setState(() {
                                _dislikeItems.remove(value);
                                _updateDislikesController();
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 58,
                          child: FilledButton(
                            onPressed: _controller.isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _controller.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    isVi
                                        ? 'L\u01b0u phi\u1ebfu kh\u1ea3o s\u00e1t'
                                        : 'Save preferences',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SurveyHero extends StatelessWidget {
  const _SurveyHero({
    required this.title,
    required this.subtitle,
    required this.loadingProfile,
    required this.textColor,
    required this.subColor,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final bool loadingProfile;
  final Color textColor;
  final Color subColor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Material(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
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
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF0DD), Color(0xFFFFE0BD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  size: 28,
                  color: Color(0xFFF97316),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: subColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.textColor,
    required this.subColor,
  });

  final IconData icon;
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
          child: Icon(icon, color: accent),
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
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: subColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProvinceAutocompleteField extends StatelessWidget {
  const _ProvinceAutocompleteField({
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
          (province) => province.toLowerCase().startsWith(query),
        );
      },
      onSelected: (selection) {
        controller.text = selection;
      },
      fieldViewBuilder:
          (context, textController, focusNode, onFieldSubmitted) {
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

class _SpicyMeter extends StatelessWidget {
  const _SpicyMeter({
    required this.level,
    required this.accent,
    required this.textColor,
    required this.subColor,
  });

  final int level;
  final Color accent;
  final Color textColor;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Nh\u1eb9',
      'H\u01a1i cay',
      'C\u00e2n b\u1eb1ng',
      'Kh\u00e1 cay',
      'R\u1ea5t cay',
      'C\u1ef1c cay',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (int index = 0; index < 6; index++) ...[
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: index <= level
                      ? accent
                      : accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            if (index < 5) const SizedBox(width: 6),
          ],
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$level/5',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              Text(
                labels[level.clamp(0, 5)],
                style: TextStyle(
                  fontSize: 12,
                  color: subColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipEditorSection extends StatelessWidget {
  const _ChipEditorSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.inputController,
    required this.items,
    required this.accent,
    required this.textColor,
    required this.subColor,
    required this.chipBg,
    required this.border,
    required this.hint,
    required this.onAdd,
    required this.onRemove,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final TextEditingController inputController;
  final List<String> items;
  final Color accent;
  final Color textColor;
  final Color subColor;
  final Color chipBg;
  final Color border;
  final String hint;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: icon,
          title: title,
          subtitle: subtitle,
          accent: accent,
          textColor: textColor,
          subColor: subColor,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: border),
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
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: chipBg,
                  deleteIconColor: textColor.withValues(alpha: 0.7),
                  onDeleted: () => onRemove(item),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  controller: inputController,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: subColor),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: textColor),
                  onSubmitted: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty) return;
                    onAdd(trimmed);
                    inputController.clear();
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
