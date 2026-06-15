import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../controller/onboarding/survey_controller.dart';
import '../../data/provinces.dart';

bool _isSurveySheetVisible = false;

Future<void> showSurveySheet(BuildContext context) async {
  if (_isSurveySheetVisible) return;
  _isSurveySheetVisible = true;
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SurveySheet(),
    );
  } finally {
    _isSurveySheetVisible = false;
  }
}

class _SurveySheet extends StatefulWidget {
  const _SurveySheet();

  @override
  State<_SurveySheet> createState() => _SurveySheetState();
}

class _SurveySheetState extends State<_SurveySheet> {
  final _formKey = GlobalKey<FormState>();
  late final SurveyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SurveyController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _controller.submit();
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
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
    final height = MediaQuery.of(context).size.height * 0.78;
    final insets = MediaQuery.of(context).viewInsets;
    final theme = Theme.of(context);
    final accent = const Color(0xFFF97316);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVi
                                  ? 'Phi\u1ebfu kh\u1ea3o s\u00e1t \u1ea9m th\u1ef1c'
                                  : t.surveyTitle,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isVi
                                  ? '\u0110i\u1ec1n nhanh \u0111\u1ec3 c\u00e1 nh\u00e2n h\u00f3a g\u1ee3i \u00fd m\u00f3n \u0103n.'
                                  : 'Complete this to personalize food suggestions.',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _SheetSection(
                          title: t.surveyProvinceLabel,
                          icon: Icons.location_city_rounded,
                          accent: accent,
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue value) {
                              final query = value.text.trim().toLowerCase();
                              if (query.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              return vietnamProvinces.where(
                                (province) =>
                                    province.toLowerCase().startsWith(query),
                              );
                            },
                            onSelected: (selection) {
                              _controller.provinceController.text = selection;
                            },
                            fieldViewBuilder: (
                              context,
                              textController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              if (textController.text.isEmpty &&
                                  _controller
                                      .provinceController.text.isNotEmpty) {
                                textController.text =
                                    _controller.provinceController.text;
                              }
                              return TextFormField(
                                controller: textController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: t.surveyProvinceLabel,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onChanged: (value) {
                                  _controller.provinceController.text = value;
                                },
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return t.surveyProvinceRequired;
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SheetSection(
                          title: t.surveySpicyLevel,
                          icon: Icons.local_fire_department_rounded,
                          accent: accent,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${_controller.spicyLevel}/5',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    isVi
                                        ? '0 = nh\u1eb9, 5 = r\u1ea5t cay'
                                        : '0 = mild, 5 = spicy',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _controller.spicyLevel.toDouble(),
                                min: 0,
                                max: 5,
                                divisions: 5,
                                activeColor: accent,
                                label: _controller.spicyLevel.toString(),
                                onChanged: _controller.setSpicyLevel,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SheetSection(
                          title: t.surveyFavoritesLabel,
                          icon: Icons.favorite_rounded,
                          accent: accent,
                          child: TextFormField(
                            controller: _controller.favoritesController,
                            decoration: InputDecoration(
                              hintText: isVi
                                  ? 'V\u00ed d\u1ee5: ph\u1edf, b\u00fan ch\u1ea3, c\u01a1m t\u1ea5m'
                                  : 'Example: pho, bun cha, com tam',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SheetSection(
                          title: t.surveyDislikesLabel,
                          icon: Icons.do_not_disturb_on_rounded,
                          accent: const Color(0xFF64748B),
                          child: TextFormField(
                            controller: _controller.dislikesController,
                            decoration: InputDecoration(
                              hintText: isVi
                                  ? 'V\u00ed d\u1ee5: \u0111\u1eadu ph\u1ed9ng, rau m\u00f9i'
                                  : 'Example: peanuts, coriander',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _controller.isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                            ),
                            child: _controller.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
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
                                        : t.save,
                                  ),
                          ),
                        ),
                      ],
                    ),
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

class _SheetSection extends StatelessWidget {
  const _SheetSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
