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
    final height = MediaQuery.of(context).size.height * 0.7;
    final insets = MediaQuery.of(context).viewInsets;
    final theme = Theme.of(context);

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
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.surveyTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
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
                        Autocomplete<String>(
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
                            _controller.provinceController.text = selection;
                          },
                          fieldViewBuilder:
                              (context, textController, focusNode, onFieldSubmitted) {
                            if (textController.text.isEmpty &&
                                _controller.provinceController.text.isNotEmpty) {
                              textController.text = _controller.provinceController.text;
                            }
                            return TextFormField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: t.surveyProvinceLabel,
                                border: const OutlineInputBorder(),
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
                        const SizedBox(height: 16),
                        Text('${t.surveySpicyLevel}: ${_controller.spicyLevel}'),
                        Slider(
                          value: _controller.spicyLevel.toDouble(),
                          min: 0,
                          max: 5,
                          divisions: 5,
                          label: _controller.spicyLevel.toString(),
                          onChanged: _controller.setSpicyLevel,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _controller.favoritesController,
                          decoration: InputDecoration(
                            labelText: t.surveyFavoritesLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _controller.dislikesController,
                          decoration: InputDecoration(
                            labelText: t.surveyDislikesLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _controller.isLoading ? null : _submit,
                            child: _controller.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(t.save),
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
