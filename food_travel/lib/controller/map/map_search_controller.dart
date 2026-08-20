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
  double? _biasLat;
  double? _biasLng;
  int _biasRadius = 5000;
  int _requestVersion = 0;

  bool get loading => _loading;

  List<GoongPrediction> get suggestions => List.unmodifiable(_suggestions);

  void setBias({double? lat, double? lng, int radius = 5000}) {
    _biasLat = lat;
    _biasLng = lng;
    _biasRadius = radius;
  }

  // Called on every text change; debounce before hitting the API.
  void onQueryChanged(String input) {
    final query = input.trim();
    _debounce?.cancel();
    final requestVersion = ++_requestVersion;

    if (query.length < 2) {
      clear();
      return;
    }

    _loading = true;
    notifyListeners();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await _service.autocomplete(
          query,
          lat: _biasLat,
          lng: _biasLng,
          radius: _biasRadius,
        );
        // Bỏ phản hồi cũ nếu người dùng đã nhập một từ khóa mới hơn.
        if (requestVersion != _requestVersion) return;
        _suggestions
          ..clear()
          ..addAll(results);
      } catch (_) {
        if (requestVersion != _requestVersion) return;
        _suggestions.clear();
      } finally {
        if (requestVersion == _requestVersion) {
          _loading = false;
          notifyListeners();
        }
      }
    });
  }

  Future<GoongPlaceDetail?> fetchDetail(GoongPrediction prediction) async {
    _loading = true;
    notifyListeners();
    try {
      return await _service.placeDetail(prediction.placeId);
    } catch (_) {
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _debounce?.cancel();
    _requestVersion++;
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
