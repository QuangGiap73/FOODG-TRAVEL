import 'package:flutter/material.dart';

import '../../controller/theme_controller.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  Future<void> _setMode(ThemeMode mode) async {
    await ThemeController().setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isAuto = controller.isAuto;
        final current = controller.themeMode;
        final isDarkSelected = current == ThemeMode.dark;
        final isLightSelected = current == ThemeMode.light;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Che do giao dien'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ThemeCard(
                        label: 'Sang',
                        selected: !isAuto && isLightSelected,
                        onTap: isAuto ? null : () => _setMode(ThemeMode.light),
                        background: const LinearGradient(
                          colors: [Color(0xFFFFC88B), Color(0xFF6CA6FF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ThemeCard(
                        label: 'Toi',
                        selected: !isAuto && isDarkSelected,
                        onTap: isAuto ? null : () => _setMode(ThemeMode.dark),
                        background: const LinearGradient(
                          colors: [Color(0xFF2B2B2B), Color(0xFF0D0D0D)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tu dong',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Switch(
                        value: isAuto,
                        onChanged: (value) {
                          if (value) {
                            _setMode(ThemeMode.system);
                          } else {
                            _setMode(ThemeMode.light);
                          }
                        },
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

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.background,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Gradient background;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? const Color(0xFF2F80FF) : Colors.transparent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            children: [
              Container(
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: background,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      left: 12,
                      right: 30,
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              if (selected)
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFF2F80FF),
                  child: Icon(Icons.check, size: 14, color: Colors.white),
                )
              else
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.transparent,
                  child: Icon(Icons.circle_outlined, size: 18, color: Colors.white30),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
