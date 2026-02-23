import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../controller/change_password/change_password_controller.dart';

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
  void dispose() {
    _controller.dispose();
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: suffixIcon,
    );
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
      case ChangePasswordController.errorNoPasswordProvider:
        return t.changePasswordErrorNoPasswordProvider;
      case ChangePasswordController.errorUnknown:
        return t.changePasswordErrorUnknown;
      default:
        return null;
    }
  }

  Future<void> _submit(AppLocalizations t) async {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(t.changePasswordTitle)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _currentController,
                      obscureText: _obscureCurrent,
                      decoration: _inputDecoration(
                        t.changePasswordCurrentLabel,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCurrent = !_obscureCurrent;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return t.changePasswordCurrentRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newController,
                      obscureText: _obscureNew,
                      decoration: _inputDecoration(
                        t.changePasswordNewLabel,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNew = !_obscureNew;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return t.changePasswordNewRequired;
                        }
                        if (value.length < 6) {
                          return t.changePasswordNewTooShort;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      decoration: _inputDecoration(
                        t.changePasswordConfirmLabel,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return t.changePasswordConfirmRequired;
                        }
                        if (value != _newController.text) {
                          return t.changePasswordMismatch;
                        }
                        return null;
                      },
                    ),
                    if (_controller.errorCode != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage(t) ?? t.changePasswordErrorUnknown,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _controller.isLoading
                            ? null
                            : () => _submit(t),
                        child: _controller.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
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
          ),
        );
      },
    );
  }
}
