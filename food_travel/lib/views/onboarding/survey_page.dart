import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      _controller.dislikesController.text = prefs.dislikedIngredients.join(', ');
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
    final bg = isDark ? const Color(0xFF0F131A) : const Color(0xFFFFFCF8);
    final cardBg = isDark ? const Color(0xFF171C26) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF242B3A) : Colors.grey.shade200;
    final hintColor = isDark ? const Color(0xFF8A93A3) : Colors.grey.shade600;
    final labelColor = isDark ? const Color(0xFF8A93A3) : Colors.grey.shade500;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final orange = const Color(0xFFFF6D00);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  if (_loadingProfile)
                    const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 10),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cardBg,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.surveyTitle,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isVi
                        ? 'Hay cho chung toi biet mon an ban thich de goi y tot hon.'
                        : 'Tell us what you love to eat so we can recommend the best local spots.',
                    style: TextStyle(color: hintColor),
                  ),
                  const SizedBox(height: 28),
                  _label(t.surveyProvinceLabel, labelColor),
                  const SizedBox(height: 10),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue value) {
                      final query = value.text.trim().toLowerCase();
                      if (query.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return vietnamProvinces.where(
                        (province) {
                          final name = province.toLowerCase();
                          return name.startsWith(query);
                        },
                      );
                    },
                    onSelected: (selection) {
                      _controller.provinceController.text = selection;
                    },
                    fieldViewBuilder:
                        (context, textController, focusNode, onFieldSubmitted) {
                      if (textController.text.isEmpty &&
                          _controller.provinceController.text.isNotEmpty) {
                        textController.text =
                            _controller.provinceController.text;
                      }
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDecoration(
                          cardBg,
                          cardBorder,
                          isDark,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isDark
                                  ? const Color(0xFF2A2F3B)
                                  : const Color(0xFFFFF3E0),
                              child: Icon(Icons.location_on, color: orange),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: textController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: t.surveyProvinceLabel,
                                  hintStyle: TextStyle(color: hintColor),
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(color: textColor),
                                onChanged: (value) {
                                  _controller.provinceController.text = value;
                                },
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return t.surveyProvinceRequired;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down, color: hintColor),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label(t.surveySpicyLevel, labelColor),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2F3B)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Level ${_controller.spicyLevel}/5',
                          style: TextStyle(
                            color: orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(
                      cardBg,
                      cardBorder,
                      isDark,
                    ),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 14,
                            ),
                            activeTrackColor: orange,
                            inactiveTrackColor: isDark
                                ? const Color(0xFF2A2F3B)
                                : Colors.grey.shade200,
                            thumbColor: Colors.white,
                            overlayColor: orange.withOpacity(0.1),
                          ),
                          child: Slider(
                            min: 0,
                            max: 5,
                            divisions: 5,
                            value: _controller.spicyLevel.toDouble(),
                            onChanged: _controller.setSpicyLevel,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mild',
                              style: TextStyle(
                                color: hintColor,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Volcanic',
                              style: TextStyle(
                                color: hintColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _label(t.surveyFavoritesLabel, labelColor),
                  const SizedBox(height: 10),
                  _chipInput(
                    controller: _favoriteInput,
                    items: _favoriteItems,
                    chipColor: isDark
                        ? const Color(0xFF2A2F3B)
                        : const Color(0xFFFFF3E0),
                    textColor: textColor,
                    hintColor: hintColor,
                    onAdd: (v) {
                      setState(() {
                        _favoriteItems.add(v);
                        _updateFavoritesController();
                      });
                    },
                    onRemove: (v) {
                      setState(() {
                        _favoriteItems.remove(v);
                        _updateFavoritesController();
                      });
                    },
                    hint: isVi ? 'Nhap mon an...' : 'Type & comma...',
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 28),
                  _label(t.surveyDislikesLabel, labelColor),
                  const SizedBox(height: 10),
                  _chipInput(
                    controller: _dislikeInput,
                    items: _dislikeItems,
                    chipColor:
                        isDark ? const Color(0xFF2A2F3B) : Colors.grey.shade200,
                    textColor: textColor,
                    hintColor: hintColor,
                    onAdd: (v) {
                      setState(() {
                        _dislikeItems.add(v);
                        _updateDislikesController();
                      });
                    },
                    onRemove: (v) {
                      setState(() {
                        _dislikeItems.remove(v);
                        _updateDislikesController();
                      });
                    },
                    hint: isVi ? 'Nhap nguyen lieu...' : 'Add ingredients...',
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 36),
                  GestureDetector(
                    onTap: _controller.isLoading ? null : _submit,
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8A50), Color(0xFFFF6D00)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: orange.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Center(
                        child: _controller.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                isVi ? 'Luu tuy chon' : 'Save Preferences',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _label(String text, Color labelColor) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: labelColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      );

  BoxDecoration _cardDecoration(Color cardBg, Color cardBorder, bool isDark) =>
      BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
          )
        ],
      );

  Widget _chipInput({
    required TextEditingController controller,
    required List<String> items,
    required Color chipColor,
    required Color textColor,
    required Color hintColor,
    required Function(String) onAdd,
    required Function(String) onRemove,
    required String hint,
    required Color cardBg,
    required Color cardBorder,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(cardBg, cardBorder, isDark),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...items.map(
            (e) => Chip(
              label: Text(e),
              backgroundColor: chipColor,
              labelStyle: TextStyle(color: textColor),
              onDeleted: () => onRemove(e),
            ),
          ),
          SizedBox(
            width: 140,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: hintColor),
                border: InputBorder.none,
              ),
              style: TextStyle(color: textColor),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  onAdd(v.trim());
                  controller.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
