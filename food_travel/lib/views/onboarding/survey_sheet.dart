import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../controller/onboarding/survey_controller.dart';
import '../../services/user_service.dart';
import 'widgets/survey_form_content.dart';

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
      _controller.loadFromPreferences(prefs);
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
                              isVi ? 'Khảo sát khẩu vị' : t.surveyTitle,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isVi
                                  ? 'Điền nhanh để cá nhân hóa gợi ý món ăn.'
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
                  child: SurveyFormContent(
                    controller: _controller,
                    onSubmit: _submit,
                    compact: true,
                    loadingProfile: _loadingProfile,
                    onClose: () => Navigator.pop(context),
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
