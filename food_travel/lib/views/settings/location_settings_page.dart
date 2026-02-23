import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';
import '../../services/location_preference_service.dart';
import '../../services/location_service.dart';

class LocationSettingsPage extends StatefulWidget {
  const LocationSettingsPage({super.key});

  @override
  State<LocationSettingsPage> createState() => _LocationSettingsPageState();
}

class _LocationSettingsPageState extends State<LocationSettingsPage> {
  final _prefs = LocationPreferenceService();
  final _locationService = LocationService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _prefs.load();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _onToggle(bool value) async {
    if (_loading) return;

    if (!value) {
      await _prefs.setEnabled(false);
      return;
    }

    final result = await _locationService.getCurrentLocation(
      useLastKnown: true,
      timeLimit: const Duration(seconds: 20),
    );
    if (!mounted) return;

    if (result.isSuccess) {
      await _prefs.setEnabled(true);
    } else {
      await _prefs.setEnabled(false);
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? t.locationError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.locationSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t.locationSettingsDescription,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: LocationPreferenceService.enabled,
            builder: (context, enabled, _) {
              return SwitchListTile(
                title: Text(t.locationEnable),
                value: enabled,
                onChanged: _onToggle,
              );
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _locationService.openLocationSettings,
            child: Text(t.locationOpenSettings),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _locationService.openAppSettings,
            child: Text(t.locationOpenAppSettings),
          ),
        ],
      ),
    );
  }
}
