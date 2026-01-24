import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/map/places_service.dart';

class MapSearchController extends ChangeNotifier {
  MapSearchController({GoongPlacesService? service})
      : _service = service ?? GoongPlacesService();

  final GoongPlacesService _service;
  final List<GoongPrediction> _suggestions = [];
  Timer? _debounce;
  bool _loading = false;

  bool get loading => _loading;

  List<GoongPrediction> get suggestions => List.unmodifiable(_suggestions);

  // Called on every text change; debounce before hitting the API.
  void onQueryChanged(String input) {
    final query = input.trim();
    _debounce?.cancel();

    if (query.length < 2) {
      clear();
      return;
    }

    _loading = true;
    notifyListeners();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await _service.autocomplete(query);
      _suggestions
        ..clear()
        ..addAll(results);
      _loading = false;
      notifyListeners();
    });
  }

  Future<GoongPlaceDetail?> fetchDetail(GoongPrediction prediction) async {
    _loading = true;
    notifyListeners();
    final detail = await _service.placeDetail(prediction.placeId);
    _loading = false;
    notifyListeners();
    return detail;
  }

  void clear() {
    _debounce?.cancel();
    _suggestions.clear();
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
