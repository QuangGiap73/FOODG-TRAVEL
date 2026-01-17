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
    }

    if (!mounted) return;
    setState(() => _loadingProfile = false);
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(t.surveyTitle)),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_loadingProfile)
                    const LinearProgressIndicator(minHeight: 2),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(t.save),
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
