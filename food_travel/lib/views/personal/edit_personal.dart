import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../cloudinary_config.dart';
import '../../data/provinces.dart';
import '../../models/user_preferences.dart';
import '../../services/cloudinary_service.dart';
import '../../services/user_service.dart';

class EditPersonalPage extends StatefulWidget {
  const EditPersonalPage({super.key});

  @override
  State<EditPersonalPage> createState() => _EditPersonalPageState();
}

class _EditPersonalPageState extends State<EditPersonalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;
  String? _selectedGender;
  DateTime? _dateOfBirth;
  String? _selectedProvince;
  UserPreferences _preferences = const UserPreferences();
  final Set<String> _favoriteTags = <String>{};

  static const List<String> _favoritePresetKeys = [
    'H\u1ea3i s\u1ea3n',
    '\u0110\u1eb7c s\u1ea3n v\u00f9ng mi\u1ec1n',
    'B\u00fan - Ph\u1edf',
    '\u0110\u1ed3 n\u01b0\u1edbng',
    '\u0110\u1ed3 ng\u1ecdt - Tr\u00e1ng mi\u1ec7ng',
  ];

  static const Set<String> _genderKeys = {
    'male',
    'female',
    'other',
    'unknown',
  };

  Map<String, String> _genderLabels(AppLocalizations t) => {
    'male': t.genderMale,
    'female': t.genderFemale,
    'other': t.genderOther,
    'unknown': t.genderUnknown,
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final profile = await UserService().getUserById(user.uid);
    _nameController.text =
        (profile?.fullName ?? user.displayName ?? '').trim();
    _phoneController.text = (profile?.phone ?? '').trim();
    _emailController.text = (profile?.email ?? user.email ?? '').trim();
    _avatarUrl = profile?.photoUrl ?? user.photoURL;
    final storedGender = profile?.gender;
    _selectedGender =
        _genderKeys.contains(storedGender) ? storedGender : null;
    _dateOfBirth = profile?.dateOfBirth;
    _preferences = profile?.preferences ?? const UserPreferences();
    _selectedProvince = _preferences.provinceName?.trim().isNotEmpty == true
        ? _preferences.provinceName!.trim()
        : null;
    _favoriteTags
      ..clear()
      ..addAll(_preferences.favoriteTags);
    _dobController.text = _formatDate(_dateOfBirth);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final service = CloudinaryService(
        cloudName: cloudinaryCloudName,
        uploadPreset: cloudinaryUploadPreset,
        folder: cloudinaryFolder,
      );

      final url = await service.uploadImage(File(picked.path));
      await UserService().updateUserPhotoUrl(uid: user.uid, photoUrl: url);
      await user.updatePhotoURL(url);

      if (mounted) {
        setState(() => _avatarUrl = url);
      }
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.profileAvatarUploadFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final fullName = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final gender = _selectedGender;
    final dateOfBirth = _dateOfBirth;
    final provinceName = _selectedProvince?.trim();
    final preferences = UserPreferences(
      provinceCode: _buildProvinceCode(provinceName ?? ''),
      provinceName: provinceName,
      spicyLevel: _preferences.spicyLevel,
      favoriteTags: _favoriteTags.toList(),
      dislikedIngredients: _preferences.dislikedIngredients,
    );

    await UserService().updateUserProfile(
      uid: user.uid,
      fullName: fullName,
      phone: phone.isEmpty ? null : phone,
      gender: gender,
      dateOfBirth: dateOfBirth,
    );
    await UserService().saveOnboarding(uid: user.uid, preferences: preferences);

    if (fullName.isNotEmpty && user.displayName != fullName) {
      await user.updateDisplayName(fullName);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String? _buildProvinceCode(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final cleaned = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    if (cleaned.isEmpty) return null;
    return cleaned.split(RegExp(r'\s+')).join('_');
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ??
        DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _dateOfBirth = picked;
      _dobController.text = _formatDate(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final photoUrl = _avatarUrl ?? FirebaseAuth.instance.currentUser?.photoURL;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF11151B) : const Color(0xFFFFFBF7);
    final surface = isDark ? const Color(0xFF171C22) : Colors.white;
    final border = isDark ? const Color(0xFF272E37) : const Color(0xFFF1E7DB);
    final subColor = isDark ? const Color(0xFFB0BAC8) : const Color(0xFF6B7280);
    final accent = const Color(0xFFF97316);

    return Scaffold(
      backgroundColor: bg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _ProfileHeader(
                      title: isVi
                          ? 'H\u1ed3 s\u01a1 c\u00e1 nh\u00e2n'
                          : t.profileEditTitle,
                      subtitle: isVi
                          ? 'C\u1eadp nh\u1eadt th\u00f4ng tin \u0111\u1ec3 tr\u1ea3i nghi\u1ec7m t\u1ed1t h\u01a1n'
                          : 'Update your info for a better experience',
                      photoUrl: photoUrl,
                      isUploading: _isUploadingAvatar,
                      onBack: () => Navigator.pop(context),
                      onPickAvatar: _pickAndUploadAvatar,
                    ),
                    Transform.translate(
                      offset: const Offset(0, 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          children: [
                            _SectionCard(
                              surface: surface,
                              border: border,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(
                                    icon: Icons.person_rounded,
                                    title: isVi
                                        ? 'Th\u00f4ng tin c\u00e1 nh\u00e2n'
                                        : 'Personal information',
                                    color: accent,
                                  ),
                                  const SizedBox(height: 18),
                                  _ProfileInputRow(
                                    icon: Icons.badge_outlined,
                                    accent: accent,
                                    child: TextFormField(
                                      controller: _nameController,
                                      decoration: _inputDecoration(
                                        t.profileNameLabel,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return t.profileNameRequired;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _ProfileInputRow(
                                    icon: Icons.wc_rounded,
                                    accent: accent,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedGender,
                                      decoration: _inputDecoration(
                                        t.profileGenderLabel,
                                      ),
                                      hint: Text(t.profileGenderHint),
                                      items: _genderLabels(t).entries
                                          .map(
                                            (entry) => DropdownMenuItem(
                                              value: entry.key,
                                              child: Text(entry.value),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() => _selectedGender = value);
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _ProfileInputRow(
                                    icon: Icons.calendar_month_rounded,
                                    accent: accent,
                                    child: TextFormField(
                                      controller: _dobController,
                                      readOnly: true,
                                      decoration: _inputDecoration(
                                        t.profileDobLabel,
                                        suffixIcon:
                                            const Icon(Icons.calendar_today),
                                      ),
                                      onTap: () {
                                        FocusScope.of(context)
                                            .requestFocus(FocusNode());
                                        _pickDate();
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _ProfileInputRow(
                                    icon: Icons.phone_rounded,
                                    accent: accent,
                                    child: TextFormField(
                                      controller: _phoneController,
                                      decoration: _inputDecoration(
                                        t.profilePhoneLabel,
                                      ),
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _ProfileInputRow(
                                    icon: Icons.email_rounded,
                                    accent: accent,
                                    child: TextFormField(
                                      controller: _emailController,
                                      decoration: _inputDecoration(
                                        t.profileEmailLabel,
                                      ),
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _ProfileInputRow(
                                    icon: Icons.location_on_rounded,
                                    accent: accent,
                                    child: _ProvinceField(
                                      selectedProvince: _selectedProvince,
                                      label: isVi
                                          ? 'T\u1ec9nh / Th\u00e0nh ph\u1ed1 hi\u1ec7n t\u1ea1i'
                                          : 'Current province / city',
                                      border: border,
                                      onSelected: (value) {
                                        setState(() => _selectedProvince = value);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            _SectionCard(
                              surface: surface,
                              border: border,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(
                                    icon: Icons.restaurant_menu_rounded,
                                    title: isVi
                                        ? 'S\u1edf th\u00edch \u1ea9m th\u1ef1c'
                                        : 'Food preferences',
                                    color: accent,
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: _favoritePresetKeys.map((label) {
                                      final selected =
                                          _favoriteTags.contains(label);
                                      return _PreferenceChip(
                                        label: label,
                                        selected: selected,
                                        onTap: () {
                                          setState(() {
                                            if (selected) {
                                              _favoriteTags.remove(label);
                                            } else {
                                              _favoriteTags.add(label);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 60,
                              width: double.infinity,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF8B3D),
                                      Color(0xFFF97316),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: FilledButton.icon(
                                  onPressed:
                                      _isSaving || _isLoading ? null : _saveProfile,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                  ),
                                  icon: _isSaving
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
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                    isVi
                                        ? 'L\u01b0u thay \u0111\u1ed5i'
                                        : t.save,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              isVi
                                  ? 'Th\u00f4ng tin c\u1ee7a b\u1ea1n s\u1ebd \u0111\u01b0\u1ee3c c\u1eadp nh\u1eadt'
                                  : 'Your information will be updated',
                              style: TextStyle(
                                color: subColor,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: Color(0xFFF97316), width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.title,
    required this.subtitle,
    required this.photoUrl,
    required this.isUploading,
    required this.onBack,
    required this.onPickAvatar,
  });

  final String title;
  final String subtitle;
  final String? photoUrl;
  final bool isUploading;
  final VoidCallback onBack;
  final VoidCallback onPickAvatar;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 272,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/person/profile_A.png',
                fit: BoxFit.cover,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.82),
                      Colors.white.withValues(alpha: 0.54),
                      Colors.white.withValues(alpha: 0.72),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton.filledTonal(
                          onPressed: onBack,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.88),
                            foregroundColor: const Color(0xFF111827),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6, right: 12),
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 64, right: 24),
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -9,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 128,
                  height: 128,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A3D), Color(0xFFF97316)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF97316).withValues(alpha: 0.28),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(5),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFF3F4F6),
                      backgroundImage:
                          photoUrl != null ? NetworkImage(photoUrl!) : null,
                      child: photoUrl == null
                          ? const Icon(Icons.person, size: 52)
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 6,
                  child: Material(
                    color: const Color(0xFFF97316),
                    shape: const CircleBorder(),
                    elevation: 8,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: isUploading ? null : onPickAvatar,
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: Center(
                          child: isUploading
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
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ProfileInputRow extends StatelessWidget {
  const _ProfileInputRow({
    required this.icon,
    required this.accent,
    required this.child,
  });

  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(width: 14),
        Expanded(child: child),
      ],
    );
  }
}

class _ProvinceField extends StatelessWidget {
  const _ProvinceField({
    required this.selectedProvince,
    required this.label,
    required this.border,
    required this.onSelected,
  });

  final String? selectedProvince;
  final String label;
  final Color border;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedProvince,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: Color(0xFFF97316), width: 1.4),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
      items: vietnamProvinces
          .map(
            (province) => DropdownMenuItem<String>(
              value: province,
              child: Text(province),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFFF97316)
                  : const Color(0xFFE5E7EB),
            ),
            color: selected
                ? const Color(0xFFFFF1E8)
                : Colors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF111827)
                      : const Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? const Color(0xFFF97316)
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFF97316)
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
