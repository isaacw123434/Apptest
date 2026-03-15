import 'package:flutter/foundation.dart';

import '../models.dart';
import '../services/saved_routes_service.dart';

class SavedRoutesProvider extends ChangeNotifier {
  final SavedRoutesService _service = SavedRoutesService();
  List<SavedRoute> _savedRoutes = [];

  List<SavedRoute> get savedRoutes => List.unmodifiable(_savedRoutes);
  int get savedCount => _savedRoutes.length;

  void init() {
    _savedRoutes = _service.loadSavedRoutes();
    notifyListeners();
  }

  bool isSaved(String journeyId) {
    return _savedRoutes.any((r) => r.journey.id == journeyId);
  }

  bool isPermanent(String journeyId) {
    final route = _savedRoutes.cast<SavedRoute?>().firstWhere(
      (r) => r!.journey.id == journeyId,
      orElse: () => null,
    );
    return route?.isPermanent ?? false;
  }

  void toggleHeart(String from, String to, JourneyResult journey) {
    final index = _savedRoutes.indexWhere((r) => r.journey.id == journey.id);
    if (index >= 0) {
      _savedRoutes.removeAt(index);
    } else {
      _savedRoutes.add(SavedRoute(
        routeKey: '$from→$to',
        from: from,
        to: to,
        journey: journey,
        savedAt: DateTime.now(),
      ));
    }
    _service.saveSavedRoutes(_savedRoutes);
    notifyListeners();
  }

  void removeRoute(String journeyId) {
    _savedRoutes.removeWhere((r) => r.journey.id == journeyId);
    _service.saveSavedRoutes(_savedRoutes);
    notifyListeners();
  }

  void saveFromDetail(String from, String to, JourneyResult journey) {
    final index = _savedRoutes.indexWhere((r) => r.journey.id == journey.id);
    if (index >= 0) {
      if (_savedRoutes[index].isPermanent) {
        // Already permanent — toggle off
        _savedRoutes.removeAt(index);
      } else {
        // Upgrade heart to permanent
        _savedRoutes[index] = _savedRoutes[index].copyWith(isPermanent: true);
      }
    } else {
      _savedRoutes.add(SavedRoute(
        routeKey: '$from→$to',
        from: from,
        to: to,
        journey: journey,
        savedAt: DateTime.now(),
        isPermanent: true,
      ));
    }
    _service.saveSavedRoutes(_savedRoutes);
    notifyListeners();
  }

  List<SavedRoute> getRoutesForPair(String from, String to) {
    final key = '$from→$to';
    return _savedRoutes.where((r) => r.routeKey == key).toList();
  }
}
