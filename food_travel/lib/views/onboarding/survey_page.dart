import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../controller/onboarding/survey_controller.dart';
import '../../router/route_names.dart';
import '../../services/user_service.dart';
import 'widgets/survey_form_content.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SurveyFormContent(
          controller: _controller,
          onSubmit: _submit,
          loadingProfile: _loadingProfile,
          onClose: () => Navigator.pop(context),
        );
      },
    );
  }
}
