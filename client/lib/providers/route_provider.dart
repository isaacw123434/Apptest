import 'package:flutter/foundation.dart';
import '../models.dart';

class RouteProvider extends ChangeNotifier {
  JourneyResult? _selectedRoute;

  JourneyResult? get selectedRoute => _selectedRoute;

  void setSelectedRoute(JourneyResult? route) {
    _selectedRoute = route;
    notifyListeners();
  }
}
