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

  /// Count of favourited routes for a specific from→to pair
  int countForPair(String from, String to) {
    final key = '$from→$to';
    return _savedRoutes.where((r) => r.routeKey == key).length;
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

  /// Bookmark a route (isPermanent = committed/upcoming journey)
  void toggleBookmark(String from, String to, JourneyResult journey) {
    final index = _savedRoutes.indexWhere((r) => r.journey.id == journey.id);
    if (index >= 0) {
      // Toggle isPermanent
      _savedRoutes[index] = _savedRoutes[index].copyWith(
        isPermanent: !_savedRoutes[index].isPermanent,
      );
    } else {
      // Heart + bookmark in one go
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

  /// Alias kept for detail page compatibility
  void saveFromDetail(String from, String to, JourneyResult journey) {
    toggleBookmark(from, to, journey);
  }

  List<SavedRoute> getRoutesForPair(String from, String to) {
    final key = '$from→$to';
    return _savedRoutes.where((r) => r.routeKey == key).toList();
  }

  /// Get all bookmarked (upcoming) routes
  List<SavedRoute> get upcomingRoutes =>
      _savedRoutes.where((r) => r.isPermanent).toList();
}
