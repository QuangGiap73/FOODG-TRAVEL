import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../controller/change_password/change_password_controller.dart';

enum _PasswordStrengthLevel { weak, medium, strong, veryStrong }

class _PasswordStrength {
  const _PasswordStrength({
    required this.level,
    required this.label,
    required this.color,
    required this.progress,
  });

  final _PasswordStrengthLevel level;
  final String label;
  final Color color;
  final double progress;
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _controller = ChangePasswordController();
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _currentController.addListener(_onPasswordChanged);
    _newController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _currentController.removeListener(_onPasswordChanged);
    _newController.removeListener(_onPasswordChanged);
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String? _errorMessage(AppLocalizations t) {
    switch (_controller.errorCode) {
      case ChangePasswordController.errorMissingFields:
        return t.changePasswordErrorMissingFields;
      case ChangePasswordController.errorPasswordMismatch:
        return t.changePasswordErrorMismatch;
      case ChangePasswordController.errorPasswordTooShort:
        return t.changePasswordErrorTooShort;
      case ChangePasswordController.errorWrongPassword:
        return t.changePasswordErrorWrongCurrent;
      case ChangePasswordController.errorWeakPassword:
        return t.changePasswordErrorWeak;
      case ChangePasswordController.errorRequiresRecentLogin:
        return t.changePasswordErrorRequiresLogin;
      case ChangePasswordController.errorNoUser:
        return t.changePasswordErrorNoUser;
      case ChangePasswordController.errorNoEmail:
        return t.changePasswordErrorNoEmail;
      case ChangePasswordController.errorNoPasswordProvider:
        return t.changePasswordErrorNoPasswordProvider;
      case ChangePasswordController.errorUnknown:
        return t.changePasswordErrorUnknown;
      default:
        return null;
    }
  }

  Future<void> _submit(AppLocalizations t) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await _controller.submit(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
      confirmPassword: _confirmController.text,
    );
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.changePasswordSuccess)),
      );
      Navigator.pop(context, true);
      return;
    }

    final message = _errorMessage(t);
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _requestPasswordReset(AppLocalizations t) async {
    FocusScope.of(context).unfocus();

    final ok = await _controller.requestPasswordReset();
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.changePasswordResetSuccess)),
      );
      return;
    }

    final message = _errorMessage(t) ?? t.changePasswordResetFailed;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  _PasswordStrength _passwordStrength(AppLocalizations t, String password) {
    if (password.isEmpty) {
      return _PasswordStrength(
        level: _PasswordStrengthLevel.weak,
        label: t.changePasswordStrengthWeak,
        color: const Color(0xFFFF7A00),
        progress: 0,
      );
    }

    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=;/\\[\]~`]').hasMatch(
      password,
    );

    var score = 0;
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (hasLower && hasUpper) score += 1;
    if (hasDigit) score += 1;
    if (hasSpecial) score += 1;

    if (score <= 1) {
      return _PasswordStrength(
        level: _PasswordStrengthLevel.weak,
        label: t.changePasswordStrengthWeak,
        color: const Color(0xFFFF6B2D),
        progress: 0.25,
      );
    }
    if (score == 2) {
      return _PasswordStrength(
        level: _PasswordStrengthLevel.medium,
        label: t.changePasswordStrengthMedium,
        color: const Color(0xFFF5A623),
        progress: 0.5,
      );
    }
    if (score == 3 || score == 4) {
      return _PasswordStrength(
        level: _PasswordStrengthLevel.strong,
        label: t.changePasswordStrengthStrong,
        color: const Color(0xFF28A745),
        progress: 0.75,
      );
    }
    return _PasswordStrength(
      level: _PasswordStrengthLevel.veryStrong,
      label: t.changePasswordStrengthVeryStrong,
      color: const Color(0xFF1E9B46),
      progress: 1,
    );
  }

  bool _meetsReuseRule() {
    final current = _currentController.text.trim();
    final next = _newController.text.trim();
    if (current.isEmpty || next.isEmpty) return false;
    return current != next;
  }

  bool _meetsLengthRule() => _newController.text.trim().length >= 8;

  bool _meetsCaseRule() {
    final value = _newController.text.trim();
    return RegExp(r'[a-z]').hasMatch(value) && RegExp(r'[A-Z]').hasMatch(value);
  }

  bool _meetsDigitRule() => RegExp(r'\d').hasMatch(_newController.text.trim());

  bool _meetsSpecialRule() {
    return RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=;/\\[\]~`]').hasMatch(
      _newController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final strength = _passwordStrength(t, _newController.text.trim());
        final errorMessage =
            _controller.errorCode == null ? null : _errorMessage(t);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F4EE),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
                  child: SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            onPressed: () => Navigator.pop(context),
                            color: const Color(0xFF171717),
                          ),
                        ),
                        Text(
                          t.changePasswordTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _BannerCard(),
                        const SizedBox(height: 16),
                        _SettingsPanel(
                          child: Form(
                            key: _formKey,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.changePasswordCurrentLabel,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF151515),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _PasswordField(
                                  controller: _currentController,
                                  obscureText: _obscureCurrent,
                                  onToggle: () {
                                    setState(() {
                                      _obscureCurrent = !_obscureCurrent;
                                    });
                                  },
                                  label: t.changePasswordCurrentLabel,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return t.changePasswordCurrentRequired;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  t.changePasswordNewLabel,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF151515),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _PasswordField(
                                  controller: _newController,
                                  obscureText: _obscureNew,
                                  onToggle: () {
                                    setState(() {
                                      _obscureNew = !_obscureNew;
                                    });
                                  },
                                  label: t.changePasswordNewLabel,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return t.changePasswordNewRequired;
                                    }
                                    if (value.trim().length < 6) {
                                      return t.changePasswordNewTooShort;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _StrengthSection(
                                  t: t,
                                  strength: strength,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  t.changePasswordConfirmLabel,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF151515),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _PasswordField(
                                  controller: _confirmController,
                                  obscureText: _obscureConfirm,
                                  onToggle: () {
                                    setState(() {
                                      _obscureConfirm = !_obscureConfirm;
                                    });
                                  },
                                  label: t.changePasswordConfirmLabel,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return t.changePasswordConfirmRequired;
                                    }
                                    if (value != _newController.text) {
                                      return t.changePasswordMismatch;
                                    }
                                    return null;
                                  },
                                ),
                                if (errorMessage != null) ...[
                                  const SizedBox(height: 14),
                                  _ErrorCard(message: errorMessage),
                                ],
                                const SizedBox(height: 16),
                                _TipsCard(
                                  t: t,
                                  meetsLength: _meetsLengthRule(),
                                  meetsCase: _meetsCaseRule(),
                                  meetsDigit: _meetsDigitRule(),
                                  meetsSpecial: _meetsSpecialRule(),
                                  meetsReuse: _meetsReuseRule(),
                                ),
                                const SizedBox(height: 14),
                                _ResetRow(
                                  t: t,
                                  onTap: _controller.isLoading
                                      ? null
                                      : () => _requestPasswordReset(t),
                                ),
                                const SizedBox(height: 14),
                                _InfoCard(t: t),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _controller.isLoading
                              ? null
                              : () => Navigator.maybePop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF7A00),
                            side: const BorderSide(color: Color(0xFFFF7A00)),
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(t.changePasswordCancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GradientActionButton(
                          label: t.changePasswordUpdate,
                          isLoading: _controller.isLoading,
                          onPressed: () => _submit(t),
                        ),
                      ),
                    ],
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

class _BannerCard extends StatelessWidget {
  const _BannerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Image.asset(
          'assets/setting/foods_change_password_banner.png',
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(height: 220),
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscureText,
    required this.onToggle,
    required this.label,
    required this.validator,
  });

  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggle;
  final String label;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF151515)),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(
          color: Color(0xFF8E8E8E),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          size: 20,
          color: Color(0xFF222222),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF222222),
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE7DFD3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE7DFD3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6A0A0)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6A0A0), width: 1.4),
        ),
      ),
    );
  }
}

class _StrengthSection extends StatelessWidget {
  const _StrengthSection({
    required this.t,
    required this.strength,
  });

  final AppLocalizations t;
  final _PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      t.changePasswordStrengthWeak,
      t.changePasswordStrengthMedium,
      t.changePasswordStrengthStrong,
      t.changePasswordStrengthVeryStrong,
    ];

    final activeIndex = switch (strength.level) {
      _PasswordStrengthLevel.weak => 0,
      _PasswordStrengthLevel.medium => 1,
      _PasswordStrengthLevel.strong => 2,
      _PasswordStrengthLevel.veryStrong => 3,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              t.changePasswordStrengthTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
              ),
            ),
            const Spacer(),
            Text(
              strength.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: strength.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: strength.progress,
            backgroundColor: const Color(0xFFE8E1D7),
            color: strength.color,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(labels.length, (index) {
            final isActive = index == activeIndex;
            return Expanded(
              child: Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? strength.color : const Color(0xFF9A9A9A),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({
    required this.t,
    required this.meetsLength,
    required this.meetsCase,
    required this.meetsDigit,
    required this.meetsSpecial,
    required this.meetsReuse,
  });

  final AppLocalizations t;
  final bool meetsLength;
  final bool meetsCase;
  final bool meetsDigit;
  final bool meetsSpecial;
  final bool meetsReuse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF4EA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0DDD0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.changePasswordTipsTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF151515),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _TipItem(label: t.changePasswordTipLength, checked: meetsLength),
                    const SizedBox(height: 12),
                    _TipItem(label: t.changePasswordTipUpperLower, checked: meetsCase),
                    const SizedBox(height: 12),
                    _TipItem(label: t.changePasswordTipNumber, checked: meetsDigit),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _TipItem(label: t.changePasswordTipSpecial, checked: meetsSpecial),
                    const SizedBox(height: 12),
                    _TipItem(label: t.changePasswordTipNoReuse, checked: meetsReuse),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({
    required this.label,
    required this.checked,
  });

  final String label;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    final color = checked ? const Color(0xFFFF7A00) : const Color(0xFFB5B5B5);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: checked ? const Color(0xFFFF7A00) : Colors.transparent,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(
            checked ? Icons.check : Icons.circle_outlined,
            size: checked ? 14 : 11,
            color: checked ? Colors.white : color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                height: 1.3,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetRow extends StatelessWidget {
  const _ResetRow({
    required this.t,
    required this.onTap,
  });

  final AppLocalizations t;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          children: [
            const Icon(
              Icons.lock_reset_outlined,
              color: Color(0xFFFF7A00),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.changePasswordForgotPrompt,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Text(
              t.changePasswordResetAction,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF7A00),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFFF7A00),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.t});

  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2DEC1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: Color(0xFFFF7A00),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.changePasswordInfoText,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF232323),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0D9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7A00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
                const Icon(
                  Icons.phone_iphone_rounded,
                  color: Color(0xFF4A4A4A),
                  size: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1B3B3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFE05B5B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFB03131),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA31A), Color(0xFFFF7A00)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33FF7A00),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
