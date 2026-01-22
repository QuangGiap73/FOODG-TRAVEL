import 'package:flutter/material.dart';
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

    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;

    if (result.isSuccess) {
      await _prefs.setEnabled(true);
    } else {
      await _prefs.setEnabled(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Location error.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Bat/tat vi tri de hien thi tren ban do.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: LocationPreferenceService.enabled,
            builder: (context, enabled, _) {
              return SwitchListTile(
                title: const Text('Bat vi tri'),
                value: enabled,
                onChanged: _onToggle,
              );
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _locationService.openLocationSettings,
            child: const Text('Mo cai dat GPS'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _locationService.openAppSettings,
            child: const Text('Mo cai dat ung dung'),
          ),
        ],
      ),
    );
  }
}
