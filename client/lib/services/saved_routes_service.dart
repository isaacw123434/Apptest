import 'dart:convert';

import '../models.dart';
import 'storage/storage.dart' as storage;

class SavedRoutesService {
  static const _storageKey = 'endmile_saved_routes';

  List<SavedRoute> loadSavedRoutes() {
    final raw = storage.getStorageItem(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => SavedRoute.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  void saveSavedRoutes(List<SavedRoute> routes) {
    final json = jsonEncode(routes.map((r) => r.toJson()).toList());
    storage.setStorageItem(_storageKey, json);
  }
}
